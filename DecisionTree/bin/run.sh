#!/bin/bash

bin=`dirname "$0"`
bin=`cd "$bin"; pwd`

echo "========== running ${APP} benchmark =========="

DIR=`cd $bin/../; pwd`
. "${DIR}/../bin/config.sh"
. "${DIR}/bin/config.sh"



DU ${INPUT_HDFS} SIZE 
JAR="${DIR}/target/DecisionTreeApp-1.0.jar"
CLASS="DecisionTree.src.main.java.DecisionTreeApp"
DEL_OLD_LOGS
ssh spark2 rm -rf /home/hadoop/bryantchang/logs/sparklogs/executor_logs/${APP}_${TYPE}_${SPARK_EXECUTOR_MEMORY}.log
echo "perf_monitor.sh ${MONITOR_LOG_PATH}/${APP}_${TYPE}_${SPARK_EXECUTOR_MEMORY}.log 1 &"

sleep 10

setup
for((i=0;i<${NUM_TRIALS};i++)); do		
	# classification
	RM ${OUTPUT_HDFS_Classification}
	purge_data "${MC_LIST}"	
	OPTION=" ${INOUT_SCHEME}${INPUT_HDFS} ${INOUT_SCHEME}${OUTPUT_HDFS_Classification} ${NUM_OF_CLASS_C} ${impurityC} ${maxDepthC} ${maxBinsC} ${modeC}"
START_TS=`get_start_ts`;
	START_TIME=`timestamp`
	echo_and_run sh -c " ${SPARK_HOME}/bin/spark-submit --class $CLASS --master ${SPARK_MASTER} ${YARN_OPT} ${SPARK_OPT} ${SPARK_RUN_OPT} $JAR ${OPTION} 2>&1|tee ${BENCH_NUM}/DecisionTree_run_${START_TS}.dat"
res=$?;
	END_TIME=`timestamp`
get_config_fields >> ${BENCH_REPORT}
print_config  ${APP} ${START_TIME} ${END_TIME} ${SIZE} ${START_TS} ${res}>> ${BENCH_REPORT};
done

STOP_MONITOR
ssh spark2 mv /home/hadoop/bryantchang/logs/sparklogs/test.log   /home/hadoop/bryantchang/logs/sparklogs/executor_logs/${APP}_${TYPE}_${SPARK_EXECUTOR_MEMORY}.log
ssh spark2 analyse_gc_log.sh ${APP}_${TYPE}_${SPARK_EXECUTOR_MEMORY}.log /home/hadoop/bryantchang/logs/sparklogs/gc_logs
ssh spark2 python /home/hadoop/bryantchang/tools/monitor/summary_gc.py ${APP}_${TYPE}_${SPARK_EXECUTOR_MEMORY}.log
ssh spark2 python /home/hadoop/bryantchang/tools/monitor/analyse_perf.py ${APP}_${TYPE}_${SPARK_EXECUTOR_MEMORY}.log
teardown

exit 0


######################## unused ########################
if [ 1 -eq 0 ]; then
# Regression
	RM ${OUTPUT_HDFS_Regression}
	purge_data "${MC_LIST}"	
	OPTION=" ${INOUT_SCHEME}${INPUT_HDFS} ${INOUT_SCHEME}${OUTPUT_HDFS_Regression} ${NUM_OF_CLASS_R} ${impurityR} ${maxDepthR} ${maxBinsR} ${modeR} "
	START_TIME=`timestamp`
START_TS=`get_start_ts`;
	echo_and_run sh -c " ${SPARK_HOME}/bin/spark-submit --class $CLASS --master ${SPARK_MASTER} $JAR ${OPTION} 2>&1|tee ${BENCH_NUM}/DecisionTree_run_${START_TS}.dat"
res=$?;
	END_TIME=`timestamp`
get_config_fields >> ${BENCH_REPORT}
print_config  ${APP} ${START_TIME} ${END_TIME} ${SIZE} ${START_TS} ${res}>> ${BENCH_REPORT};
fi

