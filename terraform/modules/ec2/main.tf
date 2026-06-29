# ── SSH Keys ─────────────────────────────────────────────────────────────────

# pyforum-main: operator access key pair
resource "tls_private_key" "pyforum_main" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "pyforum_main" {
  key_name   = "pyforum-main"
  public_key = tls_private_key.pyforum_main.public_key_openssh

  tags = {
    Name = "pyforum-main"
  }
}

resource "local_file" "pyforum_main_pem" {
  content         = tls_private_key.pyforum_main.private_key_pem
  filename        = pathexpand("~/.ssh/pyforum-main.pem")
  file_permission = "0600"
}

# pyforum-jenkins-deploy: Jenkins CI/CD deploy key pair
resource "tls_private_key" "jenkins_deploy" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# ── AMI: Amazon Linux 2023 ────────────────────────────────────────────────────
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# ── App EC2 Instance ──────────────────────────────────────────────────────────
resource "aws_instance" "app" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = "t3.small"
  subnet_id              = var.public_subnet_id
  vpc_security_group_ids = [var.sg_app_id]
  key_name               = aws_key_pair.pyforum_main.key_name
  iam_instance_profile   = var.app_instance_profile_name

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 20
    delete_on_termination = true
    encrypted             = true
  }

  user_data = templatefile("${path.module}/templates/app_userdata.sh.tpl", {
    jenkins_deploy_pubkey = tls_private_key.jenkins_deploy.public_key_openssh
    rds_endpoint          = var.rds_endpoint
    aws_region            = var.aws_region
  })

  tags = {
    Name = "${var.project_name}-app-ec2"
  }

  lifecycle {
    ignore_changes = [ami, user_data]
  }
}

resource "aws_eip" "app" {
  domain   = "vpc"
  instance = aws_instance.app.id

  tags = {
    Name = "${var.project_name}-app-eip"
  }
}

# ── Jenkins EC2 Instance ──────────────────────────────────────────────────────
resource "aws_instance" "jenkins" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = "t3.small"
  subnet_id              = var.public_subnet_id
  vpc_security_group_ids = [var.sg_jenkins_id]
  key_name               = aws_key_pair.pyforum_main.key_name
  iam_instance_profile   = var.jenkins_instance_profile_name

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 30
    delete_on_termination = true
    encrypted             = true
  }

  user_data = templatefile("${path.module}/templates/jenkins_userdata.sh.tpl", {
    jenkins_deploy_privkey = tls_private_key.jenkins_deploy.private_key_pem
    jenkins_deploy_pubkey  = tls_private_key.jenkins_deploy.public_key_openssh
  })

  tags = {
    Name = "${var.project_name}-jenkins-ec2"
  }

  lifecycle {
    ignore_changes = [ami, user_data]
  }
}

resource "aws_eip" "jenkins" {
  domain   = "vpc"
  instance = aws_instance.jenkins.id

  tags = {
    Name = "${var.project_name}-jenkins-eip"
  }
}
