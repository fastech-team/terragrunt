variable "db_identifier" {
  description = "Identificador do banco de dados"
  type        = string
}

variable "db_name" {
  description = "Nome do banco de dados"
  type        = string
}

variable "engine" {
  description = "Engine do RDS"
  type        = string
  validation {
    condition     = contains(["mysql", "postgres", "mariadb", "oracle-se2", "sqlserver-se"], var.engine)
    error_message = "Engine deve ser: mysql, postgres, mariadb, oracle-se2 ou sqlserver-se."
  }
}

variable "engine_version" {
  description = "Versão do engine"
  type        = string
  default     = "14"
}

variable "instance_class" {
  description = "Classe da instância RDS"
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Armazenamento alocado em GB"
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "Armazenamento máximo para autoscaling"
  type        = number
  default     = 100
}

variable "username" {
  description = "Usuário mestre do banco"
  type        = string
  sensitive   = true
}

variable "password" {
  description = "Senha do usuário mestre"
  type        = string
  sensitive   = true
}

variable "db_subnet_group_name" {
  description = "Nome do DB Subnet Group"
  type        = string
  default     = ""
}

variable "vpc_security_group_ids" {
  description = "IDs dos security groups"
  type        = list(string)
  default     = []
}

variable "environment" {
  description = "Ambiente de deployment"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment deve ser: dev, staging ou prod."
  }
}

variable "multi_az" {
  description = "Habilitar Multi-AZ"
  type        = bool
  default     = false
}

variable "publicly_accessible" {
  description = "Banco acessível publicamente"
  type        = bool
  default     = false
}

variable "backup_retention_period" {
  description = "Dias de retenção de backups"
  type        = number
  default     = 7
}

variable "backup_window" {
  description = "Janela de backup"
  type        = string
  default     = "03:00-04:00"
}

variable "maintenance_window" {
  description = "Janela de manutenção"
  type        = string
  default     = "mon:04:00-mon:05:00"
}

variable "enable_cloudwatch_logs_exports" {
  description = "Habilitar logs no CloudWatch"
  type        = list(string)
  default     = []
}

variable "skip_final_snapshot" {
  description = "Pular snapshot final ao deletar"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags a serem aplicadas aos recursos"
  type        = map(string)
  default     = {}
}
