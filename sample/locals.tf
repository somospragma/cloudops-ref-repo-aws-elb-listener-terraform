############################################################################
# Local Values
############################################################################

locals {
  # Configuración de listeners con valores dinámicos
  listener_config_with_dynamic_values = {
    for key, config in var.listener_config : key => merge(
      config,
      {
        # Inyectar el ARN del Load Balancer desde data source
        load_balancer_arn = data.aws_lb.existing.arn
        
        # Inyectar VPC ID en los target groups
        target_groups = [
          for tg in config.target_groups : merge(
            tg,
            {
              vpc_id = data.aws_vpc.selected.id
            }
          )
        ]
      }
    )
  }
}
