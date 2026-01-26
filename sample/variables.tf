############################################################################
# Common Variables
############################################################################

variable "region" {
  type        = string
  description = "AWS region donde se desplegarán los recursos"
  default     = "us-east-1"
}

variable "client" {
  type        = string
  description = "Identificador del cliente"
}

variable "project" {
  type        = string
  description = "Identificador del proyecto"
}

variable "environment" {
  type        = string
  description = "Entorno de despliegue (dev, qa, pdn)"
}

variable "common_tags" {
  type        = map(string)
  description = "Tags comunes para todos los recursos"
  default     = {}
}

############################################################################
# Listener Configuration
############################################################################

variable "listener_config" {
  type = map(object({
    load_balancer_arn = string
    application_id    = string

    listeners = list(object({
      protocol                = string
      port                    = string
      certificate             = string
      default_target_group_id = string
      additional_tags         = optional(map(string), {})

      rules = list(object({
        priority              = number
        target_application_id = string
        action = object({
          type = string
        })
        conditions = list(object({
          host_headers = optional(list(object({
            headers = list(string)
          })), [])
          path_patterns = optional(list(object({
            patterns = list(string)
          })), [])
        }))
      }))
    }))

    target_groups = list(object({
      target_application_id = string
      port                  = string
      protocol              = string
      vpc_id                = string
      target_type           = string
      healthy_threshold     = string
      interval              = string
      path                  = string
      unhealthy_threshold   = string
      matcher               = optional(string, "200")
      additional_tags       = optional(map(string), {})
    }))
  }))
  description = "Configuración de listeners, target groups y rules"
}
