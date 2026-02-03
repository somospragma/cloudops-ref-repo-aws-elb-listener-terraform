############################################################################
# Common Variables
############################################################################

variable "client" {
  type        = string
  description = "Identificador del cliente usado en la nomenclatura de recursos"

  validation {
    condition     = length(var.client) > 0 && length(var.client) <= 20
    error_message = "El client debe tener entre 1 y 20 caracteres."
  }
}

variable "project" {
  type        = string
  description = "Identificador del proyecto usado en la nomenclatura de recursos"

  validation {
    condition     = length(var.project) > 0 && length(var.project) <= 20
    error_message = "El project debe tener entre 1 y 20 caracteres."
  }
}

variable "environment" {
  type        = string
  description = "Entorno de despliegue (dev, qa, pdn) usado en la nomenclatura de recursos"

  validation {
    condition     = contains(["dev", "qa", "pdn"], lower(var.environment))
    error_message = "El entorno debe ser uno de: dev, qa, pdn (case insensitive)."
  }
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
        target_application_id = optional(string)
        action = object({
          type = string
        })
        fixed_response = optional(object({
          content_type = string
          message_body = optional(string)
          status_code  = string
        }))
        jwt_validation = optional(object({
          issuer        = string
          jwks_endpoint = string
          additional_claims = optional(list(object({
            format = string
            name   = string
            values = list(string)
          })), [])
        }))
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

  description = <<-EOF
    Map of Listener configurations including Target Groups, Listeners, and Listener Rules.
    Key is the configuration identifier.
    
    - load_balancer_arn: (string) ARN of the existing Load Balancer
    - application_id: (string) Application identifier for tagging
    - listeners: (list) List of listener configurations
      - protocol: (string) Protocol (HTTP, HTTPS, TCP, TLS)
      - port: (string) Listener port
      - certificate: (string) ARN of SSL/TLS certificate (required for HTTPS/TLS)
      - default_target_group_id: (string) ID of the default target group
      - additional_tags: (optional, map) Additional tags for the listener
      - rules: (list) List of listener rules
        - priority: (number) Rule priority (1-50000, lower = higher priority)
        - target_application_id: (string) Target group ID for this rule
        - action: (object) Action configuration
          - type: (string) Action type (forward)
        - conditions: (list) List of conditions
          - host_headers: (optional, list) Host header conditions
          - path_patterns: (optional, list) Path pattern conditions
    - target_groups: (list) List of target group configurations
      - target_application_id: (string) Unique target group identifier
      - port: (string) Target port
      - protocol: (string) Protocol (HTTP, HTTPS, TCP)
      - vpc_id: (string) VPC ID
      - target_type: (string) Target type (instance, ip, lambda)
      - healthy_threshold: (string) Healthy threshold (2-10)
      - interval: (string) Health check interval in seconds
      - path: (string) Health check path
      - unhealthy_threshold: (string) Unhealthy threshold (2-10)
      - matcher: (optional, string) HTTP codes for successful health checks
      - additional_tags: (optional, map) Additional tags for the target group
  EOF

  validation {
    condition     = length(var.listener_config) > 0
    error_message = "Debe proporcionar al menos una configuración de listener."
  }

  validation {
    condition = alltrue([
      for key, item in var.listener_config : alltrue([
        for listener in item.listeners : alltrue([
          for rule in listener.rules : alltrue([
            for condition in rule.conditions :
            length(condition.host_headers) > 0 || length(condition.path_patterns) > 0
          ])
        ])
      ])
    ])
    error_message = "Cada condición de regla debe tener al menos host_headers o path_patterns."
  }

  validation {
    condition = alltrue([
      for key, config in var.listener_config :
      length(config.listeners) > 0
    ])
    error_message = "Cada configuración debe tener al menos un listener."
  }

  validation {
    condition = alltrue([
      for key, config in var.listener_config :
      length(config.target_groups) > 0
    ])
    error_message = "Cada configuración debe tener al menos un target group."
  }

  validation {
    condition = alltrue([
      for key, config in var.listener_config : alltrue([
        for listener in config.listeners : alltrue([
          for rule in listener.rules :
          (rule.action.type == "forward" && rule.target_application_id != null) ||
          (rule.action.type == "fixed-response" && rule.fixed_response != null)
        ])
      ])
    ])
    error_message = "Las reglas con action.type='forward' requieren target_application_id. Las reglas con action.type='fixed-response' requieren fixed_response."
  }
}
