variable "cluster_name" {
  description = "Nome do cluster ECS"
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

variable "capacity_providers" {
  description = "Capacity providers do ECS"
  type        = list(string)
  default     = ["FARGATE", "FARGATE_SPOT"]
}

variable "default_capacity_provider_strategy" {
  description = "Estratégia padrão de capacity provider"
  type = list(object({
    capacity_provider = string
    weight            = optional(number, 100)
    base              = optional(number, 0)
  }))
  default = [
    {
      capacity_provider = "FARGATE"
      weight            = 100
      base              = 1
    }
  ]
}

variable "enable_container_insights" {
  description = "Habilitar Container Insights"
  type        = bool
  default     = false
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
