# !/bin/bash

#Step1, Check JDK exists or not !
for i in $(rpm -qa | grep jdk | grep -v grep)
do
    echo "-->[`data +"%Y-%m-%d %H:%M.%S"`] Deleting "$i
    rpm -e --nodeps $i
done

#Step2, Feedback if JDK was uninstalled or not !
if [[ -n $(rpm -qa | grep jdk | grep -v grep) ]];
then
    echo "-->[`date +"%Y-%m-%d %H:%M.%S"`] Failed to delete the $i"
    exit 0
else
    echo "-->[`date +"%Y-%m-%d %H:%M.%S"`] Successfully delete $i"

    # Step3, Install JDK
    JAVA_HOME=/usr/java
    if [[ -n $JAVA_HOME ]]
    then
       rm -rf $JAVA_HOME
    fi
    tar -zxf $1 -C /usr/
    mv /usr/jdk* /usr/java
    echo "-->[`date +"%Y-%m-%d %H:%M.%S"`] Successfully install $i"
fi

#Step3, Config JDK env
cp /etc/profile /etc/profile.bk
if [ -z "`grep "JAVA_HOME" /etc/profile`" ]
then
    echo "# For jdk start" >> /etc/profile
    echo "export JAVA_HOME=$JAVA_HOME" >> /etc/profile
    echo "export JRE_HOME=$JAVA_HOME/jre" >> /etc/profile
    echo "export CLASSPATH=.:$JAVA_HOME/lib:$JAVA__HOME/jre/lib" >> /etc/profile
    echo "export PATH=\$JAVA_HOME/bin:\$PATH" >> /etc/profile
    echo "# For jdk end" >> /etc/profile

    if [ $? -eq 0 ]
    then
        source /etc/profile
        echo "-->[`date +"%Y-%m-%d %H:%M.%S"`] JDK environment has been successed set in /etc/profile"
        echo "-->[`date +"%Y-%m-%d %H:%M.%S"`] java -version"
        java -version
    fi
else
   echo "-->[`date +"%Y-%m-%d %H:%M.%S"`] JDK environment not need set again"
fi


#Step4, Test JDK funcation
touch Test.java
echo "public class Test {" >> Test.java
echo "    public static void main(String[] args){" >> Test.java
echo "        System.out.println(\"-->Test!!!\");" >> Test.java
echo "    }" >> Test.java
echo "}" >> Test.java

if [ -f Test.class ]
then
    rm -f Test.class
fi

javac Test.java
if [ $? -eq 0 ]
then 
    echo "-->[`date +"%Y-%m-%d %H:%M.%S"`] Successfully Complie"
    java Test
    echo "-->[`date +"%Y-%m-%d %H:%M.%S"`] If you see the 'Test!!!', JDK was on right position"
else
    echo "-->[`date +"%Y-%m-%d %H:%M.%S"`] JDK was worry!!!"
fi

rm -rf Test*
