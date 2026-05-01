variable "bucket_name" {
  description = "Nome do bucket S3 (deve ser globalmente único)"
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

variable "versioning_enabled" {
  description = "Habilitar versionamento do bucket"
  type        = bool
  default     = true
}

variable "block_public_acls" {
  description = "Bloquear ACLs públicas"
  type        = bool
  default     = true
}

variable "block_public_policy" {
  description = "Bloquear política pública"
  type        = bool
  default     = true
}

variable "ignore_public_acls" {
  description = "Ignorar ACLs públicas"
  type        = bool
  default     = true
}

variable "restrict_public_buckets" {
  description = "Restringir buckets públicos"
  type        = bool
  default     = true
}

variable "enable_server_side_encryption" {
  description = "Habilitar criptografia no lado do servidor"
  type        = bool
  default     = true
}

variable "encryption_algorithm" {
  description = "Algoritmo de criptografia"
  type        = string
  default     = "AES256"
  validation {
    condition     = contains(["AES256", "aws:kms"], var.encryption_algorithm)
    error_message = "Deve ser AES256 ou aws:kms."
  }
}

variable "enable_logging" {
  description = "Habilitar logging de acesso"
  type        = bool
  default     = false
}

variable "lifecycle_rules" {
  description = "Regras de ciclo de vida"
  type = list(object({
    enabled = bool
    prefix  = string
    days    = number
    storage_class = optional(string, "GLACIER")
  }))
  default = []
}

variable "tags" {
  description = "Tags a serem aplicadas aos recursos"
  type        = map(string)
  default     = {}
}
