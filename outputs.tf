############################################################################
# Outputs
############################################################################

output "target_group_info" {
  description = "Información de los grupos de destino creados, organizados por application_id"
  value = {
    for key, target in aws_lb_target_group.lb_target_group : key => {
      arn  = target.arn
      name = target.name
      id   = target.id
    }
  }
}

output "listener_info" {
  description = "Información de los listeners creados"
  value = {
    for key, listener in aws_lb_listener.lb_listener : key => {
      arn      = listener.arn
      port     = listener.port
      protocol = listener.protocol
      id       = listener.id
    }
  }
}

output "listener_rule_info" {
  description = "Información de las reglas de listener creadas"
  value = {
    for key, rule in aws_lb_listener_rule.listener_rule : key => {
      arn      = rule.arn
      priority = rule.priority
      id       = rule.id
    }
  }
}

output "target_group_arns" {
  description = "Map de ARNs de target groups por application_id"
  value = {
    for key, target in aws_lb_target_group.lb_target_group : key => target.arn
  }
}

output "listener_arns" {
  description = "Map de ARNs de listeners por key"
  value = {
    for key, listener in aws_lb_listener.lb_listener : key => listener.arn
  }
}
