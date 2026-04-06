############################################################################
# Local Values - Nomenclatura y Transformaciones (PC-IAC-003, PC-IAC-012)
############################################################################

locals {
  # Prefijo de gobernanza (PC-IAC-003)
  governance_prefix = "${var.client}-${var.project}-${var.environment}"

  # Transformar los target groups para facilitar su referencia
  target_groups_map = {
    for key, config in var.listener_config :
    key => {
      for tg in config.target_groups : tg.target_application_id => {
        config_key   = key
        target_group = tg
      }
    }
  }

  # Aplanar los target groups para facilitar su uso con for_each
  flattened_target_groups = merge([
    for config_key, tg_map in local.target_groups_map : {
      for tg_key, tg in tg_map : tg_key => merge(tg, { config_key = config_key })
    }
  ]...)

  # Nombres de target groups (PC-IAC-003)
  target_group_names = {
    for key, tg in local.flattened_target_groups :
    key => "${local.governance_prefix}-tg-${key}"
  }

  # Transformar los listeners para facilitar su referencia
  listeners_map = {
    for key, config in var.listener_config :
    key => {
      for listener_idx, listener in config.listeners : "${config.application_id}-${listener.port}" => {
        config_key        = key
        listener          = listener
        application_id    = config.application_id
        load_balancer_arn = config.load_balancer_arn
      }
    }
  }

  # Aplanar los listeners para facilitar su uso con for_each
  flattened_listeners = merge([
    for config_key, listener_map in local.listeners_map : {
      for listener_key, listener in listener_map : listener_key => merge(listener, { config_key = config_key })
    }
  ]...)

  # Nombres de listeners (PC-IAC-003)
  listener_names = {
    for key, listener in local.flattened_listeners :
    key => "${local.governance_prefix}-listener-${key}"
  }

  # Transformar las reglas de listener para facilitar su referencia
  listener_rules = flatten([
    for config_key, config in var.listener_config : [
      for listener_idx, listener in config.listeners : [
        for rule_idx, rule in listener.rules : {
          key                   = "${rule.target_application_id}-${rule.priority}"
          config_key            = config_key
          listener_key          = "${config.application_id}-${listener.port}"
          rule                  = rule
          config_application_id = config.application_id
          listener_port         = listener.port
        }
      ]
    ]
  ])

  # Convertir las reglas a un mapa para usar con for_each
  listener_rules_map = {
    for rule in local.listener_rules : rule.key => rule
  }

  # Nombres de rules (PC-IAC-003)
  rule_names = {
    for key, rule in local.listener_rules_map :
    key => "${local.governance_prefix}-rule-${key}"
  }
}
