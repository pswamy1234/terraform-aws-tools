data "aws_vpc" "default" {
  default = true
}
resource "aws_security_group" "jenkins_sg" {
  name        = "jenkins_sg"
  description = "Allow Jenkins and SSH access"
  vpc_id      = data.aws_vpc.default.id  # Dynamically fetch the VPC ID

  # Allow Jenkins (8080) access
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow SSH (port 22) access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Replace with your IP for security
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}



module "jenkins" {
  source  = "terraform-aws-modules/ec2-instance/aws"

  name = "jenkins-tf"

  instance_type          = "t3.small"
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id] # Updated reference
  subnet_id              = "subnet-0e7377711054f1fd6" # Replace your Subnet
  ami                   = data.aws_ami.ami_info.id
  user_data             = file("jenkins.sh")
  tags = {
    Name = "jenkins-tf"
  }
}

module "jenkins_agent" {
  source  = "terraform-aws-modules/ec2-instance/aws"

  name = "jenkins-agent"

  instance_type          = "t3.small"
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id] # Updated reference
  subnet_id              = "subnet-0e7377711054f1fd6"
  ami                   = data.aws_ami.ami_info.id
  user_data             = file("jenkins-agent.sh")
  tags = {
    Name = "jenkins-agent"
  }
}

module "nexus" {
  source  = "terraform-aws-modules/ec2-instance/aws"

  name = "nexus"

  instance_type          = "t3.small"
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id] # Updated reference
  subnet_id              = "subnet-0e7377711054f1fd6"
  ami                   = data.aws_ami.ami_info.id
  tags = {
    Name = "nexus"
  }
}

resource "aws_key_pair" "tools" {
  key_name   = "tools"
  public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJJx/tR9Iby5e+4dJT0aEtrse0Jou4uziDf0Zw2pTjxR puttiswamy123@gmail.com"
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
      records = [
        module.nexus.private_ip
      ]
      allow_overwrite = true
    }
  ]
}
