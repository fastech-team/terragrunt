### Módulo EC2 Reutilizável (modules/ec2-instance/main.tf) ###

variable "instance_name" {
  description = "Nome da instância EC2"
  type        = string
}

variable "instance_type" {
  description = "Tipo da instância EC2"
  type        = string
  default     = "t3.medium"
}

variable "environment" {
  description = "Ambiente"
  type        = string
}

variable "tags" {
  description = "Tags para a instância"
  type        = map(string)
  default     = {}
}

variable "ami_id" {
  description = "AMI ID para a instância"
  type        = string
  default     = "ami-0c7217cdde317cfec" # Ubuntu 22.04 LTS (us-east-1)
}

# Data source para obter a AMI mais recente do Ubuntu
data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"] # Canonical
}

# Security group para a instância
resource "aws_security_group" "this" {
  name        = "${var.instance_name}-sg"
  description = "Security group para ${var.instance_name}"

  # SSH do meu IP (substitua pelo seu IP)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Em produção, restrinja ao seu IP
  }

  # HTTP para Metabase
  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.instance_name}-sg"
  })
}

# Chave SSH (opcional - você pode criar uma chave separada)
resource "aws_key_pair" "this" {
  key_name   = "${var.instance_name}-key"
  public_key = file("~/.ssh/id_rsa.pub") # Ajuste o caminho da sua chave pública
}

# Instância EC2
resource "aws_instance" "this" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.this.key_name
  vpc_security_group_ids = [aws_security_group.this.id]

  # User data para instalar Docker e Metabase
  user_data = <<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y apt-transport-https ca-certificates curl software-properties-common
    
    # Instalar Docker
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    apt-get update
    apt-get install -y docker-ce
    
    # Instalar Docker Compose
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    
    # Criar diretório para Metabase
    mkdir -p /opt/metabase
    cd /opt/metabase
    
    # Criar docker-compose.yml para Metabase
    cat > docker-compose.yml <<EOL
    version: '3'
    services:
      metabase:
        image: metabase/metabase:latest
        container_name: metabase
        ports:
          - "3000:3000"
        restart: always
        volumes:
          - metabase-data:/metabase-data
    volumes:
      metabase-data:
    EOL
    
    # Iniciar Metabase
    docker-compose up -d
  EOF

  tags = merge(var.tags, {
    Name = var.instance_name
    Type = "Metabase"
  })

  # Metadata options para segurança
  metadata_options {
    http_endpoint               = "enabled"
    http_put_response_hop_limit = 2
    http_tokens                 = "required"
  }
}

output "instance_id" {
  description = "ID da instância"
  value       = aws_instance.this.id
}

output "public_ip" {
  description = "IP público da instância"
  value       = aws_instance.this.public_ip
}

output "metabase_url" {
  description = "URL do Metabase"
  value       = "http://${aws_instance.this.public_ip}:3000"
}