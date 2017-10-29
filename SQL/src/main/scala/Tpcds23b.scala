
/*
 * (C) Copyright IBM Corp. 2015 
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at 
 *
 *  http://www.apache.org/licenses/LICENSE-2.0 
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package src.main.scala

import com.google.common.io.{ByteStreams, Files}
import java.io.File
import org.apache.spark.{SparkConf, SparkContext}
import org.apache.spark.sql._
import org.apache.spark.sql.hive.HiveContext
import org.apache.log4j.Logger
import org.apache.log4j.Level
import org.apache.spark.storage.StorageLevel

object Tpcds23b {

  //将count*>4修改为>10，降低数据量，这样30G的tpcds库里，只有26735
  val query23_fst = """
                      |select substr(i_item_desc,1,30) itemdesc,i_item_sk item_sk,d_date solddate,count(*) cnt
                      |  from store_sales, date_dim, item
                      |  where ss_sold_date_sk = d_date_sk
                      |    and ss_item_sk = i_item_sk
                      |    and d_year in (2000, 2000+1, 2000+2,2000+3)
                      |  group by substr(i_item_desc,1,30),i_item_sk,d_date
                      |  having count(*) > 4
                    """.stripMargin

  val query23_mss = """
                      | select max(csales) tpcds_cmax
                      |  from (select c_customer_sk,sum(ss_quantity*ss_sales_price) csales
                      |        from store_sales, customer, date_dim
                      |        where ss_customer_sk = c_customer_sk
                      |         and ss_sold_date_sk = d_date_sk
                      |         and d_year in (2000, 2000+1, 2000+2,2000+3)
                      |        group by c_customer_sk) x
                    """.stripMargin

  //best_ss_customer
  val query23_bsc = """
                      | select c_customer_sk,sum(ss_quantity*ss_sales_price) ssales
                      |  from store_sales, customer
                      |  where ss_customer_sk = c_customer_sk
                      |  group by c_customer_sk
                      |  having sum(ss_quantity*ss_sales_price) > (50/100.0) *
                    """.stripMargin

  val query23a_query_fixed = """
                               |select sum(sales)
                               | from (
                               |select cs_quantity*cs_list_price sales
                               |       from catalog_sales t1, date_dim t2
                               |       left outer join frequent_ss_items t3
                               |       left outer join best_ss_customer t4
                               |       where d_year = 2000
                               |         and d_moy = 2
                               |         and cs_sold_date_sk = d_date_sk
                               |         and t1.cs_item_sk=t3.item_sk
                               |         and t3.item_sk is not null
                               |         and t1.cs_bill_customer_sk = t4.c_customer_sk and t4.c_customer_sk is not null
                               |       ) y
                             """.stripMargin

  //30000 需要cache
  val query23a_query_final_tb1 = """
                                   |select cs_quantity*cs_list_price sales, cs_item_sk, cs_bill_customer_sk
                                   |       from catalog_sales t1, date_dim t2
                                   |       where d_year = 2000
                                   |         and d_moy = 2
                                   |         and cs_sold_date_sk = d_date_sk
                                 """.stripMargin

  // Not used now
  val query23a_query_final_tb2 = """
                                   |select sales, cs_bill_customer_sk
                                   | from tb1
                                   | left outer join frequent_ss_items t3
                                   | where tb1.cs_item_sk = t3.item_sk and t3.item_sk is not null
                                 """.stripMargin

  //从外连接修改为内连接
  val query23a_query_final = """
                               |select sum(sales)
                               | from tb1, frequent_ss_items t3, best_ss_customer t4
                               | where tb1.cs_item_sk = t3.item_sk
                               |   and tb1.cs_bill_customer_sk = t4.c_customer_sk
                             """.stripMargin

  def main(args: Array[String]) {

    if (args.length < 4) {
      println("usage:<input>  <output> <numpar> <storageLevel>")
      System.exit(0)
    }
    //Logger.getLogger("org.apache.spark").setLevel(Level.WARN)
    //Logger.getLogger("org.apache.hadoop.hive").setLevel(Level.WARN)
    Logger.getLogger("org.eclipse.jetty.server").setLevel(Level.OFF)
    val inputPath = args(0)
    val output = args(1)
    val numpar = args(2).toInt

    val storageLevel=args(3)

    //最后的一个join非常耗时，应该和并行度有关
    val finalPartitionNumber = if (args.length > 4) args(4).toInt else 10
    //val storageLevel="MEMORY_AND_DISK_SER"

    //val storageLevel="MEMORY_AND_DISK"
    var sl:StorageLevel=StorageLevel.MEMORY_ONLY
    if(storageLevel=="MEMORY_AND_DISK_SER")
      sl=StorageLevel.MEMORY_AND_DISK_SER
    else if(storageLevel=="MEMORY_AND_DISK")
      sl=StorageLevel.MEMORY_AND_DISK
    else if(storageLevel=="OFF_HEAP")
      sl=StorageLevel.MEMORY_ONLY_SER
    //sl=StorageLevel.OFF_HEAP
    else if(storageLevel=="NONE")
      sl=StorageLevel.NONE

    val isCaching = sl != StorageLevel.NONE

    //sl=StorageLevel.MEMORY_AND_DISK
    println(s"storage level $sl")
    val sparkConf = new SparkConf().setAppName(s"Tpcds23b with $storageLevel, final partition $finalPartitionNumber")
    val sc = new SparkContext(sparkConf)

    val sqlContext = new HiveContext(sc)

    //use database. e.g
    sqlContext.sql("use " + inputPath)
    sqlContext.sql("show tables").collect().foreach(println _)

    def cacheTempTable(sql: String, tableName: String, level: StorageLevel = StorageLevel.MEMORY_ONLY, repartition: Int = -1) {
      if (isCaching) {
        println(s"cache table $tableName")
        val tbl = if (repartition > 0) {
          sqlContext.sql(sql).repartition(repartition).persist(level)
        } else {
          sqlContext.sql(sql).persist(level)
        }
        tbl.count()
        tbl.registerTempTable(tableName)
        //sqlContext.sql(s"select count(*) from $tableName").collect().foreach(println _)
      } else {
        sqlContext.sql(sql).registerTempTable(tableName)
      }
    }

    cacheTempTable(query23_fst, "frequent_ss_items", sl, numpar)
    cacheTempTable(query23_mss, "max_store_sales", sl, numpar)
    val mssVal = sqlContext.sql("select * from max_store_sales limit 1").collect().head.get(0).asInstanceOf[Double]

    cacheTempTable(query23_bsc + mssVal.toString, "best_ss_customer", sl, 1)

    //final table1
    cacheTempTable(query23a_query_final_tb1, "tb1", sl, finalPartitionNumber)

    //都repartition到1个分区时，3.2min跑完。如果10个分区呢？可以试验下
    //还有试验是否使用broadcast join替代left outer join

    if (storageLevel == "MEMORY_ONLY" || !sparkConf.getBoolean("spark.smspark.enable", false)) {
      //sqlContext.sql(query23_fst).registerTempTable("frequent_ss_items")
      sqlContext.sql(query23_bsc + mssVal.toString).registerTempTable("best_ss_customer")
      sqlContext.sql(query23a_query_final_tb1).registerTempTable("tb1")
    }

    sqlContext.sql(query23a_query_final).collect().foreach(println)

    sc.stop()
  }
}

// The results of SQL queries are themselves RDDs and support all normal RDD functions.  The
// items in the RDD are of type Row, which allows you to access each column by ordinal.
// val rddFromSql = sql("SELECT key, value FROM records1 WHERE key < 10 ORDER BY key")

// println("Result of RDD.map:")

//val rddAsStrings = rddFromSql.map {
//  case Row(key: Int, value: String) => s"Key: $key, Value: $value"
// }


//sql("CREATE TABLE IF NOT EXISTS order (oid INT, oc STRING, bid INT, cts STRING, pts STRING, ip STRING, ostat STRING)")
//	sql("CREATE TABLE IF NOT EXISTS order (oid INT,  bid INT, cts STRING)")
//sql("CREATE TABLE IF NOT EXISTS orderItem (iid INT, oid INT, gid INT , gnum DOUBLE, price DOUBLE, gprice DOUBLE, gstore DOUBLE)")
//	sql("CREATE TABLE IF NOT EXISTS orderItem (iid INT, oid INT, gid INT , gnum DOUBLE, price DOUBLE, gprice DOUBLE, gstore DOUBLE)")
//sql(s"LOAD DATA LOCAL INPATH '${kv1File.getAbsolutePath}' INTO TABLE src")

// Copy kv1.txt file from classpath to temporary directory
//val kv1Stream = HiveFromSpark.getClass.getResourceAsStream("/kv1.txt")
//val kv1File = File.createTempFile("kv1", "txt")
//kv1File.deleteOnExit()
//ByteStreams.copy(kv1Stream, Files.newOutputStreamSupplier(kv1File))

// A hive context adds support for finding tables in the MetaStore and writing queries
// using HiveQL. Users who do not have an existing Hive deployment can still create a
// HiveContext. When not configured by the hive-site.xml, the context automatically
// creates metastore_db and warehouse in the current directory.
   