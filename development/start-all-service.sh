#!/bin/bash

function check(){
    count=`ps -ef |grep $1 |grep -v "grep" |wc -l`
    #echo $count
    if [ 0 == $count ];then
        echo $1 "已停止..."
    else
    	echo $1 "已启动..."
    fi
}

function startRedis(){
	echo 'Redis集群正在启动中...'

	cd $REDIS_HOME/src
	./redis-server ../conf/redis_master.conf &
	./redis-server ../conf/redis_slave.conf &
	./redis-sentinel ../conf/sentinel.conf &
	sleep 1
}

function startZookeeper() {
	echo 'Zookeeper正在启动中...'
	cd $ZOOKEEPER_HOME/bin
	./zkServer.sh start
	sleep 1
}

function startHadoop() {
	echo 'Hadoop正在启动中...'
	cd $HADOOP_HOME/sbin
	./start-all.sh
	sleep 1
}

function statKafka() {
	echo 'Kafka集群正在启动中...'
	cd $KAFKA_HOME/bin
	nohup ./kafka-server-start.sh ../config/server-1.properties >> $KAFKA_HOME/logs/kafka-1.log 2>&1 &
	nohup ./kafka-server-start.sh ../config/server-2.properties >> $KAFKA_HOME/logs/kafka-2.log 2>&1 &
	nohup ./kafka-server-start.sh ../config/server-3.properties >> $KAFKA_HOME/logs/kafka-3.log 2>&1 &
	sleep 1
}


function startEs() {
	echo 'elasticsearch正在启动中...'
	cd $ES_HOME/bin
	sh elasticsearch -d
	sleep 1
}

function startNginx() {
	echo 'nginx正在启动中...'
	nginx
	sleep 1
}


function startMysql() {
	echo 'Mysql正在启动中...'
	sudo /usr/local/MySQL/support-files/mysql.server start
	sleep 1
}

function MainFunc(){
# 启动redis集群
isStart="null"
count=0


check "redis"
if [[ $count -eq 0 ]]; then
	#statements
	echo '请输入Y启动Redis集群！'
	read isStart
	if [[ $isStart == "Y" ]]; then
		startRedis
		check "redis"
	fi
fi
echo ""

# 启动zookeeper相关服务
check "zookeeper"
if [[ $count -eq 0 ]]; then
	#statements
	echo '请输入Y启动Zookeeper！'
	read isStart
	if [[ $isStart == "Y" ]]; then
		startZookeeper
		check "redis"
	fi
fi
echo ""

# 启动Hadoop相关服务
check "hadoop"
if [[ $count -eq 0 ]]; then
	#statements
	echo '请输入Y启动Hadoop！'
	read isStart
	if [[ $isStart == "Y" ]]; then
		startHadoop
		check "hadoop"
	fi
fi
echo ""

# 启动Kafka服务，采用Kafka单节点多Broker部署
check "kafka"
if [[ $count -eq 0 ]]; then
	echo '请输入Y启动Kafka集群！'
	read isStart
	if [[ $isStart == "Y" ]]; then
		statKafka
		check "kafka"
	fi
	#statements
fi
echo ""

# 启动Elasticsearch
check "elasticsearch"
if [[ $count -eq 0 ]]; then
	#statements
	echo '请输入Y启动elasticsearch！'
	read isStart
	if [[ $isStart == "Y" ]]; then
		#statements
		startEs
		check "elasticsearch"
	fi
fi
echo ""


# 启动nnginx
check "nginx"
if [[ $count -eq 0 ]]; then
	#statements
	echo '请输入Y启动nginx！'
	read isStart
	if [[ $isStart == "Y" ]]; then
		#statements
		startNginx
		check "nginx"
	fi

fi
echo ""


# 启动mysql
check "mysql"
if [[ $count -eq 0 ]]; then
	#statements
	echo '请输入Y启动Mysql！'
	read isStart
	if [[ $isStart == "Y" ]]; then
		#statements
		startMysql
		check "mysql"
	fi
fi


}

MainFunc

