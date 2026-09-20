variable "cluster_name" {
  description = "Nome do cluster ECS"
  type        = string
}

variable "enable_container_insights" {
  description = "Habilitar Container Insights: enabled, enhanced ou disabled"
  type        = string
  default     = "enabled"
}

variable "environment" {
  description = "Ambiente de deployment"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment deve ser: dev, staging ou prod."
  }
}

variable "capacity_providers" {
  description = "Capacity providers do ECS"
  type        = list(string)
  default     = ["FARGATE", "FARGATE_SPOT"]
}

variable "capacity_provider_strategy" {
  description = "Estratégia padrão de capacity provider"
  type = object({
    capacity_provider = optional(string)
    weight            = optional(number)
    base              = optional(number)
  })
  default = {}
}

variable "log_group_retention_days" {
  description = "Dias de retenção dos logs"
  type        = number
  default     = 7
}

variable "tags" {
  description = "Tags a serem aplicadas aos recursos"
  type        = map(string)
  default     = {}
}

variable "load_balancers" {
  description = "Configuração dos ALBs e suas regras de ingresso"

  type = map(object({
    internal           = bool
    load_balancer_type = string
    subnets            = list(string)

    ingress_rules = map(object({
      port         = number
      protocol     = string
      allowed_cidr = optional(string, "0.0.0.0/0")
    }))
  }))
  default = {}
}

variable "security_groups" {
  description = "Lista de security groups"
  type        = list(string)
  default     = []
}

variable "vpc_id" {
  description = "ID da VPC"
  type        = string
  default     = ""
}

variable "ingress_rules" {
  description = "Regras de ingresso para o ALB"
  type = map(object({
    port         = number
    protocol     = string
    allowed_cidr = optional(string, "0.0.0.0/0")
  }))
  default = {}
}

variable "domain" {
  description = "Domínio para o certificado ALB"
  type        = string
  default     = ""
}