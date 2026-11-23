terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

data "aws_ssm_parameter" "ubuntu" {
  name = "/aws/service/canonical/ubuntu/server/24.04/stable/current/amd64/hvm/ebs-gp3/ami-id"
}

resource "aws_key_pair" "me" {
  key_name   = "${var.project}-key"
  public_key = file(pathexpand(var.public_key_path))
}

resource "aws_security_group" "sg" {
  name = "${var.project}-sg"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ip_cidr]
  }

  ingress {
    description = "Jenkins"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [var.ip_cidr]
  }

  ingress {
    description = "Grafana"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = [var.ip_cidr]
  }

  ingress {
    description = "Prometheus"
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = [var.ip_cidr]
  }

  ingress {
    description = "node_exporter"
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    self        = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

locals {
  base_setup = <<-EOT
    apt-get update
    apt-get install -y docker.io
    systemctl enable --now docker
    usermod -aG docker ubuntu
    docker run -d --name node-exporter --restart unless-stopped \
      --net host --pid host -v /:/host:ro,rslave \
      prom/node-exporter --path.rootfs=/host
  EOT
}

resource "aws_instance" "vm" {
  ami                    = data.aws_ssm_parameter.ubuntu.value
  instance_type          = "t3.micro"
  key_name               = aws_key_pair.me.key_name
  vpc_security_group_ids = [aws_security_group.sg.id]

  user_data = <<-EOF
    #!/bin/bash
    ${local.base_setup}
  EOF

  tags = { Name = "${var.project}-app" }
}

resource "aws_instance" "jenkins" {
  ami                    = data.aws_ssm_parameter.ubuntu.value
  instance_type          = "t3.small"
  key_name               = aws_key_pair.me.key_name
  vpc_security_group_ids = [aws_security_group.sg.id]

  user_data = <<-EOF
    #!/bin/bash
    ${local.base_setup}
    docker run -d --name jenkins --restart unless-stopped \
      -p 8080:8080 -p 50000:50000 \
      -v jenkins_home:/var/jenkins_home \
      jenkins/jenkins:lts-jdk17
  EOF

  tags = { Name = "${var.project}-jenkins" }
}

resource "aws_instance" "monitoring" {
  ami                    = data.aws_ssm_parameter.ubuntu.value
  instance_type          = "t3.small"
  key_name               = aws_key_pair.me.key_name
  vpc_security_group_ids = [aws_security_group.sg.id]

  user_data = <<-EOF
    #!/bin/bash
    ${local.base_setup}
    mkdir -p /opt/monitoring
    cat > /opt/monitoring/prometheus.yml <<'PROM'
    global:
      scrape_interval: 15s
    scrape_configs:
      - job_name: nodes
        static_configs:
          - targets:
              - "${aws_instance.app.private_ip}:9100"
              - "${aws_instance.jenkins.private_ip}:9100"
    PROM
    docker run -d --name prometheus --restart unless-stopped -p 9090:9090 \
      -v /opt/monitoring/prometheus.yml:/etc/prometheus/prometheus.yml \
      prom/prometheus
    docker run -d --name grafana --restart unless-stopped -p 3000:3000 grafana/grafana
  EOF

  tags = { Name = "${var.project}-monitoring" }
}


