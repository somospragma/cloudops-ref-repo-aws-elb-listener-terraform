# Terraform Module: cloudops-ref-repo-aws-elb-listener-terraform

## Descripción

Módulo de referencia para la creación de **Target Groups**, **Listeners** y **Listener Rules** para Application Load Balancers (ALB) y Network Load Balancers (NLB) en AWS.

**IMPORTANTE:** Este módulo requiere un Load Balancer previamente creado con el módulo `cloudops-ref-repo-aws-elb-terraform`.

## Estrategia de Separación de Responsabilidades

Este módulo forma parte de una arquitectura de separación de responsabilidades:

- **Módulo Transversal** (`cloudops-ref-repo-aws-elb-terraform`): Crea la infraestructura base compartida (Load Balancer)
- **Módulo Funcionalidad** (este módulo): Crea configuraciones específicas por servicio (Target Groups, Listeners, Rules)

### Beneficios de esta Separación

- ✅ Cada equipo gestiona sus propios servicios independientemente
- ✅ Cambios en un servicio no afectan otros servicios
- ✅ Ciclos de vida independientes por servicio
- ✅ Menor riesgo en despliegues
- ✅ Escalabilidad mejorada
- ✅ Facilita la gestión de microservicios

## Características

- ✅ Creación de Target Groups con health checks configurables
- ✅ Creación de Listeners (HTTP, HTTPS, TCP, TLS)
- ✅ Creación de Listener Rules con condiciones avanzadas
- ✅ **JWT Verification** para autenticación de tokens en ALB
- ✅ Enrutamiento por host headers
- ✅ Enrutamiento por path patterns
- ✅ Soporte para múltiples target groups
- ✅ Soporte para múltiples listeners
- ✅ Soporte para múltiples reglas por listener
- ✅ Nomenclatura estandarizada
- ✅ Sistema de etiquetado en 3 niveles
- ✅ Validaciones exhaustivas
- ✅ PC-IAC compliance

## Requisitos Técnicos

| Nombre | Versión |
|--------|---------|
| terraform | >= 1.0 |
| aws | >= 4.31.0 |

## Requisitos Previos

1. **Load Balancer existente**: Debe estar creado con `cloudops-ref-repo-aws-elb-terraform`
2. **ARN del Load Balancer**: Necesario para asociar los listeners
3. **VPC ID**: Necesario para crear los target groups
4. **Certificado SSL/TLS**: Necesario si usas listeners HTTPS/TLS

## Provider Configuration

```hcl
provider "aws" {
  region = "us-east-1"
  alias  = "project"
  
  default_tags {
    tags = {
      Environment = var.environment
      Project     = var.project
      Client      = var.client
      ManagedBy   = "terraform"
    }
  }
}

module "listeners" {
  source = "git::https://github.com/somospragma/cloudops-ref-repo-aws-elb-listener-terraform.git?ref=v1.0.0"
  
  providers = {
    aws.project = aws.project
  }
  
  # Resto de la configuración...
}
```

## Convenciones de Nomenclatura

### Target Groups
```
{environment}-target-{application_id}
```

Ejemplos:
- `dev-target-api-payments`: Target group para API de pagos en desarrollo
- `pdn-target-web-frontend`: Target group para frontend web en producción

### Listeners
```
{environment}-listener-{application_id}-{port}
```

Ejemplos:
- `dev-listener-api-443`: Listener HTTPS en puerto 443 para API en desarrollo
- `pdn-listener-web-80`: Listener HTTP en puerto 80 para web en producción

### Listener Rules
```
{environment}-rule-{target_application_id}-{priority}
```

## Uso del Módulo

### Ejemplo Básico - API con HTTPS

```hcl
module "api_listeners" {
  source = "git::https://github.com/somospragma/cloudops-ref-repo-aws-elb-listener-terraform.git?ref=v1.0.0"
  
  providers = {
    aws.project = aws.principal
  }

  client      = "pragma"
  project     = "api"
  environment = "dev"
  
  listener_config = {
    "api-config" = {
      load_balancer_arn = data.aws_lb.api.arn
      application_id    = "api"
      
      listeners = [
        {
          protocol                = "HTTPS"
          port                    = "443"
          certificate             = data.aws_acm_certificate.api.arn
          default_target_group_id = "api-default"
          additional_tags         = {}
          
          rules = [
            {
              priority              = 100
              target_application_id = "api-payments"
              action = {
                type = "forward"
              }
              conditions = [
                {
                  host_headers = []
                  path_patterns = [
                    {
                      patterns = ["/payments/*"]
                    }
                  ]
                }
              ]
            }
          ]
        }
      ]
      
      target_groups = [
        {
          target_application_id = "api-default"
          port                  = "8080"
          protocol              = "HTTP"
          vpc_id                = data.aws_vpc.main.id
          target_type           = "ip"
          healthy_threshold     = "3"
          interval              = "30"
          path                  = "/health"
          unhealthy_threshold   = "3"
          matcher               = "200"
          additional_tags       = {}
        },
        {
          target_application_id = "api-payments"
          port                  = "8081"
          protocol              = "HTTP"
          vpc_id                = data.aws_vpc.main.id
          target_type           = "ip"
          healthy_threshold     = "3"
          interval              = "30"
          path                  = "/payments/health"
          unhealthy_threshold   = "3"
          matcher               = "200"
          additional_tags = {
            Service = "Payments"
          }
        }
      ]
    }
  }
}
```

### Ejemplo - Múltiples Microservicios

```hcl
module "microservices_listeners" {
  source = "git::https://github.com/somospragma/cloudops-ref-repo-aws-elb-listener-terraform.git?ref=v1.0.0"
  
  providers = {
    aws.project = aws.principal
  }

  client      = "pragma"
  project     = "platform"
  environment = "pdn"
  
  listener_config = {
    "platform-services" = {
      load_balancer_arn = data.aws_lb.platform.arn
      application_id    = "platform"
      
      listeners = [
        {
          protocol                = "HTTPS"
          port                    = "443"
          certificate             = data.aws_acm_certificate.platform.arn
          default_target_group_id = "platform-default"
          additional_tags         = {}
          
          rules = [
            {
              priority              = 100
              target_application_id = "platform-auth"
              action = {
                type = "forward"
              }
              conditions = [
                {
                  host_headers = []
                  path_patterns = [
                    {
                      patterns = ["/auth/*", "/login", "/logout"]
                    }
                  ]
                }
              ]
            },
            {
              priority              = 200
              target_application_id = "platform-users"
              action = {
                type = "forward"
              }
              conditions = [
                {
                  host_headers = []
                  path_patterns = [
                    {
                      patterns = ["/users/*", "/profile/*"]
                    }
                  ]
                }
              ]
            }
          ]
        }
      ]
      
      target_groups = [
        {
          target_application_id = "platform-default"
          port                  = "8080"
          protocol              = "HTTP"
          vpc_id                = data.aws_vpc.main.id
          target_type           = "ip"
          healthy_threshold     = "3"
          interval              = "30"
          path                  = "/health"
          unhealthy_threshold   = "3"
          matcher               = "200"
          additional_tags       = {}
        },
        {
          target_application_id = "platform-auth"
          port                  = "8081"
          protocol              = "HTTP"
          vpc_id                = data.aws_vpc.main.id
          target_type           = "ip"
          healthy_threshold     = "3"
          interval              = "30"
          path                  = "/auth/health"
          unhealthy_threshold   = "3"
          matcher               = "200"
          additional_tags = {
            Service = "Authentication"
          }
        },
        {
          target_application_id = "platform-users"
          port                  = "8082"
          protocol              = "HTTP"
          vpc_id                = data.aws_vpc.main.id
          target_type           = "ip"
          healthy_threshold     = "3"
          interval              = "30"
          path                  = "/users/health"
          unhealthy_threshold   = "3"
          matcher               = "200"
          additional_tags = {
            Service = "Users"
          }
        }
      ]
    }
  }
}
```

### Ejemplo - JWT Verification para APIs Protegidas

```hcl
module "api_jwt_listeners" {
  source = "git::https://github.com/somospragma/cloudops-ref-repo-aws-elb-listener-terraform.git?ref=v1.1.0"
  
  providers = {
    aws.project = aws.principal
  }

  client      = "pragma"
  project     = "api"
  environment = "pdn"
  
  listener_config = {
    "api-jwt" = {
      load_balancer_arn = data.aws_lb.api.arn
      application_id    = "api"
      
      listeners = [
        {
          protocol                = "HTTPS"
          port                    = "443"
          certificate             = data.aws_acm_certificate.api.arn
          default_target_group_id = "api-public"
          additional_tags         = {}
          
          rules = [
            # Endpoint protegido con JWT
            {
              priority              = 100
              target_application_id = "api-protected"
              action = {
                type = "forward"
              }
              jwt_validation = {
                issuer        = "https://auth.pragma.com"
                jwks_endpoint = "https://auth.pragma.com/.well-known/jwks.json"
                additional_claims = [
                  {
                    format = "string-array"
                    name   = "scope"
                    values = ["api:read", "api:write"]
                  },
                  {
                    format = "single-string"
                    name   = "tenant_id"
                    values = ["pragma-001"]
                  }
                ]
              }
              conditions = [
                {
                  host_headers = []
                  path_patterns = [
                    {
                      patterns = ["/api/v1/*"]
                    }
                  ]
                }
              ]
            }
          ]
        }
      ]
      
      target_groups = [
        {
          target_application_id = "api-public"
          port                  = "8080"
          protocol              = "HTTP"
          vpc_id                = data.aws_vpc.main.id
          target_type           = "ip"
          healthy_threshold     = "3"
          interval              = "30"
          path                  = "/health"
          unhealthy_threshold   = "3"
          matcher               = "200"
          additional_tags       = {}
        },
        {
          target_application_id = "api-protected"
          port                  = "8081"
          protocol              = "HTTP"
          vpc_id                = data.aws_vpc.main.id
          target_type           = "ip"
          healthy_threshold     = "3"
          interval              = "30"
          path                  = "/health"
          unhealthy_threshold   = "3"
          matcher               = "200"
          additional_tags = {
            Protected = "true"
          }
        }
      ]
    }
  }
}
```

**Ver más ejemplos en:** [EXAMPLE_JWT.md](./EXAMPLE_JWT.md)

## Variables de Entrada

| Nombre | Descripción | Tipo | Requerido |
|--------|-------------|------|:---------:|
| client | Identificador del cliente | `string` | sí |
| project | Identificador del proyecto | `string` | sí |
| environment | Entorno (dev, qa, pdn) | `string` | sí |
| listener_config | Configuración de listeners y target groups | `map(object)` | sí |

### Estructura de listener_config

```hcl
map(object({
  load_balancer_arn = string  # ARN del Load Balancer existente
  application_id    = string  # ID de la aplicación
  
  listeners = list(object({
    protocol                = string  # HTTP, HTTPS, TCP, TLS
    port                    = string  # Puerto del listener
    certificate             = string  # ARN del certificado (HTTPS/TLS)
    default_target_group_id = string  # ID del target group por defecto
    additional_tags         = optional(map(string))
    
    rules = list(object({
      priority              = number  # Prioridad (1-50000)
      target_application_id = string  # ID del target group destino
      action = object({
        type = string  # "forward"
      })
      jwt_validation = optional(object({
        issuer        = string  # Issuer del JWT
        jwks_endpoint = string  # Endpoint JWKS público
        additional_claims = optional(list(object({
          format = string         # single-string, string-array, space-separated-values
          name   = string         # Nombre del claim
          values = list(string)   # Valores esperados
        })))
      }))
      conditions = list(object({
        host_headers = optional(list(object({
          headers = list(string)
        })))
        path_patterns = optional(list(object({
          patterns = list(string)
        })))
      }))
    }))
  }))

  target_groups = list(object({
    target_application_id = string  # ID único del target group
    port                  = string  # Puerto del target
    protocol              = string  # HTTP, HTTPS, TCP
    vpc_id                = string  # ID de la VPC
    target_type           = string  # instance, ip, lambda
    healthy_threshold     = string  # Checks exitosos (2-10)
    interval              = string  # Intervalo en segundos
    path                  = string  # Path para health check
    unhealthy_threshold   = string  # Checks fallidos (2-10)
    matcher               = optional(string)  # Códigos HTTP válidos
    additional_tags       = optional(map(string))
  }))
}))
```

## Outputs

| Nombre | Descripción |
|--------|-------------|
| target_group_info | Información completa de los target groups (ARN, nombre, ID) |
| listener_info | Información completa de los listeners (ARN, puerto, protocolo, ID) |
| listener_rule_info | Información completa de las reglas (ARN, prioridad, ID) |
| target_group_arns | Map de ARNs de target groups por application_id |
| listener_arns | Map de ARNs de listeners por key |

## Recursos Gestionados

| Nombre | Tipo |
|--------|------|
| aws_lb_target_group | resource |
| aws_lb_listener | resource |
| aws_lb_listener_rule | resource |

## Consideraciones Importantes

### Dependencia con Módulo ELB

1. **Primero**: Desplegar `cloudops-ref-repo-aws-elb-terraform` (crea el Load Balancer)
2. **Segundo**: Desplegar este módulo (crea TG, Listeners, Rules)

### Obtener ARN del Load Balancer

```hcl
data "aws_lb" "existing" {
  name = "dev-alb-public"
}

module "listeners" {
  source = "..."
  
  listener_config = {
    "config" = {
      load_balancer_arn = data.aws_lb.existing.arn
      # ...
    }
  }
}
```

### Gestión de Prioridades

- Menor número = mayor prioridad
- Cada regla debe tener prioridad única por listener
- Recomendación: Usar rangos por servicio (100-199, 200-299, etc.)

### Health Checks Recomendados

- **healthy_threshold**: 3
- **unhealthy_threshold**: 3
- **interval**: 30 segundos
- **path**: Endpoint específico de health check
- **matcher**: "200" o "200-299"

## PC-IAC Compliance

Este módulo cumple con las siguientes reglas PC-IAC:

- ✅ PC-IAC-001: Estructura de archivos obligatoria
- ✅ PC-IAC-002: Nomenclatura estandarizada
- ✅ PC-IAC-003: Variables con validaciones
- ✅ PC-IAC-004: Outputs documentados
- ✅ PC-IAC-005: Providers con alias
- ✅ PC-IAC-006: Versiones especificadas
- ✅ PC-IAC-007: README completo
- ✅ PC-IAC-009: CHANGELOG mantenido
- ✅ PC-IAC-010: .gitignore configurado
- ✅ PC-IAC-011: Locals para transformaciones
- ✅ PC-IAC-012: Data sources separados
- ✅ PC-IAC-020: Configuración map-based
- ✅ PC-IAC-023: Sistema de etiquetado
- ✅ PC-IAC-026: Directorio sample con ejemplo funcional

## Seguridad

- ✅ Health checks obligatorios
- ✅ Soporte para HTTPS/TLS
- ✅ Validaciones de condiciones
- ✅ Nomenclatura estandarizada
- ✅ Etiquetado consistente

## Limitaciones

- Requiere Load Balancer existente
- Las reglas solo aplican para ALB (no para NLB)
- Prioridades deben ser únicas por listener
- Condiciones requieren al menos host_headers o path_patterns

## Soporte

Para consultas o problemas con este módulo, contactar al equipo de CloudOps de Pragma.

---

**Versión:** 1.0.0  
**Última actualización:** 2026-01-26  
**Mantenido por:** Pragma CloudOps Team
