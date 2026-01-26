############################################################################
# Local Values - Transformaciones para Target Groups, Listeners y Rules
############################################################################

locals {
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
}
