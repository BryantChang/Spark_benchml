
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

object Tpcds1 {

  val query1_ctr = """
                     | SELECT sr_customer_sk AS ctr_customer_sk, sr_store_sk AS ctr_store_sk,
                     |           sum(sr_return_amt) AS ctr_total_return
                     |    FROM store_returns, date_dim
                     |    WHERE sr_returned_date_sk = d_date_sk AND d_year = 2000
                     |    GROUP BY sr_customer_sk, sr_store_sk
                   """.stripMargin

  val query1_query = """
                       | SELECT c_customer_id
                       |   FROM customer_total_return ctr1, store, customer
                       |   WHERE ctr1.ctr_total_return > 38.88
                       |   AND s_store_sk = ctr1.ctr_store_sk
                       |   AND s_state = 'TN'
                       |   AND ctr1.ctr_customer_sk = c_customer_sk
                       |   ORDER BY c_customer_id LIMIT 100
                     """.stripMargin

  def main(args: Array[String]) {

    if (args.length != 4) {
      println("usage:<input>  <output> <numpar> <storageLevel> ")
      System.exit(0)
    }
    //Logger.getLogger("org.apache.spark").setLevel(Level.ERROR)
    Logger.getLogger("org.apache.hadoop.hive").setLevel(Level.WARN)
    Logger.getLogger("org.eclipse.jetty.server").setLevel(Level.OFF)
    val inputPath = args(0)
    val output = args(1)
    val numpar=args(2).toInt

    val storageLevel=args(3)
    //val storageLevel="MEMORY_AND_DISK_SER"

    //val storageLevel="MEMORY_AND_DISK"
    var sl:StorageLevel=StorageLevel.NONE;
    if(storageLevel=="MEMORY_AND_DISK_SER")
      sl=StorageLevel.MEMORY_AND_DISK_SER
    else if(storageLevel=="MEMORY_AND_DISK")
      sl=StorageLevel.MEMORY_AND_DISK
    else if(storageLevel=="OFF_HEAP")
      sl=StorageLevel.OFF_HEAP
    else if(storageLevel=="NONE")
      sl=StorageLevel.NONE
    else if(storageLevel=="MEMORY_ONLY_2")
      sl=StorageLevel.MEMORY_ONLY

    //sl=StorageLevel.MEMORY_AND_DISK
    println(s"storage level $sl")
    val sparkConf = new SparkConf().setAppName("Tpcds1 with "+storageLevel)
    //sparkConf.set("spark.sql.broadcastTimeout", "")
    val sc = new SparkContext(sparkConf)

    val sqlContext = new HiveContext(sc)

    sqlContext.sql("use " + inputPath)
    sqlContext.sql("show tables").collect().foreach(println _)

    val fst = sqlContext.sql(query1_ctr).repartition(2).persist(sl)
    fst.count()
    if (sl != StorageLevel.NONE) {
      println("register cached TempTable query1_ctr")
      fst.registerTempTable("customer_total_return")
    } else {
      println("register uncached TempTable query1_ctr")
      sqlContext.sql(query1_ctr).registerTempTable("customer_total_return")
    }
    //sqlContext.sql(s"select count(*) from customer_total_return").collect().foreach(println _)

    sqlContext.sql(query1_query).collect().foreach(println _)

    println()

    sc.stop()
  }
}

