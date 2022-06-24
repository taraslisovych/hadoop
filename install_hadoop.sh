#!/bin/bash

apt-get update
apt-get -y dist-upgrade
apt-get -y install openjdk-8-jdk-headless

wget https://dlcdn.apache.org/hadoop/common/hadoop-2.10.2/hadoop-2.10.2.tar.gz
tar xvzf hadoop-2.10.2.tar.gz
mv hadoop-2.10.2 hadoop

export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
export HADOOP_HOME=/home/ubuntu/hadoop
export HADOOP_CONF=$HADOOP_HOME/conf
export PATH=$PATH:$JAVA_HOME:$HADOOP_HOME/bin

sed -i "s|127.0.0.1|$(curl http://169.254.169.254/latest/meta-data/local-ipv4)|g" /etc/hosts
sed -i "s|localhost|$(curl http://169.254.169.254/latest/meta-data/public-hostname)|g" /etc/hosts

echo -e "\nexport JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64" >> /home/ubuntu/.bashrc
echo -e "export HADOOP_HOME=/home/ubuntu/hadoop	" >> /home/ubuntu/.bashrc
echo -e "export HADOOP_CONF=$HADOOP_HOME/conf" >> /home/ubuntu/.bashrc
echo -e "export PATH=\$PATH:\$JAVA_HOME:\$HADOOP_HOME/bin" >> /home/ubuntu/.bashrc
#source /home/ubuntu/.bashrc

mkdir -p /usr/local/hadoop/hdfs/data
chown ubuntu:ubuntu /usr/local/hadoop/hdfs/data
