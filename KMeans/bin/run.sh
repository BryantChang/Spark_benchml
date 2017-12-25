#!/bin/bash
bin=`dirname "$0"`
bin=`cd "$bin"; pwd`
DIR=`cd $bin/../; pwd`
. "${DIR}/../bin/config.sh"
. "${DIR}/bin/config.sh"

echo "========== running ${APP} bench =========="


# pre-running
DU ${INPUT_HDFS} SIZE 

JAR="${DIR}/target/KMeansApp-1.0.jar"
CLASS="kmeans_min.src.main.scala.SimpleKMeans"
OPTION=" ${INPUT_HDFS} ${OUTPUT_HDFS} ${NUM_OF_CLUSTERS} ${MAX_ITERATION} ${STORAGE_LEVEL} ${NUM_OF_PARTITIONS}"
echo $OPTION
if  [ $# -ge 1 ] && [ $1 = "graphx" ]; then

	APP=KMeans
	CLASS="KmeansApp"
	OPTION=" ${INOUT_SCHEME}${INPUT_HDFS} ${INOUT_SCHEME}${OUTPUT_HDFS} ${NUM_OF_CLUSTERS} ${MAX_ITERATION} ${NUM_RUN}"
fi
CORES=`cat ${SPARK_HOME}/conf/spark-defaults.conf | grep 'spark.executor.cores' | cut -d ' ' -f 2`
PARALLELISM=`cat ${SPARK_HOME}/conf/spark-defaults.conf | grep 'spark.default.parallelism' | cut -d ' ' -f 2`
RDD_COMPRESS=`cat ${SPARK_HOME}/conf/spark-defaults.conf | grep 'spark.rdd.compress' | cut -d ' ' -f 2`
SHUFFLE_COMPRESS=`cat ${SPARK_HOME}/conf/spark-defaults.conf | grep 'spark.shuffle.compress' | cut -d ' ' -f 2`
DEL_OLD_LOGS
ssh spark2 rm -rf ${EXECUTOR_ORI_LOG_DIR}/${APP}_${TYPE}_${SPARK_EXECUTOR_MEMORY}_${CORES}_${PARALLELISM}_${RDD_COMPRESS}_${SHUFFLE_COMPRESS}.log
nohup ssh spark2 -t -t "perf_monitor.sh ${MONITOR_ORI_LOG_DIR}/${APP}_${TYPE}_${SPARK_EXECUTOR_MEMORY}_${CORES}_${PARALLELISM}_${RDD_COMPRESS}_${SHUFFLE_COMPRESS}.log" &


echo "start to execute"
# sh +x iostat_execute.sh "dm-2" ${APP}_${TYPE}_${EXEMEM} &
# ssh spark2 "sh +x iostat_execute.sh \"dm-2\" ${APP}_${TYPE}_${EXEMEM} &"&

setup

for((i=0;i<${NUM_TRIALS};i++)); do
    RM ${OUTPUT_HDFS}
    # (Optional procedure): free page cache, dentries and inodes.
    # purge_data "${MC_LIST}"
    START_TS=`get_start_ts`;
    START_TIME=`timestamp`

    echo_and_run sh -c " ${SPARK_HOME}/bin/spark-submit --class $CLASS --master ${APP_MASTER} ${YARN_OPT} ${SPARK_OPT} ${SPARK_RUN_OPT} $JAR ${OPTION} 2>&1|tee ${BENCH_NUM}/${APP}_run_${START_TS}.dat"
    res=$?;

    END_TIME=`timestamp`
    get_config_fields >> ${BENCH_REPORT}
    print_config  ${APP} ${START_TIME} ${END_TIME} ${SIZE} ${START_TS} ${res}>> ${BENCH_REPORT};
done
STOP_MONITOR
ssh spark2 mv ${SPARK_EXECUTOR_ORI_LOG_DIR}/test.log   ${EXECUTOR_ORI_LOG_DIR}/${APP}_${TYPE}_${SPARK_EXECUTOR_MEMORY}_${CORES}_${PARALLELISM}_${RDD_COMPRESS}_${SHUFFLE_COMPRESS}.log
ssh spark2 analyse_gc_log.sh ${APP}_${TYPE}_${SPARK_EXECUTOR_MEMORY}_${CORES}_${PARALLELISM}_${RDD_COMPRESS}_${SHUFFLE_COMPRESS}.log ${GC_ORI_LOG_DIR}
ssh spark2 sh ${TOOLS_DIR}/bin/summary_gc.sh ${APP}_${TYPE}_${SPARK_EXECUTOR_MEMORY}_${CORES}_${PARALLELISM}_${RDD_COMPRESS}_${SHUFFLE_COMPRESS}.log
ssh spark2 sh ${TOOLS_DIR}/bin/analyse_perf.sh ${APP}_${TYPE}_${SPARK_EXECUTOR_MEMORY}_${CORES}_${PARALLELISM}_${RDD_COMPRESS}_${SHUFFLE_COMPRESS}.log
# iostat_stop.sh ${APP}
# ssh spark2 "iostat_stop.sh ${APP}"
# ssh spark2 "mv /home/hadoop/bryantchang/platforms/logs/spark/spark.log /home/hadoop/bryantchang/platforms/logs/spark/${APP}_${TYPE}_${EXEMEM}.log"
teardown

exit 0

