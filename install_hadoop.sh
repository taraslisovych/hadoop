#!/bin/bash
sudo apt-get update && sudo apt-get -y dist-upgrade
sudo apt-get -y install openjdk-8-jdk-headless

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

# ++++++++++++++++++++ Namenode +++++++++++++++++++++++++++
#
#ec2=$(curl http://169.254.169.254/latest/meta-data/public-hostname)
#
# hadoop-env.sh configuration
#sed -i -r "s|export JAVA_HOME|# export JAVA_HOME|g" /home/ubuntu/hadoop/etc/hadoop/hadoop-env.sh
#line_nm=$(grep -n "export JAVA_HOME" /home/ubuntu/hadoop/etc/hadoop/hadoop-env.sh | cut -d: -f1)
#sed -i "$(($line_nm+1)) i export JAVA_HOME=$JAVA_HOME" /home/ubuntu/hadoop/etc/hadoop/hadoop-env.sh
#
# core-site.xml configuration
#echo -e "<configuration>\n\t<property>\n\t\t<name>fs.defaultFS</name>\n\t\t<value>hdfs://$ec2:9000</value>\n\t</property>\n</configuration>" > /home/ubuntu/hadoop/etc/hadoop/core-site.xml
#
# hdfs-site.xml configuration
#echo -e "<configuration>\n\t<property>\n\t\t<name>dfs.replication</name>\n\t\t<value>2</value>\n\t</property>\n\t<property>\n\t\t<name>dfs.namenode.name.dir</name>\n\t\t<value>file:///usr/local/hadoop/hdfs/data</value>\n\t</property>\n</configuration>" > /home/ubuntu/hadoop/etc/hadoop/hdfs-site.xml
#
# mapred-site.xml configuration
#echo -e "<configuration>\n\t<property>\n\t\t<name>mapreduce.framework.name</name>\n\t\t<value>yarn</value>\n\t</property>\n</configuration>" > /home/ubuntu/hadoop/etc/hadoop/mapred-site.xml
#
# yarn-site.xml configuration
#echo -e "<configuration>\n\t<property>\n\t\t<name>yarn.nodemanager.aux-services</name>\n\t\t<value>mapred_shuffle</value>\n\t</property>\n\t<property>\n\t\t<name>yarn.resourcenamager.hostname</name>\n\t\t<value>$ec2</value>\n\t</property>\n</configuration>" > /home/ubuntu/hadoop/etc/hadoop/yarn-site.xml
#
#ssh-keygen -t rsa -P '' -f /home/ubuntu/.ssh/id_rsa
#chown ubuntu:ubuntu /home/ubuntu/.ssh/id_rsa
