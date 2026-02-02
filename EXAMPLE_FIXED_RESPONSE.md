# Fixed Response Examples

## Basic Fixed Response - Health Check Endpoint

```hcl
module "alb_health_check" {
  source = "git::https://github.com/somospragma/cloudops-ref-repo-aws-elb-listener-terraform.git?ref=v1.2.0"
  
  providers = {
    aws.project = aws.principal
  }

  client      = "pragma"
  project     = "api"
  environment = "pdn"
  
  listener_config = {
    "health-check" = {
      load_balancer_arn = data.aws_lb.api.arn
      application_id    = "api"
      
      listeners = [
        {
          protocol                = "HTTP"
          port                    = "80"
          certificate             = ""
          default_target_group_id = "api-default"
          additional_tags         = {}
          
          rules = [
            {
              priority = 100
              action = {
                type = "fixed-response"
              }
              fixed_response = {
                content_type = "text/plain"
                message_body = "HEALTHY"
                status_code  = "200"
              }
              conditions = [
                {
                  host_headers = []
                  path_patterns = [
                    {
                      patterns = ["/health", "/healthz"]
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
        }
      ]
    }
  }
}
```

## Maintenance Mode Page

```hcl
module "alb_maintenance" {
  source = "git::https://github.com/somospragma/cloudops-ref-repo-aws-elb-listener-terraform.git?ref=v1.2.0"
  
  providers = {
    aws.project = aws.principal
  }

  client      = "pragma"
  project     = "web"
  environment = "pdn"
  
  listener_config = {
    "maintenance" = {
      load_balancer_arn = data.aws_lb.web.arn
      application_id    = "web"
      
      listeners = [
        {
          protocol                = "HTTPS"
          port                    = "443"
          certificate             = data.aws_acm_certificate.web.arn
          default_target_group_id = "web-default"
          additional_tags         = {}
          
          rules = [
            {
              priority = 1
              action = {
                type = "fixed-response"
              }
              fixed_response = {
                content_type = "text/html"
                message_body = "<html><body><h1>Maintenance Mode</h1><p>We'll be back soon!</p></body></html>"
                status_code  = "503"
              }
              conditions = [
                {
                  host_headers = []
                  path_patterns = [
                    {
                      patterns = ["/*"]
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
          target_application_id = "web-default"
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
        }
      ]
    }
  }
}
```

## API Rate Limit Response

```hcl
module "alb_rate_limit" {
  source = "git::https://github.com/somospragma/cloudops-ref-repo-aws-elb-listener-terraform.git?ref=v1.2.0"
  
  providers = {
    aws.project = aws.principal
  }

  client      = "pragma"
  project     = "api"
  environment = "pdn"
  
  listener_config = {
    "rate-limit" = {
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
              priority = 50
              action = {
                type = "fixed-response"
              }
              fixed_response = {
                content_type = "application/json"
                message_body = "{\"error\":\"Too Many Requests\",\"message\":\"Rate limit exceeded\"}"
                status_code  = "429"
              }
              conditions = [
                {
                  host_headers = []
                  path_patterns = [
                    {
                      patterns = ["/api/limited/*"]
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
        }
      ]
    }
  }
}
```

## Mixed Rules - Forward and Fixed Response

```hcl
module "alb_mixed" {
  source = "git::https://github.com/somospragma/cloudops-ref-repo-aws-elb-listener-terraform.git?ref=v1.2.0"
  
  providers = {
    aws.project = aws.principal
  }

  client      = "pragma"
  project     = "api"
  environment = "pdn"
  
  listener_config = {
    "mixed" = {
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
            # Health check - Fixed response
            {
              priority = 10
              action = {
                type = "fixed-response"
              }
              fixed_response = {
                content_type = "text/plain"
                message_body = "OK"
                status_code  = "200"
              }
              conditions = [
                {
                  host_headers = []
                  path_patterns = [
                    {
                      patterns = ["/health"]
                    }
                  ]
                }
              ]
            },
            # API endpoint - Forward to target group
            {
              priority              = 100
              target_application_id = "api-service"
              action = {
                type = "forward"
              }
              conditions = [
                {
                  host_headers = []
                  path_patterns = [
                    {
                      patterns = ["/api/*"]
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
          target_application_id = "api-service"
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
            Service = "API"
          }
        }
      ]
    }
  }
}
```

## Custom Error Pages

```hcl
module "alb_error_pages" {
  source = "git::https://github.com/somospragma/cloudops-ref-repo-aws-elb-listener-terraform.git?ref=v1.2.0"
  
  providers = {
    aws.project = aws.principal
  }

  client      = "pragma"
  project     = "web"
  environment = "pdn"
  
  listener_config = {
    "error-pages" = {
      load_balancer_arn = data.aws_lb.web.arn
      application_id    = "web"
      
      listeners = [
        {
          protocol                = "HTTPS"
          port                    = "443"
          certificate             = data.aws_acm_certificate.web.arn
          default_target_group_id = "web-default"
          additional_tags         = {}
          
          rules = [
            # 404 Not Found
            {
              priority = 10
              action = {
                type = "fixed-response"
              }
              fixed_response = {
                content_type = "text/html"
                message_body = "<html><body><h1>404 - Not Found</h1></body></html>"
                status_code  = "404"
              }
              conditions = [
                {
                  host_headers = []
                  path_patterns = [
                    {
                      patterns = ["/404"]
                    }
                  ]
                }
              ]
            },
            # 403 Forbidden
            {
              priority = 20
              action = {
                type = "fixed-response"
              }
              fixed_response = {
                content_type = "text/html"
                message_body = "<html><body><h1>403 - Forbidden</h1></body></html>"
                status_code  = "403"
              }
              conditions = [
                {
                  host_headers = []
                  path_patterns = [
                    {
                      patterns = ["/admin/*"]
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
          target_application_id = "web-default"
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
        }
      ]
    }
  }
}
```

## Fixed Response Configuration

### Content Types
Valid content types for fixed responses:
- `text/plain`
- `text/css`
- `text/html`
- `application/javascript`
- `application/json`

### Status Codes
Valid status code patterns:
- `2XX` - Success responses (200-299)
- `4XX` - Client errors (400-499)
- `5XX` - Server errors (500-599)

Or specific codes like: `200`, `404`, `503`, etc.

### Message Body
- Optional field
- Can contain HTML, JSON, plain text, etc.
- Must match the specified content_type

## Use Cases

### 1. Health Check Endpoints
Return static health check responses without backend processing:
```hcl
fixed_response = {
  content_type = "text/plain"
  message_body = "HEALTHY"
  status_code  = "200"
}
```

### 2. Maintenance Mode
Display maintenance pages during deployments:
```hcl
fixed_response = {
  content_type = "text/html"
  message_body = "<html><body><h1>Under Maintenance</h1></body></html>"
  status_code  = "503"
}
```

### 3. API Responses
Return JSON responses for specific endpoints:
```hcl
fixed_response = {
  content_type = "application/json"
  message_body = "{\"status\":\"ok\",\"version\":\"1.0\"}"
  status_code  = "200"
}
```

### 4. Error Pages
Custom error pages without backend:
```hcl
fixed_response = {
  content_type = "text/html"
  message_body = "<html><body><h1>404 Not Found</h1></body></html>"
  status_code  = "404"
}
```

### 5. Rate Limiting
Return rate limit errors:
```hcl
fixed_response = {
  content_type = "application/json"
  message_body = "{\"error\":\"Rate limit exceeded\"}"
  status_code  = "429"
}
```

## Important Notes

1. **No Target Group Required**: Fixed response rules don't need a target_application_id
2. **Priority Matters**: Lower priority numbers execute first
3. **Content Type**: Must be one of the five supported types
4. **Message Body**: Optional but recommended for user-friendly responses
5. **Status Codes**: Can use specific codes or patterns (2XX, 4XX, 5XX)
6. **Performance**: Fixed responses are faster than forwarding to backends
7. **Cost Effective**: No backend processing or data transfer costs
