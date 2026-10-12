## VARIABLES ##
variable "additional_origins" {
  description = "Custom origins adicionais; omita para manter apenas a origin S3"
  type = list(object({
    origin_id                = string
    domain_name              = string
    origin_path              = optional(string, "")
    connection_attempts      = optional(number, 3)
    connection_timeout       = optional(number, 10)
    origin_read_timeout      = optional(number, 30)
    origin_keepalive_timeout = optional(number, 5)
  }))
  default = []

  validation {
    condition     = length(distinct(var.additional_origins[*].origin_id)) == length(var.additional_origins)
    error_message = "Cada origin adicional deve ter um origin_id exclusivo."
  }
}

variable "additional_behaviors" {
  description = "Behaviors adicionais em ordem de prioridade, antes de *.html e do behavior padrao"
  type = list(object({
    path_pattern               = string
    target_origin_id           = string
    allowed_methods            = optional(list(string), ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"])
    cached_methods             = optional(list(string), ["GET", "HEAD"])
    cache_policy_name          = optional(string, "Managed-CachingDisabled")
    origin_request_policy_name = optional(string, "Managed-AllViewerExceptHostHeader")
  }))
  default = []

  validation {
    condition = (
      length(distinct(var.additional_behaviors[*].path_pattern)) == length(var.additional_behaviors) &&
      alltrue([for behavior in var.additional_behaviors : !contains(["*", "*.html"], behavior.path_pattern)])
    )
    error_message = "Os caminhos devem ser exclusivos; * e *.html estao reservados para o frontend S3."
  }
}

variable "site_name" {
  description = "Nome do projeto para o CloudFront"
  type        = string
}

variable "aws_acm_certificate" {
  description = "Usa certificado ACM emitido para *.domain em us-east-1 e habilita o domínio personalizado; false usa apenas o domínio padrão do CloudFront"
  type        = bool
  default     = false
}

variable "domain" {
  description = "Domínio para o CloudFront"
  type        = string
}

variable "cname" {
  description = "CNAME para o CloudFront"
  type        = string
}

variable "enable_waf" {
  description = "Habilita WAF para o CloudFront"
  type        = bool
  default     = false
}

variable "environment" {
  description = "Ambiente de deployment"
  type        = string
  validation {
    condition     = contains(["dev", "stage", "prod", "prod-dr"], var.environment)
    error_message = "Environment deve ser: dev, stage, prod ou prod-dr."
  }
}

variable "region" {
  description = "AWS region for the CloudFront distribution"
  type        = string
}