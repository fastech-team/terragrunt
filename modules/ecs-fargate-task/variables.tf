variable "image_tag" {
  description = "Tag da imagem Docker no repositório (ECR) a ser utilizada na task definition"
  type        = string
  default     = ""
}

variable "health_path" {
  description = "Path utilizado pelo health check do load balancer/target group (ex: /health)"
  type        = string
  default     = ""
}

variable "cluster_name" {
  description = "Nome do cluster ECS onde o serviço será provisionado"
  type        = string
  default     = ""
}

variable "domain" {
  description = "Domínio associado ao serviço, utilizado nas regras de roteamento do load balancer"
  type        = string
  default     = ""
}

variable "registry" {
  description = "Nome (ou URL) do repositório ECR de onde a imagem do container será obtida"
  type        = string
  default     = ""
}

variable "load_balancer" {
  description = "ARN ou nome do load balancer (ALB) público utilizado pelo serviço"
  type        = string
  default     = ""
}

variable "internal_load_balancer" {
  description = "ARN ou nome do load balancer (ALB) interno utilizado pelo serviço"
  type        = string
  default     = ""
}

variable "task_variables" {
  description = "Mapa de variáveis de ambiente por task no formato esperado pelo ECS"
  type = map(list(object({
    name  = string
    value = string
  })))
  default   = {}
  sensitive = true
}

variable "task_secrets" {
  description = "Mapa de secrets por task no formato esperado pelo ECS"
  type = map(list(object({
    name      = string
    valueFrom = string
  })))
  default   = {}
  sensitive = true
}

variable "log_retention_days" {
  description = "Quantidade de dias de retenção do CloudWatch log groups"
  type        = number
  default     = 14
}

variable "vpc_id" {
  description = "ID da VPC onde o serviço será provisionado"
  type        = string
  default     = ""
}

variable "subnets_id" {
  description = "Lista de IDs das subnets utilizadas pelo serviço ECS"
  type        = list(string)
  default     = []
}

variable "environment" {
  description = "Nome do ambiente (ex: dev, staging, production) para o qual os recursos estão sendo provisionados"
  type        = string
  default     = ""
}

variable "aws_region" {
  description = "Região da AWS onde os recursos serão provisionados"
  type        = string
  default     = ""
}

variable "container_definitions" {
  description = "Mapa com as definições de cada container do serviço, incluindo porta, CPU, memória, contagem de tasks (desired/min/max) e alvos de auto scaling por CPU e memória"
  type = map(object({
    container_port     = optional(number, 8080)
    cpu                = optional(number, 256)
    memory             = optional(number, 512)
    desired_count      = optional(number, 1)
    min_tasks          = optional(number, 1)
    max_tasks          = optional(number, 2)
    cpu_target_scaling = optional(number, 70)
    mem_target_scaling = optional(number, 70)
    health_path        = optional(string, "helth")
    priority           = optional(number, 1)
    listener_rule      = optional(string, "443")
  }))
}

variable "account_id" {
  description = "ID da conta AWS onde os recursos serão provisionados"
  type        = string
  default     = ""
}