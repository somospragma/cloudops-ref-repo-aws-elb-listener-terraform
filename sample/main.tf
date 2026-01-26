############################################################################
# ELB Listener Module - Sample Implementation
############################################################################

module "elb_listeners" {
  source = "../"

  providers = {
    aws.project = aws.principal
  }

  client      = var.client
  project     = var.project
  environment = var.environment

  listener_config = local.listener_config_with_dynamic_values
}
