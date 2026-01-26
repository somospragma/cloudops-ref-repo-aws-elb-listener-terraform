############################################################################
# Data Sources
############################################################################

# Obtener información del Load Balancer existente
data "aws_lb" "existing" {
  provider = aws.principal
  name     = "dev-alb-public"  # Cambiar por el nombre de tu ALB
}

# Obtener información de la VPC
data "aws_vpc" "selected" {
  provider = aws.principal
  
  filter {
    name   = "tag:Name"
    values = ["pragma-mcp-dev-vpc"]  # Cambiar por el nombre de tu VPC
  }
}

# Obtener certificado ACM (si usas HTTPS)
# data "aws_acm_certificate" "api" {
#   provider = aws.principal
#   domain   = "api.example.com"
#   statuses = ["ISSUED"]
# }
