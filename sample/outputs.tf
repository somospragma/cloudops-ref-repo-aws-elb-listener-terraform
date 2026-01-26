############################################################################
# Outputs
############################################################################

output "target_group_info" {
  description = "Información de los target groups creados"
  value       = module.elb_listeners.target_group_info
}

output "listener_info" {
  description = "Información de los listeners creados"
  value       = module.elb_listeners.listener_info
}

output "listener_rule_info" {
  description = "Información de las reglas de listener creadas"
  value       = module.elb_listeners.listener_rule_info
}

output "target_group_arns" {
  description = "ARNs de los target groups"
  value       = module.elb_listeners.target_group_arns
}

output "listener_arns" {
  description = "ARNs de los listeners"
  value       = module.elb_listeners.listener_arns
}
