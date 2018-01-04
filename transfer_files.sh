#!/bin/sh  
  
#该脚本使用nohup指令后台运行：nohup sh transfer_files.sh > /home/coswadmin/he/scplog/scp.log 2>&1 &  
#查询当前后台执行脚本的pid：ps -ef|grep 'transfer_files.sh'  
#停止进程：kill -9 pid  
  
#解决shell脚本中SCP命令需要输入密码的问题：http://blog.csdn.net/chris_playnow/article/details/22579139  
  
#定义变量值  
folder=/home/coswadmin/ftp  
#scp远程目的目录  
remote_folder=/home/cosw/he  
  
now=$(date '+%Y-%m-%d %H:%M:%S')  
  
#log folder  
log_dir="/home/coswadmin/he/scplog"  
log_file="$log_dir/log_${now}.log"  
log_file="$log_dir/scp.log"  
  
#对账文件备份目录  
bak_dir='/home/coswadmin/he/checkfile_bak'  
  
#--parents,此选项后，可以是一个路径名称。  
#若路径中的某些目录尚不存在，系统将自动建立好那些尚不存在的目录。  
#即一次可以建立多个目录。  
mkdir -p $log_dir  
mkdir -p $bak_dir  
  
#进入ftp对账文件目录  
cd $folder  
  
#统计当前文件夹下对账文件数量，并赋值到fileNum  
fileNum=$(ls -l |grep "^-"|wc -l)  
  
while true  
do  
      now=$(date '+%Y-%m-%d %H:%M:%S')  
      fileNum=$(ls -l |grep "^-"|wc -l)  
      #如果文件数量大于0，则说明存在对账文件，执行文件移动操作，将文件移动到另一台服务器  
      if [ $fileNum -gt 0 ]    
      then     
         #遍历当前文件夹，输出其下文件名,下面移动方式会将文件夹一起进行移动  
         for file_a in $folder/*; do   
             echo -e $now' 开始移动对账文件' >> $log_file        
             temp_file=`basename $file_a`   
             #1、文件名输入到文件          
             echo $temp_file     >> $log_file   
             #2、文件移动到指定服务器scp，  
             scp $temp_file cosw@172.16.66.86:/home/cosw/he_account   
             #3、文件移动到备份文件夹  
             exec mv $temp_file  $bak_dir &  
             echo -e $now' 对账文件移动结束' >> $log_file    
         done   
      else    
         echo $now' 当前没有需要移动的对账文件' >> $log_file    
      fi  
      #休眠1小时        
      sleep 5  
done  
  
echo -e '' >> $log_file  
echo -e '' >> $log_file  
