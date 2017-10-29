package src.main.scala

import org.apache.log4j.{Level, Logger}
import org.apache.spark.storage.StorageLevel
import org.apache.spark.{SparkConf, SparkContext}

/**
 * Created by hwang on 2016/6/19.
 */
object SimplePageRank {

  def main(args: Array[String]) {

    if (args.length < 5) {
      println("usage: <input> <output> <minEdge> <maxIterations> <tolerance> <resetProb> <StorageLevel>")
      System.exit(0)
    }
    Logger.getLogger("org.apache.spark").setLevel(Level.WARN)
    Logger.getLogger("org.eclipse.jetty.server").setLevel(Level.OFF)

    //val conf = new SparkConf
    //conf.setAppName("Spark PageRank Application")
    //val sc = new SparkContext(conf)
    //conf.registerKryoClasses(Array(classOf[pagerankApp] ))

    val input = args(0)
    val output = args(1)
    val minEdge = args(2).toInt
    val maxIterations = args(3).toInt
    val tolerance = args(4).toDouble
    val resetProb = args(5).toDouble
    val storageLevel=args(6)

    var sl:StorageLevel=StorageLevel.MEMORY_ONLY;
    if(storageLevel=="MEMORY_AND_DISK_SER")
      sl=StorageLevel.MEMORY_AND_DISK_SER
    else if(storageLevel=="MEMORY_AND_DISK")
      sl=StorageLevel.MEMORY_AND_DISK
    else if(storageLevel=="OFF_HEAP")
      sl=StorageLevel.OFF_HEAP
    else if(storageLevel=="NONE")
      sl=StorageLevel.NONE


    val sparkConf = new SparkConf().setAppName("PageRank with storage "+storageLevel)
    val iters = if (maxIterations > 0) maxIterations else 10
    val ctx = new SparkContext(sparkConf)
    val lines = ctx.textFile(input)
    val links = lines.map{ s =>
      val parts = s.split("\\s+")
      (parts(0), parts(1))
    }.distinct().groupByKey().persist(sl)
    var ranks = links.mapValues(v => 1.0)

    for (i <- 1 to iters) {
      val contribs = links.join(ranks).values.flatMap{ case (urls, rank) =>
        val size = urls.size
        urls.map(url => (url, rank / size))
      }
      ranks = contribs.reduceByKey(_ + _).mapValues(0.15 + 0.85 * _)
    }

    ranks.map(tup => tup._1 + " " + tup._2).saveAsTextFile(output)
    //output.foreach(tup => println(tup._1 + " has rank: " + tup._2 + "."))

    ctx.stop()
  }

}
