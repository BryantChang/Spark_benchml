package kmeans_min.src.main.scala

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
object SimpleKMeans {

  def main(args: Array[String]) {
    Logger.getLogger("org.apache.spark").setLevel(Level.WARN);
    Logger.getLogger("org.eclipse.jetty.server").setLevel(Level.OFF);
    if (args.length < 5) {
      println("usage: <input> <output> <numClusters> <maxIterations> <StorageLevel> <partitionCount>")
      System.exit(0)
    }

    System.out.println(args.length);
    val input = args(0)
    val output = args(1)
    val K = args(2).toInt
    val maxIterations = args(3).toInt
    val storageLevel=args(4)
    val partitionCount = args(5).toInt

    val conf = new SparkConf
    conf.setAppName("Spark Simple KMeans with storageLevel"+storageLevel)
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

    val lines = sc.textFile(input, partitionCount)

    //We add sleep time for stimulate the data loading and processing load.
    val data = lines.map(parseVector _).mapPartitions{ iter =>
      //TimeUnit.SECONDS.sleep(sleepDuration)
      iter
    }.persist(sl).setName("KMeansData")

    val kPoints = data.takeSample(false, K, 42).toArray
    var num = 0

    while (num < maxIterations) {

      val closet = data.map( point => (closestPoint(point, kPoints), (point, 1)))

      val pointStat = closet.reduceByKey{case ((x1, y1), (x2, y2)) => (x1 + x2, y1 + y2)}

      val newPoints = pointStat.map { pair =>
        (pair._1, pair._2._1 * (1.0 / pair._2._2))
      }.collectAsMap()

      for (newp <- newPoints) {
        kPoints(newp._1) = newp._2
      }

      println("Finished iteration (num = " + num + ")")

      num += 1
    }

    println("=====================Final centers:=================================")
    kPoints.foreach(println)
    sc.stop()
  }

  def parseVector(line: String): Vector[Double] = {
    val arr = line.split("\\s+")
    if (arr.length < 2) { //for excaption data
      DenseVector(("57643656        116007120").split("\\s+").map(_.toDouble))
    } else {
      DenseVector(arr.map(_.toDouble))
    }
  }

  def closestPoint(p: Vector[Double], centers: Array[Vector[Double]]): Int = {
    var bestIndex = 0
    var closet = Double.PositiveInfinity

    for (i <- 0 until centers.length) {
      val dist = squaredDistance(p, centers(i))
      if (dist < closet) {
        bestIndex = i
        closet = dist
      }
    }

    bestIndex
  }

}
