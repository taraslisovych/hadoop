#!/bin/bash

ssh-keygen -t rsa -P '' -f /home/ubuntu/.ssh/id_rsa
chown ubuntu:ubuntu /home/ubuntu/.ssh/id_rsa

ec2=$(curl http://169.254.169.254/latest/meta-data/public-hostname)

# hadoop-env.sh configuration
sed -i -r "s|export JAVA_HOME|# export JAVA_HOME|g" /home/ubuntu/hadoop/etc/hadoop/hadoop-env.sh
line_nm=$(grep -n "export JAVA_HOME" /home/ubuntu/hadoop/etc/hadoop/hadoop-env.sh | cut -d: -f1)
sed -i "$(($line_nm+1)) i export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64" /home/ubuntu/hadoop/etc/hadoop/hadoop-env.sh

# core-site.xml configuration
echo -e "<configuration>\n\t<property>\n\t\t<name>fs.defaultFS</name>\n\t\t<value>hdfs://$ec2:9000</value>\n\t</property>\n</configuration>" > /home/ubuntu/hadoop/etc/hadoop/core-site.xml

# hdfs-site.xml configuration
echo -e "<configuration>\n\t<property>\n\t\t<name>dfs.replication</name>\n\t\t<value>2</value>\n\t</property>\n\t<property>\n\t\t<name>dfs.namenode.name.dir</name>\n\t\t<value>file:///usr/local/hadoop/hdfs/data</value>\n\t</property>\n</configuration>" > /home/ubuntu/hadoop/etc/hadoop/hdfs-site.xml

# mapred-site.xml configuration
echo -e "<configuration>\n\t<property>\n\t\t<name>mapreduce.framework.name</name>\n\t\t<value>yarn</value>\n\t</property>\n</configuration>" > /home/ubuntu/hadoop/etc/hadoop/mapred-site.xml

# yarn-site.xml configuration
echo -e "<configuration>\n\t<property>\n\t\t<name>yarn.nodemanager.aux-services</name>\n\t\t<value>mapred_shuffle</value>\n\t</property>\n\t<property>\n\t\t<name>yarn.resourcenamager.hostname</name>\n\t\t<value>$ec2</value>\n\t</property>\n</configuration>" > /home/ubuntu/hadoop/etc/hadoop/yarn-site.xml
