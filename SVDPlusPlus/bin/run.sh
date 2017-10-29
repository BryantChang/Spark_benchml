#!/bin/bash

bin=`dirname "$0"`
bin=`cd "$bin"; pwd`
DIR=`cd $bin/../; pwd`
. "${DIR}/../bin/config.sh"
. "${DIR}/bin/config.sh"

echo "========== running ${APP} benchmark =========="


# path check

DU ${INPUT_HDFS} SIZE 

JAR="${DIR}/target/SVDPlusPlusApp-1.0.jar"
CLASS="src.main.scala.SVDPlusPlusApp"
OPTION="${INOUT_SCHEME}${INPUT_HDFS} ${INOUT_SCHEME}${OUTPUT_HDFS} ${NUM_OF_PARTITIONS} ${NUM_ITERATION} ${RANK} ${MINVAL} ${MAXVAL} ${GAMMA1} ${GAMMA2} ${GAMMA6} ${GAMMA7} ${STORAGE_LEVEL}"

# echo "opt ${OPTION}"

# echo "start to execute iostat"

# ssh spark2 "sh +x iostat_execute.sh \"dm-2\" ${APP}_${TYPE}_${EXEMEM} &"&

echo "perf_monitor.sh ${MONITOR_LOG_PATH}/${APP}_${TYPE}_${SPARK_EXECUTOR_MEMORY}.log 1 &"

sleep 10

setup
for((i=0;i<${NUM_TRIALS};i++)); do

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

ssh spark2 perf_monitor_stop.sh
# ssh spark2 "iostat_stop.sh ${APP}"
# mv /home/hadoop/bryantchang/platforms/logs/spark/spark.log /home/hadoop/bryantchang/platforms/logs/spark/${APP}_${TYPE}_${EXEMEM}_master.log
# ssh spark2 "mv /home/hadoop/bryantchang/platforms/logs/spark/spark.log /home/hadoop/bryantchang/platforms/logs/spark/${APP}_${TYPE}_${EXEMEM}.log"

teardown
exit 0


