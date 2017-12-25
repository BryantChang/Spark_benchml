#!/bin/bash


bin=`dirname "$0"`
bin=`cd "$bin"; pwd`
DIR=`cd $bin/../; pwd`
. "${DIR}/../bin/config.sh"
. "${DIR}/bin/config.sh"

echo "========== Running ${APP} Workload =========="

DU ${INPUT_HDFS} SIZE 
CLASS="SVM.src.main.java.SVMApp"
OPTION=" ${INOUT_SCHEME}${INPUT_HDFS} ${INOUT_SCHEME}${OUTPUT_HDFS} ${MAX_ITERATION} ${STORAGE_LEVEL}"
JAR="${DIR}/target/SVMApp-1.0.jar"

CORES=`cat ${SPARK_HOME}/conf/spark-defaults.conf | grep 'spark.executor.cores' | cut -d ' ' -f 2`
PARALLELISM=`cat ${SPARK_HOME}/conf/spark-defaults.conf | grep 'spark.default.parallelism' | cut -d ' ' -f 2`
RDD_COMPRESS=`cat ${SPARK_HOME}/conf/spark-defaults.conf | grep 'spark.rdd.compress' | cut -d ' ' -f 2`
SHUFFLE_COMPRESS=`cat ${SPARK_HOME}/conf/spark-defaults.conf | grep 'spark.shuffle.compress' | cut -d ' ' -f 2`
DEL_OLD_LOGS
ssh spark2 rm -rf ${EXECUTOR_ORI_LOG_DIR}/${APP}_${TYPE}_${SPARK_EXECUTOR_MEMORY}_${CORES}_${PARALLELISM}_${RDD_COMPRESS}_${SHUFFLE_COMPRESS}.log
nohup ssh spark2 -t -t "perf_monitor.sh ${MONITOR_ORI_LOG_DIR}/${APP}_${TYPE}_${SPARK_EXECUTOR_MEMORY}_${CORES}_${PARALLELISM}_${RDD_COMPRESS}_${SHUFFLE_COMPRESS}.log" &

setup
for((i=0;i<${NUM_TRIALS};i++)); do
	# path check	
	RM ${OUTPUT_HDFS}
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
exit 0

