variable "instance_name" {
  description = "Nome da instância EC2"
  type        = string
}

variable "instance_type" {
  description = "Tipo de instância EC2"
  type        = string
  default     = "t3.micro"
}

variable "subnet_id" {
  description = "ID da subnet para lançar a instância"
  type        = string
}

variable "environment" {
  description = "Ambiente de deployment"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment deve ser: dev, staging ou prod."
  }
}

variable "tags" {
  description = "Tags a serem aplicadas aos recursos"
  type        = map(string)
  default     = {}
}

variable "associate_public_ip" {
  description = "Associar IP público à instância"
  type        = bool
  default     = false
}

variable "root_volume_size" {
  description = "Tamanho do volume raiz em GB"
  type        = number
  default     = 20
}

variable "root_volume_type" {
  description = "Tipo de volume raiz"
  type        = string
  default     = "gp3"
}

variable "vpc_security_group_ids" {
  description = "IDs dos security groups"
  type        = list(string)
  default     = []
}
