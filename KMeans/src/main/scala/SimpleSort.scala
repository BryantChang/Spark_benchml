package src.main.scala

import java.util.concurrent.TimeUnit

import breeze.linalg.{Vector, DenseVector, squaredDistance}
import org.apache.log4j.{Level, Logger}
import org.apache.spark.mllib.clustering.{KMeans, KMeansModel}
import org.apache.spark.mllib.linalg.Vectors
import org.apache.spark.storage.StorageLevel
import org.apache.spark.{SparkContext, SparkConf}
import org.json4s.jackson.JsonMethods._

/**
 * Created by hwang on 2016/6/19.
 */
object SimpleSort {

  def main(args: Array[String]) {
    Logger.getLogger("org.apache.spark").setLevel(Level.WARN);
    Logger.getLogger("org.eclipse.jetty.server").setLevel(Level.OFF);
    if (args.length < 4) {
      println("usage: <input> <output> <numClusters> <maxIterations> <StorageLevel>")
      System.exit(0)
    }

    val input = args(0)
    val output = args(1)
    val K = args(2).toInt
    val maxIterations = args(3).toInt
    val storageLevel=args(4)
    //val runs = calculateRuns(args)

    val conf = new SparkConf
    conf.setAppName("Spark Simple Sort with storageLevel"+storageLevel)
    val sc = new SparkContext(conf)

    var sl:StorageLevel=StorageLevel.MEMORY_ONLY;
    if(storageLevel=="MEMORY_AND_DISK_SER")
      sl=StorageLevel.MEMORY_AND_DISK_SER
    else if(storageLevel=="MEMORY_AND_DISK")
      sl=StorageLevel.MEMORY_AND_DISK
    else if(storageLevel=="OFF_HEAP")
      sl=StorageLevel.OFF_HEAP
    else if(storageLevel=="NONE")
      sl=StorageLevel.NONE

    val words = sc.textFile(input).flatMap(_.split("\\s+"))

    val res = words.sortBy(str => str, true)

    res.saveAsTextFile(output)

    sc.stop()
  }

}
