#!/bin/bash

bin=`dirname "$0"`
bin=`cd "$bin"; pwd`
DIR=`cd $bin/../; pwd`
. "${DIR}/../bin/config.sh"
. "${DIR}/bin/config.sh"

echo "========== running ${APP} benchmark =========="


# path check
DU ${INPUT_HDFS} SIZE 

JAR="${DIR}/target/TerasortApp-1.0-jar-with-dependencies.jar"
CLASS="src.main.scala.terasortApp"
OPTION="${INOUT_SCHEME}${INPUT_HDFS} ${INOUT_SCHEME}${OUTPUT_HDFS} "
Addition_jar="--jars ${DIR}/target/jars/guava-19.0-rc2.jar"


# echo "start to execute iostat"
# ssh spark2 "sh +x iostat_execute.sh \"dm-2\" ${APP}_${TYPE} &"&
CORES=`cat ${SPARK_HOME}/conf/spark-defaults.conf | grep 'spark.executor.cores' | cut -d ' ' -f 2`
PARALLELISM=`cat ${SPARK_HOME}/conf/spark-defaults.conf | grep 'spark.default.parallelism' | cut -d ' ' -f 2`
RDD_COMPRESS=`cat ${SPARK_HOME}/conf/spark-defaults.conf | grep 'spark.rdd.compress' | cut -d ' ' -f 2`
SHUFFLE_COMPRESS=`cat ${SPARK_HOME}/conf/spark-defaults.conf | grep 'spark.shuffle.compress' | cut -d ' ' -f 2`
DEL_OLD_LOGS
ssh spark2 "${TOOLS_DIR}/bin/delete_log.sh one ${APP} ${TYPE} ${SPARK_EXECUTOR_MEMORY}"
nohup ssh spark2 -t -t "perf_monitor.sh ${MONITOR_ORI_LOG_DIR}/${APP}_${TYPE}_${SPARK_EXECUTOR_MEMORY}_${CORES}_${PARALLELISM}_${RDD_COMPRESS}_${SHUFFLE_COMPRESS}.log" &
setup
for((i=0;i<${NUM_TRIALS};i++)); do
    echo "${APP} opt ${OPTION}"
    RM ${OUTPUT_HDFS}
    purge_data "${MC_LIST}"	
    START_TS=`get_start_ts`;
    START_TIME=`timestamp`
    echo_and_run sh -c " ${SPARK_HOME}/bin/spark-submit --class $CLASS --master ${APP_MASTER} ${YARN_OPT} ${SPARK_OPT} ${SPARK_RUN_OPT} ${Addition_jar} $JAR ${OPTION} 2>&1|tee ${BENCH_NUM}/${APP}_run_${START_TS}.dat"
    res=$?;
    END_TIME=`timestamp`
    get_config_fields >> ${BENCH_REPORT}
    print_config  ${APP} ${START_TIME} ${END_TIME} ${SIZE} ${START_TS} ${res}>> ${BENCH_REPORT};
done
# ssh spark2 "iostat_stop.sh ${APP}"
STOP_MONITOR
ssh spark2 mv ${SPARK_EXECUTOR_ORI_LOG_DIR}/test.log   ${EXECUTOR_ORI_LOG_DIR}/${APP}_${TYPE}_${SPARK_EXECUTOR_MEMORY}_${CORES}_${PARALLELISM}_${RDD_COMPRESS}_${SHUFFLE_COMPRESS}.log
ssh spark2 analyse_gc_log.sh ${APP}_${TYPE}_${SPARK_EXECUTOR_MEMORY}_${CORES}_${PARALLELISM}_${RDD_COMPRESS}_${SHUFFLE_COMPRESS}.log ${GC_ORI_LOG_DIR}
ssh spark2 sh ${TOOLS_DIR}/bin/summary_gc.sh ${APP}_${TYPE}_${SPARK_EXECUTOR_MEMORY}_${CORES}_${PARALLELISM}_${RDD_COMPRESS}_${SHUFFLE_COMPRESS}.log
ssh spark2 sh ${TOOLS_DIR}/bin/analyse_perf.sh ${APP}_${TYPE}_${SPARK_EXECUTOR_MEMORY}_${CORES}_${PARALLELISM}_${RDD_COMPRESS}_${SHUFFLE_COMPRESS}.log
teardown
exit 0


