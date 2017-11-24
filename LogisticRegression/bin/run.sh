#!/bin/bash

bin=`dirname "$0"`
bin=`cd "$bin"; pwd`
DIR=`cd $bin/../; pwd`
. "${DIR}/../bin/config.sh"
. "${DIR}/bin/config.sh"

echo "========== running ${APP} workload =========="


DU ${INPUT_HDFS} SIZE 
CLASS="LogisticRegression.src.main.java.LogisticRegressionApp"
OPTION=" ${INOUT_SCHEME}${INPUT_HDFS} ${INOUT_SCHEME}${OUTPUT_HDFS}  ${MAX_ITERATION} ${STORAGE_LEVEL} "

JAR="${DIR}/target/LogisticRegressionApp-1.0.jar"
DEL_OLD_LOGS
ssh spark2 rm -rf ${MONITOR_ORI_LOG_DIR}/${APP}_${TYPE}_${SPARK_EXECUTOR_MEMORY}.log
echo "perf_monitor.sh ${MONITOR_ORI_LOG_DIR}/${APP}_${TYPE}_${SPARK_EXECUTOR_MEMORY}.log 1 &"

sleep 10

setup
for((i=0;i<${NUM_TRIALS};i++)); do
    RM ${OUTPUT_HDFS}
    purge_data "${MC_LIST}"	
    START_TS=`get_start_ts`;

    START_TIME=`timestamp`
    echo_and_run sh -c " ${SPARK_HOME}/bin/spark-submit --class $CLASS --master ${APP_MASTER} ${YARN_OPT} ${SPARK_OPT} ${SPARK_RUN_OPT} $JAR ${OPTION} 2>&1|tee ${BENCH_NUM}/${APP}_run_${START_TS}.dat"
    res=$?
    END_TIME=`timestamp`
    get_config_fields >> ${BENCH_REPORT}
    print_config  ${APP} ${START_TIME} ${END_TIME} ${SIZE} ${START_TS} ${res}>> ${BENCH_REPORT}
done
ssh spark2 perf_monitor_stop.sh
ssh spark2 mv ${SPARK_EXECUTOR_ORI_LOG_DIR}/test.log   ${MONITOR_ORI_LOG_DIR}/${APP}_${TYPE}_${SPARK_EXECUTOR_MEMORY}.log
ssh spark2 analyse_gc_log.sh ${APP}_${TYPE}_${SPARK_EXECUTOR_MEMORY}.log ${GC_ORI_LOG_DIR}
ssh spark2 sh ${TOOLS_DIR}/bin/summary_gc.sh ${APP}_${TYPE}_${SPARK_EXECUTOR_MEMORY}.log
ssh spark2 sh ${TOOLS_DIR}/bin/analyse_perf.sh ${APP}_${TYPE}_${SPARK_EXECUTOR_MEMORY}.log
teardown
exit 0

