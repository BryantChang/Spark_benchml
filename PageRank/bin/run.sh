#!/bin/bash

bin=`dirname "$0"`
bin=`cd "$bin"; pwd`
DIR=`cd $bin/../; pwd`
. "${DIR}/../bin/config.sh"
. "${DIR}/bin/config.sh"

echo "========== running ${APP}1 benchmark =========="


# path check
DU ${INPUT_HDFS} SIZE 

#JAR="${DIR}/target/scala-2.10/pagerankapp_2.10-1.0.jar"
JAR="${DIR}/target/PageRankApp-1.0.jar"
CLASS="src.main.scala.SimplePageRank"
OPTION="${INOUT_SCHEME}${INPUT_HDFS} ${INOUT_SCHEME}${OUTPUT_HDFS} ${NUM_OF_PARTITIONS} ${MAX_ITERATION} ${TOLERANCE} ${RESET_PROB} ${STORAGE_LEVEL}"

# echo "start to execute iostat"
# sh +x iostat_execute.sh "dm-2" ${APP}_${TYPE}_${EXEMEM} &
# ssh spark2 "sh +x iostat_execute.sh \"dm-2\" ${APP}_${TYPE}_${EXEMEM} &"&
DEL_OLD_LOGS
ssh spark2 rm -rf ${MONITOR_ORI_LOG_DIR}/${APP}_${TYPE}_${SPARK_EXECUTOR_MEMORY}.log
echo "perf_monitor.sh ${MONITOR_ORI_LOG_DIR}/${APP}_${TYPE}_${SPARK_EXECUTOR_MEMORY}.log 1 &"

sleep 10

setup
for((i=0;i<${NUM_TRIALS};i++)); do
	echo "${OPTION}"
	RM ${OUTPUT_HDFS}
	purge_data "${MC_LIST}"	
	START_TS=`get_start_ts`;
	START_TIME=`timestamp`
	echo_and_run sh -c " ${SPARK_HOME}/bin/spark-submit --class $CLASS ${YARN_OPT} --master ${APP_MASTER} ${SPARK_OPT} ${SPARK_RUN_OPT} $JAR ${OPTION} 2>&1|tee ${BENCH_NUM}/${APP}_run_${START_TS}.dat"
res=$?;
	END_TIME=`timestamp`
get_config_fields >> ${BENCH_REPORT}
print_config  ${APP} ${START_TIME} ${END_TIME} ${SIZE} ${START_TS} ${res}>> ${BENCH_REPORT};
done
# iostat_stop.sh ${APP}
# ssh spark2 "iostat_stop.sh ${APP}"
# mv /home/hadoop/bryantchang/platforms/logs/spark/spark.log /home/hadoop/bryantchang/platforms/logs/spark/${APP}_${TYPE}_${EXEMEM}_master.log
# ssh spark2 "mv /home/hadoop/bryantchang/platforms/logs/spark/spark.log /home/hadoop/bryantchang/platforms/logs/spark/${APP}_${TYPE}_${EXEMEM}.log"
ssh spark2 perf_monitor_stop.sh
ssh spark2 mv ${SPARK_EXECUTOR_ORI_LOG_DIR}/test.log   ${MONITOR_ORI_LOG_DIR}/${APP}_${TYPE}_${SPARK_EXECUTOR_MEMORY}.log
ssh spark2 analyse_gc_log.sh ${APP}_${TYPE}_${SPARK_EXECUTOR_MEMORY}.log ${GC_ORI_LOG_DIR}
ssh spark2 sh ${TOOLS_DIR}/bin/summary_gc.sh ${APP}_${TYPE}_${SPARK_EXECUTOR_MEMORY}.log
ssh spark2 sh ${TOOLS_DIR}/bin/analyse_perf.sh ${APP}_${TYPE}_${SPARK_EXECUTOR_MEMORY}.log
teardown
exit 0


