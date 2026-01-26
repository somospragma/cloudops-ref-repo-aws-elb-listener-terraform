# Sample - ELB Listener Module

Este directorio contiene un ejemplo funcional de cómo usar el módulo `cloudops-ref-repo-aws-elb-listener-terraform`.

## Descripción

Este ejemplo demuestra cómo crear:
- 3 Target Groups (api-default, api-payments, api-users)
- 1 Listener HTTP en puerto 80
- 2 Listener Rules para enrutamiento por path

## Requisitos Previos

1. **Load Balancer existente**: Debe existir un ALB llamado `dev-alb-public`
2. **VPC**: Debe existir una VPC con tag `Name = pragma-mcp-dev-vpc`
3. **Terraform**: >= 1.0
4. **AWS Provider**: >= 4.31.0

## Estructura de Archivos

```
sample/
├── README.md           # Este archivo
├── data.tf             # Data sources para obtener recursos existentes
├── locals.tf           # Transformaciones locales
├── main.tf             # Llamada al módulo
├── outputs.tf          # Outputs del ejemplo
├── providers.tf        # Configuración del provider
├── terraform.tfvars    # Valores de las variables
├── variables.tf        # Definición de variables
└── versions.tf         # Versiones requeridas
```

## Configuración

### 1. Actualizar Data Sources

Edita `data.tf` y actualiza:

```hcl
data "aws_lb" "existing" {
  name = "dev-alb-public"  # Cambiar por tu ALB
}

data "aws_vpc" "selected" {
  filter {
    name   = "tag:Name"
    values = ["pragma-mcp-dev-vpc"]  # Cambiar por tu VPC
  }
}
```

### 2. Actualizar Variables

Edita `terraform.tfvars` y ajusta los valores según tu entorno:

```hcl
region      = "us-east-1"
client      = "pragma"
project     = "mcp"
environment = "dev"
```

### 3. Revisar Configuración de Listeners

La configuración incluye:

**Target Groups:**
- `api-default`: Puerto 8080, health check en `/health`
- `api-payments`: Puerto 8081, health check en `/payments/health`
- `api-users`: Puerto 8082, health check en `/users/health`

**Listener:**
- Protocolo: HTTP
- Puerto: 80
- Target Group por defecto: api-default

**Rules:**
- Prioridad 100: `/payments/*` → api-payments
- Prioridad 200: `/users/*`, `/profile/*` → api-users

## Uso

### Inicializar Terraform

```bash
cd sample
terraform init
```

### Planificar Cambios

```bash
terraform plan
```

### Aplicar Configuración

```bash
terraform apply
```

### Ver Outputs

```bash
terraform output
```

## Outputs Esperados

```hcl
target_group_info = {
  "api-default" = {
    arn  = "arn:aws:elasticloadbalancing:..."
    name = "dev-target-api-default"
    id   = "arn:aws:elasticloadbalancing:..."
  }
  "api-payments" = {
    arn  = "arn:aws:elasticloadbalancing:..."
    name = "dev-target-api-payments"
    id   = "arn:aws:elasticloadbalancing:..."
  }
  "api-users" = {
    arn  = "arn:aws:elasticloadbalancing:..."
    name = "dev-target-api-users"
    id   = "arn:aws:elasticloadbalancing:..."
  }
}

listener_info = {
  "api-80" = {
    arn      = "arn:aws:elasticloadbalancing:..."
    port     = "80"
    protocol = "HTTP"
    id       = "arn:aws:elasticloadbalancing:..."
  }
}

listener_rule_info = {
  "api-payments-100" = {
    arn      = "arn:aws:elasticloadbalancing:..."
    priority = 100
    id       = "arn:aws:elasticloadbalancing:..."
  }
  "api-users-200" = {
    arn      = "arn:aws:elasticloadbalancing:..."
    priority = 200
    id       = "arn:aws:elasticloadbalancing:..."
  }
}
```

## Personalización

### Agregar HTTPS

Para usar HTTPS, descomenta el data source del certificado en `data.tf`:

```hcl
data "aws_acm_certificate" "api" {
  provider = aws.principal
  domain   = "api.example.com"
  statuses = ["ISSUED"]
}
```

Y actualiza el listener en `terraform.tfvars`:

```hcl
listeners = [
  {
    protocol                = "HTTPS"
    port                    = "443"
    certificate             = data.aws_acm_certificate.api.arn
    # ...
  }
]
```

### Agregar Más Servicios

Para agregar más servicios, agrega:

1. Un nuevo target group en `target_groups`
2. Una nueva rule en `rules` con prioridad única

### Cambiar Health Check

Ajusta los parámetros del health check en cada target group:

```hcl
{
  target_application_id = "api-custom"
  # ...
  healthy_threshold     = "5"      # Cambiar umbral
  interval              = "60"     # Cambiar intervalo
  path                  = "/custom/health"  # Cambiar path
  unhealthy_threshold   = "2"      # Cambiar umbral
  matcher               = "200-299"  # Cambiar códigos válidos
}
```

## Limpieza

Para eliminar todos los recursos creados:

```bash
terraform destroy
```

## Troubleshooting

### Error: Load Balancer not found

Verifica que el nombre del ALB en `data.tf` sea correcto:

```bash
aws elbv2 describe-load-balancers --query 'LoadBalancers[*].LoadBalancerName'
```

### Error: VPC not found

Verifica que el tag de la VPC sea correcto:

```bash
aws ec2 describe-vpcs --filters "Name=tag:Name,Values=pragma-mcp-dev-vpc"
```

### Error: Priority already in use

Cada regla debe tener una prioridad única. Verifica que no haya conflictos:

```bash
aws elbv2 describe-rules --listener-arn <listener-arn>
```

## Notas

- Este ejemplo usa HTTP para simplicidad. En producción, usa HTTPS.
- Los health checks están configurados con valores conservadores.
- Las prioridades de las reglas usan rangos de 100 para facilitar la inserción de nuevas reglas.
- Los target groups usan `target_type = "ip"` para compatibilidad con ECS/Fargate.

## Próximos Pasos

Después de desplegar este ejemplo:

1. Registra targets en los target groups
2. Verifica que los health checks pasen
3. Prueba el enrutamiento de tráfico
4. Configura auto-scaling si es necesario

## Soporte

Para consultas sobre este ejemplo, contactar al equipo de CloudOps de Pragma.
