############################################################################
# AWS Load Balancer Listeners - Módulo de Referencia
# Este módulo crea Target Groups, Listeners y Listener Rules
# Requiere un Load Balancer existente (creado por cloudops-ref-repo-aws-elb-terraform)
############################################################################

############################################################################
# Target Groups
############################################################################
resource "aws_lb_target_group" "lb_target_group" {
  provider    = aws.project
  for_each    = local.flattened_target_groups
  name        = join("-", [var.environment, "target", each.key])
  port        = each.value.target_group.port
  protocol    = each.value.target_group.protocol
  vpc_id      = each.value.target_group.vpc_id
  target_type = each.value.target_group.target_type

  health_check {
    healthy_threshold   = each.value.target_group.healthy_threshold
    interval            = each.value.target_group.interval
    port                = each.value.target_group.port
    protocol            = each.value.target_group.protocol
    unhealthy_threshold = each.value.target_group.unhealthy_threshold
    matcher             = each.value.target_group.matcher
    path                = each.value.target_group.path
  }

  tags = merge(
    {
      Name           = join("-", [var.environment, "target", each.key])
      application_id = each.key
      client         = var.client
      project        = var.project
      environment    = var.environment
    },
    each.value.target_group.additional_tags
  )
}

############################################################################
# Listeners
############################################################################
resource "aws_lb_listener" "lb_listener" {
  # checkov:skip=CKV_AWS_2: Protocol is sent as variable and can be HTTP for internal services
  # checkov:skip=CKV_AWS_103: TLS 1.2 is enforced at ALB level, not listener level
  provider = aws.project
  for_each = local.flattened_listeners

  default_action {
    target_group_arn = aws_lb_target_group.lb_target_group[each.value.listener.default_target_group_id].arn
    type             = "forward"
  }

  certificate_arn   = each.value.listener.certificate != "" ? each.value.listener.certificate : null
  load_balancer_arn = each.value.load_balancer_arn
  port              = each.value.listener.port
  protocol          = each.value.listener.protocol

  tags = merge(
    {
      Name        = join("-", [var.environment, "listener", each.key])
      client      = var.client
      project     = var.project
      environment = var.environment
    },
    lookup(each.value.listener, "additional_tags", {})
  )
}

############################################################################
# Listener Rules
############################################################################
resource "aws_lb_listener_rule" "listener_rule" {
  provider     = aws.project
  for_each     = local.listener_rules_map
  listener_arn = aws_lb_listener.lb_listener[each.value.listener_key].arn
  priority     = each.value.rule.priority

  dynamic "action" {
    for_each = each.value.rule.jwt_validation != null ? [1] : []
    content {
      type  = "jwt-validation"
      order = 1

      jwt_validation {
        issuer        = each.value.rule.jwt_validation.issuer
        jwks_endpoint = each.value.rule.jwt_validation.jwks_endpoint

        dynamic "additional_claim" {
          for_each = each.value.rule.jwt_validation.additional_claims
          content {
            format = additional_claim.value.format
            name   = additional_claim.value.name
            values = additional_claim.value.values
          }
        }
      }
    }
  }

  action {
    type             = each.value.rule.action.type
    target_group_arn = aws_lb_target_group.lb_target_group[each.value.rule.target_application_id].arn
    order            = each.value.rule.jwt_validation != null ? 2 : 1
  }

  dynamic "condition" {
    for_each = each.value.rule.conditions
    content {
      dynamic "host_header" {
        for_each = condition.value.host_headers
        content {
          values = host_header.value.headers
        }
      }

      dynamic "path_pattern" {
        for_each = condition.value.path_patterns
        content {
          values = path_pattern.value.patterns
        }
      }
    }
  }

  tags = {
    Name        = join("-", [var.environment, "rule", each.key])
    client      = var.client
    project     = var.project
    environment = var.environment
  }
}
