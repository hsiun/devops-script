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

function killProcess(){
	echo '正在停止进程' $1
	kill -9 $(ps -ef|grep $1|grep -v grep|awk '{ print $2}')
	sleep 1
}

function stopHadoop() {
	echo "正在停止Hadoop"
	cd $HADOOP_HOME/sbin
	./stop-all.sh
}

function stopNginx() {
	echo "正在停止Nginx"
	nginx -s stop
}

function stopMysql(){
	echo "正在停止Mysql"
	sudo /usr/local/mysql/support-files/mysql.server stop
}

function mainFun() {
	count=0
	# 杀死redis服务的进程
	check "redis"
	if [[ $count -ne 0 ]]; then
		#statements
		killProcess "redis"
		check "redis"
	fi
	echo ""

	# 关闭zookeeper服务
	check "zookeeper"
	if [[ $count -ne 0 ]]; then
		#statements
		killProcess "zookeeper"
		check "zookeeper"
	fi
	echo ""

	# 关闭Hadoop服务
	check "hadoop"
	if [[ $count -ne 0 ]]; then
		#statements
		stopHadoop
		check "hadoop"
	fi
	echo ""

	# 关闭Kafka服务
	check "kafka"
	if [[ $count -ne 0 ]]; then
		#statements
		killProcess "kafka"
		check "kafka"
	fi
	echo ""

	# 关闭Elasticsearch
	check "elasticsearch"
	if [[ $count -ne 0 ]]; then
		#statements
		killProcess "elasticsearch"
		check "elasticsearch"
	fi
	echo ""

	# 关闭nginx服务
	check "nginx"
	if [[ $count -ne 0 ]]; then
		#statements
		stopNginx
		check "nginx"
	fi
	echo ""

	# 关闭Mysql
	# check "mysql"
	# if [[ $count -ne 0 ]]; then
	# 	#statements
	# 	stopMysql
	# 	check "mysql"
	# fi
	

}

mainFun

