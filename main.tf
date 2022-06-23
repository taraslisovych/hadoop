provider "aws" {
  region = "us-west-1"
}

data "aws_ami" "amazon_ubuntu_2004" {
  owners      = ["099720109477"]
  most_recent = true
  filter {
    name   = "name"
    values = ["*ubuntu-focal-20.04-amd64-server-*"]
  }
}

variable "env" {
  default = "Hadoop"
}

module "my_vpc" {
  source                = "git::https://git@github.com/taraslisovych/terraform-modules.git//aws_network"
  private_network_count = 1
  public_network_count  = 1
  env                   = var.env
}

//+++++++ Hadoop Namenode ++++++++++++++++
resource "aws_instance" "hadoop_namenode" {
  ami                    = data.aws_ami.amazon_ubuntu_2004.id
  instance_type          = "t2.micro"
  subnet_id              = module.my_vpc.ter_public_net_ids[0]
  vpc_security_group_ids = [module.my_vpc.ter_def_sg]
  key_name               = module.my_vpc.ter_rsa_key_name
  //user_data              = templatefile("install_hadoop.sh.tpl", {})
  //  depends_on = [aws_efs_mount_target.target1]
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("${module.my_vpc.ter_rsa_key_name}.pem")
    #host = aws_instance.web.public_ip
    host = self.public_ip
  }

  # Hadoop basic installation
  provisioner "file" {
    source      = "install_hadoop.sh"
    destination = "/tmp/install_hadoop.sh"
  }

  provisioner "file" {
    source      = "${module.my_vpc.ter_rsa_key_name}.pem"
    destination = "/tmp/Hadoop_key.pem"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod 400 /tmp/Hadoop_key.pem",
      "chmod +x /tmp/install_hadoop.sh",
      "sed -i -e 's/\r$//' /tmp/install_hadoop.sh",
      "sudo /tmp/install_hadoop.sh > /tmp/install.log"
    ]
  }

  # Configure Hadoop on the Namenode
  provisioner "file" {
    source      = "configure_hadoop.sh"
    destination = "/tmp/configure_hadoop.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/configure_hadoop.sh",
      "sed -i -e 's/\r$//' /tmp/configure_hadoop.sh",
      "sudo /tmp/configure_hadoop.sh >> /tmp/install.log",
      "echo '${aws_instance.hadoop_namenode.public_dns}' > /home/ubuntu/hadoop/etc/hadoop/masters",
      "echo '${aws_instance.hadoop_sec_namenode.public_dns}' >> /home/ubuntu/hadoop/etc/hadoop/masters",
      "echo '${aws_instance.hadoop_datanode[0].public_dns}' > /home/ubuntu/hadoop/etc/hadoop/slaves",
      "echo '${aws_instance.hadoop_datanode[1].public_dns}' >> /home/ubuntu/hadoop/etc/hadoop/slaves",
    ]
  }

  # Configure SSH from Namenode to all other nodes in a Cluster
  provisioner "remote-exec" {
    inline = [
      "ssh-keyscan -H ${aws_instance.hadoop_sec_namenode.public_dns} >> ~/.ssh/known_hosts",
      "ssh-keyscan -H ${aws_instance.hadoop_datanode[0].public_dns} >> ~/.ssh/known_hosts",
      "ssh-keyscan -H ${aws_instance.hadoop_datanode[1].public_dns} >> ~/.ssh/known_hosts",
      "scp -i /tmp/Hadoop_key.pem /home/ubuntu/.ssh/id_rsa.pub ubuntu@${aws_instance.hadoop_sec_namenode.public_dns}:/tmp/id_rsa.pub",
      "ssh -i /tmp/Hadoop_key.pem ubuntu@${aws_instance.hadoop_sec_namenode.public_dns} 'cat /tmp/id_rsa.pub >> /home/ubuntu/.ssh/authorized_keys'",
      "scp -i /tmp/Hadoop_key.pem /home/ubuntu/.ssh/id_rsa.pub ubuntu@${aws_instance.hadoop_datanode[0].public_dns}:/tmp/id_rsa.pub",
      "ssh -i /tmp/Hadoop_key.pem ubuntu@${aws_instance.hadoop_datanode[0].public_dns} 'cat /tmp/id_rsa.pub >> /home/ubuntu/.ssh/authorized_keys'",
      "scp -i /tmp/Hadoop_key.pem /home/ubuntu/.ssh/id_rsa.pub ubuntu@${aws_instance.hadoop_datanode[1].public_dns}:/tmp/id_rsa.pub",
      "ssh -i /tmp/Hadoop_key.pem ubuntu@${aws_instance.hadoop_datanode[1].public_dns} 'cat /tmp/id_rsa.pub >> /home/ubuntu/.ssh/authorized_keys'",
    ]
  }

  # Send configuration file to all other nodes in a Cluster
  provisioner "remote-exec" {
    inline = [
      "scp /home/ubuntu/hadoop/etc/hadoop/hadoop-env.sh /home/ubuntu/hadoop/etc/hadoop/core-site.xml /home/ubuntu/hadoop/etc/hadoop/hdfs-site.xml /home/ubuntu/hadoop/etc/hadoop/mapred-site.xml /home/ubuntu/hadoop/etc/hadoop/yarn-site.xml ubuntu@${aws_instance.hadoop_sec_namenode.public_dns}:/home/ubuntu/hadoop/etc/hadoop",
      "scp /home/ubuntu/hadoop/etc/hadoop/hadoop-env.sh /home/ubuntu/hadoop/etc/hadoop/core-site.xml /home/ubuntu/hadoop/etc/hadoop/hdfs-site.xml /home/ubuntu/hadoop/etc/hadoop/mapred-site.xml /home/ubuntu/hadoop/etc/hadoop/yarn-site.xml ubuntu@${aws_instance.hadoop_datanode[0].public_dns}:/home/ubuntu/hadoop/etc/hadoop",
      "scp /home/ubuntu/hadoop/etc/hadoop/hadoop-env.sh /home/ubuntu/hadoop/etc/hadoop/core-site.xml /home/ubuntu/hadoop/etc/hadoop/hdfs-site.xml /home/ubuntu/hadoop/etc/hadoop/mapred-site.xml /home/ubuntu/hadoop/etc/hadoop/yarn-site.xml ubuntu@${aws_instance.hadoop_datanode[1].public_dns}:/home/ubuntu/hadoop/etc/hadoop",
      "scp /home/ubuntu/hadoop/etc/hadoop/masters ubuntu@${aws_instance.hadoop_sec_namenode.public_dns}:/home/ubuntu/hadoop/etc/hadoop",
      "scp /home/ubuntu/hadoop/etc/hadoop/slaves ubuntu@${aws_instance.hadoop_datanode[0].public_dns}:/home/ubuntu/hadoop/etc/hadoop",
      "scp /home/ubuntu/hadoop/etc/hadoop/slaves ubuntu@${aws_instance.hadoop_datanode[1].public_dns}:/home/ubuntu/hadoop/etc/hadoop",
    ]
  }

  tags = {
    "Name" = "${var.env} Namenode"
  }
}

//+++++++ Hadoop Secondary Namenode ++++++++++++++++
resource "aws_instance" "hadoop_sec_namenode" {
  ami                    = data.aws_ami.amazon_ubuntu_2004.id
  instance_type          = "t2.micro"
  subnet_id              = module.my_vpc.ter_public_net_ids[0]
  vpc_security_group_ids = [module.my_vpc.ter_def_sg]
  key_name               = module.my_vpc.ter_rsa_key_name
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("${module.my_vpc.ter_rsa_key_name}.pem")
    #host = aws_instance.web.public_ip
    host = self.public_ip
  }

  # Hadoop basic installation
  provisioner "file" {
    source      = "install_hadoop.sh"
    destination = "/tmp/install_hadoop.sh"
  }

  provisioner "file" {
    source      = "${module.my_vpc.ter_rsa_key_name}.pem"
    destination = "/tmp/Hadoop_key.pem"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod 400 /tmp/Hadoop_key.pem",
      "chmod +x /tmp/install_hadoop.sh",
      "sed -i -e 's/\r$//' /tmp/install_hadoop.sh",
      "sudo /tmp/install_hadoop.sh > /tmp/install.log"
    ]
  }

  tags = {
    "Name" = "${var.env} Secondary Namenode"
  }
}

//+++++++ Hadoop Data Namenodes ++++++++++++++++
resource "aws_instance" "hadoop_datanode" {
  count                  = 2
  ami                    = data.aws_ami.amazon_ubuntu_2004.id
  instance_type          = "t2.micro"
  subnet_id              = module.my_vpc.ter_public_net_ids[0]
  vpc_security_group_ids = [module.my_vpc.ter_def_sg]
  key_name               = module.my_vpc.ter_rsa_key_name
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("${module.my_vpc.ter_rsa_key_name}.pem")
    #host = aws_instance.web.public_ip
    host = self.public_ip
  }

  # Hadoop basic installation
  provisioner "file" {
    source      = "install_hadoop.sh"
    destination = "/tmp/install_hadoop.sh"
  }

  provisioner "file" {
    source      = "${module.my_vpc.ter_rsa_key_name}.pem"
    destination = "/tmp/Hadoop_key.pem"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod 400 /tmp/Hadoop_key.pem",
      "chmod +x /tmp/install_hadoop.sh",
      "sed -i -e 's/\r$//' /tmp/install_hadoop.sh",
      "sudo /tmp/install_hadoop.sh > /tmp/install.log"
    ]
  }

  tags = {
    "Name" = "${var.env} Datanode${count.index}"
  }
}
