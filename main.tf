resource "aws_key_pair" "Swamy" {
  key_name   = "Swamy"
  # you can paste the public key directly like this
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDZBLPI46+8kIFDPuE3UbvcWwKA6GIu0n8d8E1nsmDFKjxwWyF9P9I+dCz3QgmCT7+1PgdTVOqiEVwyhJ9kBFJ+fwmWPQw3VbzErqr7sEXvfgriG7kIwEj8+44lfOzTDL1bRUKG+Pe5Xd+mJF6pcBNtZmlx1x1ksYe7s1NtZbh+qxvTBk5WA7IPkHDmvc5pdNKx16SYiw1D62eH6fZa2jVrmNKcyT6+1grqBLL+bHyjYvafBPjVJ1EROhatWqhjxbdDoYb7z26ZkrmQys1zud2hbCSs9iflbNF4BvxD/L98Qmua18g6dHJfayk0p5hoOOHfLiyFsKPTPbTgW+zen6mRDQ1NJqBGoIll58GT2gyoXVgZ+HsP9Dw5deesdJ+0/hfYe/NxevAIR+H9CC+XFuwcpM0wZVRWEV3y6LWS4hZhI7AQrqVonZYeFdaPBdnXLdgwGl2+LH6lg08z+yKItOMQ2AjVVxpgMX/DNMPS5KXMj/hWvmHgtEInXrsBthk/iTDiMpHeT8Yv184Q9qf8yGpPipXLTA3mazYnVtZIrMhb3ISihDmblZF8+aZpibRp1N48Wo7+SPdoZJ+S2PYW2GVAhgdoIwzTYxARGh49PkYh4SLFJbVp9mQmWkKMil4CQQFfF9KSlM5mrEcZSDJuSQpA7TLMDQQ0uboxkSqMYjUlsQ== SAMSUNG@Swamy"
  #public_key = file("~/.ssh/tools.pub")
  # ~ means windows home directory
}

module "jenkins" {
  source  = "terraform-aws-modules/ec2-instance/aws"

  name = "jenkins-tf"

  instance_type          = "t3.small"
  vpc_security_group_ids = ["sg-03931b1bad72d1a95"] #replace your SG
  subnet_id = "subnet-02785d205e5166b95" #replace your Subnet
  ami = data.aws_ami.ami_info.id
  key_name = aws_key_pair.Swamy.key_name
  user_data = file("jenkins.sh")
  tags = {
    Name = "jenkins-tf"
  }
}

module "jenkins_agent" {
  source  = "terraform-aws-modules/ec2-instance/aws"

  name = "jenkins-agent"

  instance_type          = "t3.small"
  vpc_security_group_ids = ["sg-03931b1bad72d1a95"]
  # convert StringList to list and get first element
  subnet_id = "subnet-06019b3c21801bd27"
  ami = data.aws_ami.ami_info.id
  key_name = aws_key_pair.Swamy.key_name
  user_data = file("jenkins-agent.sh")
  tags = {
    Name = "jenkins-agent"
  }
}



module "nexus" {
  source  = "terraform-aws-modules/ec2-instance/aws"

  name = "nexus"

  instance_type          = "t3.medium"
  vpc_security_group_ids = ["sg-03931b1bad72d1a95"]
  # convert StringList to list and get first element
  subnet_id = "subnet-02785d205e5166b95"
  ami = data.aws_ami.nexus_ami_info.id
  key_name = aws_key_pair.Swamy.key_name
  root_block_device = [
    {
      volume_type = "gp3"
      volume_size = 30
    }
  ]
  tags = {
    Name = "nexus"
  }
}

module "records" {
  source  = "terraform-aws-modules/route53/aws//modules/records"
  version = "~> 2.0"

  zone_name = var.zone_name

  records = [
    {
      name    = "jenkins"
      type    = "A"
      ttl     = 1
      records = [
        module.jenkins.public_ip
      ]
      allow_overwrite = true
    },
    {
      name    = "jenkins-agent"
      type    = "A"
      ttl     = 1
      records = [
        module.jenkins_agent.private_ip
      ]
      allow_overwrite = true
    },
    {
      name    = "nexus"
      type    = "A"
      ttl     = 1
      allow_overwrite = true
      records = [
        module.nexus.public_ip
      ]
      allow_overwrite = true
    }
  ]
  
}

resource "aws_security_group_rule" "allow_jenkins_8080" {
  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  cidr_blocks              = ["0.0.0.0/0"] # Or restrict to your office/VPN IP
  security_group_id        = "sg-03931b1bad72d1a95"
  description              = "Allow access to Jenkins UI on port 8080"
}

resource "aws_security_group_rule" "allow_nexus_8081" {
  type                     = "ingress"
  from_port                = 8081
  to_port                  = 8081
  protocol                 = "tcp"
  cidr_blocks              = ["0.0.0.0/0"] # Or restrict as needed
  security_group_id        = "sg-03931b1bad72d1a95"
  description              = "Allow access to Nexus UI on port 8081"
}

resource "aws_security_group_rule" "allow_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"] # Or restrict to your IP for better security
  security_group_id = "sg-03931b1bad72d1a95"
  description       = "Allow SSH access"
}
