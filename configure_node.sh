#!/bin/bash

ssh-keyscan -H $1 >> ~/.ssh/known_hosts
scp -i /tmp/Hadoop_key.pem /home/ubuntu/.ssh/id_rsa.pub ubuntu@$1:/tmp/id_rsa.pub
ssh -i /tmp/Hadoop_key.pem ubuntu@$1 'cat /tmp/id_rsa.pub >> /home/ubuntu/.ssh/authorized_keys'
scp /home/ubuntu/hadoop/etc/hadoop/hadoop-env.sh /home/ubuntu/hadoop/etc/hadoop/core-site.xml /home/ubuntu/hadoop/etc/hadoop/hdfs-site.xml /home/ubuntu/hadoop/etc/hadoop/mapred-site.xml /home/ubuntu/hadoop/etc/hadoop/yarn-site.xml ubuntu@$1:/home/ubuntu/hadoop/etc/hadoop
scp /home/ubuntu/hadoop/etc/hadoop/slaves ubuntu@$1:/home/ubuntu/hadoop/etc/hadoop
echo $1 >> $HADOOP_HOME/etc/hadoop/slaves
ssh ubuntu@$1 "sudo apt-get update"
ssh ubuntu@$1 "sudo apt-get -y install openjdk-8-jdk-headless"
