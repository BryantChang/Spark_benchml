#!/usr/bin/env bash
# global settings

master=spark1
slave=spark2

TOOLS_DIR="/home/hadoop/bryantchang/tools/awsmc"
# TOOLS_DIR="/home/zc/bryantchang/tools/awsmc"

##Log locations


# EXECUTOR_ORI_LOG_DIR="/home/zc/bryantchang/logs/executor_logs"
# MONITOR_ORI_LOG_DIR="/home/zc/bryantchang/logs/monitor_logs"
# MONITOR_RES_LOG_DIR="/home/zc/bryantchang/logs/monitor_logs/analyse_result"
# GC_ORI_LOG_DIR="/home/zc/bryantchang/logs/gc_logs"
# GC_RES_LOG_DIR="/home/zc/bryantchang/logs/gc_logs/gc_result"

EXECUTOR_ORI_LOG_DIR="/home/hadoop/bryantchang/logs/sparklogs/executor_logs"
MONITOR_ORI_LOG_DIR="/home/hadoop/bryantchang/logs/sparklogs/monitor_logs"
MONITOR_RES_LOG_DIR="/home/hadoop/bryantchang/logs/sparklogs/monitor_logs/analyse_result"
GC_ORI_LOG_DIR="/home/hadoop/bryantchang/logs/sparklogs/gc_logs"
GC_RES_LOG_DIR="/home/hadoop/bryantchang/logs/sparklogs/gc_logs/gc_result"
SPARK_EXECUTOR_ORI_LOG_DIR="/home/hadoop/bryantchang/logs/sparklogs"
#A list of machines where the spark cluster is running
MC_LIST=/YOUR/SLAVES
FILESYSTEM="hdfs"
[ -z "$HADOOP_HOME" ] &&     export HADOOP_HOME=/home/zc/hadoop-2.3.0
# base dir for DataSet
HDFS_URL="hdfs://${master}:9000"
SPARK_HADOOP_FS_LOCAL_BLOCK_SIZE=134217728

# DATA_HDFS="hdfs://${master}:9000/SparkBench", "file:///home/`whoami`/SparkBench"
DATA_HDFS="hdfs://${master}:9000/BryantChang/SparkBench"

#Local dataset optional
DATASET_DIR=/home/hadoop/bryantchang/codes/SparkBench/DataSet

SPARK_VERSION=2.0.2  #1.5.1
[ -z "$SPARK_HOME" ] &&     export SPARK_HOME=/home/zc/sparkdir/spark_platforms/spark-hadoop2.3

#SPARK_MASTER=local
#SPARK_MASTER=local[K]
#SPARK_MASTER=local[*]
#SPARK_MASTER=spark://HOST:PORT
##SPARK_MASTER=mesos://HOST:PORT
##SPARK_MASTER=yarn-client
##SPARK_MASTER=yarn-cluster
SPARK_MASTER=spark://${master}:7077



# Spark config in environment variable or aruments of spark-submit 
# - SPARK_SERIALIZER, --conf spark.serializer
# - SPARK_RDD_COMPRESS, --conf spark.rdd.compress
# - SPARK_IO_COMPRESSION_CODEC, --conf spark.io.compression.codec
# - SPARK_DEFAULT_PARALLELISM, --conf spark.default.parallelism
#SPARK_SERIALIZER=org.apache.spark.serializer.KryoSerializer
#SPARK_RDD_COMPRESS=false
#SPARK_IO_COMPRESSION_CODEC=lzf

# Spark options in system.property or arguments of spark-submit 
# - SPARK_EXECUTOR_MEMORY, --conf spark.executor.memory
# - SPARK_STORAGE_MEMORYFRACTION, --conf spark.storage.memoryfraction
#SPARK_STORAGE_MEMORYFRACTION=0.5
#export MEM_FRACTION_GLOBAL=0.005

# Spark options in YARN client mode
# - SPARK_DRIVER_MEMORY, --driver-memory
# - SPARK_EXECUTOR_INSTANCES, --num-executors
# - SPARK_EXECUTOR_CORES, --executor-cores
# - SPARK_DRIVER_MEMORY, --driver-memory
#export EXECUTOR_GLOBAL_MEM=6g
#export executor_cores=6

# Storage levels, see http://spark.apache.org/docs/latest/api/java/org/apache/spark/api/java/StorageLevels.html
# - STORAGE_LEVEL, set MEMORY_AND_DISK, MEMORY_AND_DISK_SER, MEMORY_ONLY, MEMORY_ONLY_SER, or DISK_ONLY
#STORAGE_LEVEL=MEMORY_AND_DISK

# for data generation
NUM_OF_PARTITIONS=10
# for running
NUM_TRIALS=1
SPARK_EXECUTOR_CORES=3
