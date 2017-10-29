# for prepare #200M=1million points
m=8000 
n=500
rank=10
trainSampFact=0.9
noise=false
sigma=0.1
test=false
testSampFact=0.1
NUM_OF_PARTITIONS=10

##### for running ####
MAX_ITERATION=3 #90 # 3
LAMBDA=0.01
NUM_RUN=1


TYPE="1200M"
SPARK_EXECUTOR_MEMORY="1800m"
STORAGE_LEVEL="MEMORY_AND_DISK_SER"
#SPARK_RDD_COMPRESS=true
#SPARK_IO_COMPRESSION_CODEC=lzf
