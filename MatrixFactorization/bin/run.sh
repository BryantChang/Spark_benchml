#!/bin/bash

bin=`dirname "$0"`
bin=`cd "$bin"; pwd`
DIR=`cd $bin/../; pwd`
. "${DIR}/../bin/config.sh"
. "${DIR}/bin/config.sh"
echo "========== running MF benchmark =========="

DU ${INPUT_HDFS} SIZE 


CLASS="MatrixFactorization.src.main.java.MFApp"
OPTION="${INPUT_HDFS} ${OUTPUT_HDFS} ${rank} ${MAX_ITERATION} ${LAMBDA} ${STORAGE_LEVEL}"
echo $OPTION
JAR="${DIR}/target/MFApp-1.0.jar"

#CLASS="src.main.scala.MFMovieLens"
#OPTION=" ${INOUT_SCHEME}${INPUT_HDFS} ${DATASET_DIR}/ml-10M100K/personalRatings.txt"
#OPTION=" ${INOUT_SCHEME}${INPUT_HDFS} ${DATASET_DIR}/BigDataGeneratorSuite/Graph_datagen/personalRatings.txt $NUM_OF_PARTITIONS"
DEL_OLD_LOGS
ssh spark2 rm -rf /home/hadoop/bryantchang/logs/sparklogs/executor_logs/${APP}_${TYPE}_${SPARK_EXECUTOR_MEMORY}.log
nohup ssh spark2 -t -t "perf_monitor.sh ${MONITOR_ORI_LOG_DIR}/${APP}_${TYPE}_${SPARK_EXECUTOR_MEMORY}.log" &


setup
for((i=0;i<${NUM_TRIALS};i++)); do		
    # path check
    RM ${OUTPUT_HDFS}
    purge_data "${MC_LIST}"	
    START_TS=`get_start_ts`;

    START_TIME=`timestamp`
    echo_and_run sh -c " ${SPARK_HOME}/bin/spark-submit --class $CLASS --master ${APP_MASTER} ${YARN_OPT} ${SPARK_OPT} ${SPARK_RUN_OPT} $JAR ${OPTION} 2>&1|tee ${BENCH_NUM}/${APP}_run_${START_TS}.dat"
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


