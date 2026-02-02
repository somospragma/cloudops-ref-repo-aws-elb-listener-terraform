# JWT Verification Example

## Basic JWT Verification

```hcl
module "api_listeners_jwt" {
  source = "git::https://github.com/somospragma/cloudops-ref-repo-aws-elb-listener-terraform.git?ref=v1.1.0"
  
  providers = {
    aws.project = aws.principal
  }

  client      = "pragma"
  project     = "api"
  environment = "pdn"
  
  listener_config = {
    "api-jwt-config" = {
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
              target_application_id = "api-protected"
              action = {
                type = "forward"
              }
              # JWT Verification Configuration
              jwt_validation = {
                issuer        = "https://auth.example.com"
                jwks_endpoint = "https://auth.example.com/.well-known/jwks.json"
                additional_claims = []
              }
              conditions = [
                {
                  host_headers = []
                  path_patterns = [
                    {
                      patterns = ["/api/protected/*"]
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

## JWT Verification with Additional Claims

```hcl
module "api_listeners_jwt_claims" {
  source = "git::https://github.com/somospragma/cloudops-ref-repo-aws-elb-listener-terraform.git?ref=v1.1.0"
  
  providers = {
    aws.project = aws.principal
  }

  client      = "pragma"
  project     = "api"
  environment = "pdn"
  
  listener_config = {
    "api-jwt-claims" = {
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
              target_application_id = "api-admin"
              action = {
                type = "forward"
              }
              # JWT Verification with Additional Claims
              jwt_validation = {
                issuer        = "https://auth.example.com"
                jwks_endpoint = "https://auth.example.com/.well-known/jwks.json"
                additional_claims = [
                  {
                    format = "string-array"
                    name   = "scope"
                    values = ["admin", "superuser"]
                  },
                  {
                    format = "single-string"
                    name   = "tenant_id"
                    values = ["pragma-001"]
                  },
                  {
                    format = "space-separated-values"
                    name   = "permissions"
                    values = ["read", "write", "delete"]
                  }
                ]
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
          target_application_id = "api-admin"
          port                  = "8082"
          protocol              = "HTTP"
          vpc_id                = data.aws_vpc.main.id
          target_type           = "ip"
          healthy_threshold     = "3"
          interval              = "30"
          path                  = "/health"
          unhealthy_threshold   = "3"
          matcher               = "200"
          additional_tags = {
            Service = "Admin"
            Protected = "true"
          }
        }
      ]
    }
  }
}
```

## Mixed Rules (With and Without JWT)

```hcl
module "api_listeners_mixed" {
  source = "git::https://github.com/somospragma/cloudops-ref-repo-aws-elb-listener-terraform.git?ref=v1.1.0"
  
  providers = {
    aws.project = aws.principal
  }

  client      = "pragma"
  project     = "api"
  environment = "pdn"
  
  listener_config = {
    "api-mixed" = {
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
            # Public endpoint - No JWT required
            {
              priority              = 100
              target_application_id = "api-public"
              action = {
                type = "forward"
              }
              conditions = [
                {
                  host_headers = []
                  path_patterns = [
                    {
                      patterns = ["/public/*", "/health"]
                    }
                  ]
                }
              ]
            },
            # Protected endpoint - JWT required
            {
              priority              = 200
              target_application_id = "api-protected"
              action = {
                type = "forward"
              }
              jwt_validation = {
                issuer        = "https://auth.example.com"
                jwks_endpoint = "https://auth.example.com/.well-known/jwks.json"
                additional_claims = []
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
          additional_tags = {
            Access = "Public"
          }
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
            Access = "Protected"
          }
        }
      ]
    }
  }
}
```

## JWT Claim Formats

### single-string
Validates that the claim matches exactly one value:
```hcl
{
  format = "single-string"
  name   = "tenant_id"
  values = ["pragma-001"]
}
```

### string-array
Validates that the claim (as an array) contains one of the specified values:
```hcl
{
  format = "string-array"
  name   = "roles"
  values = ["admin", "editor", "viewer"]
}
```

### space-separated-values
Validates that the claim (space-separated string) contains the specified values:
```hcl
{
  format = "space-separated-values"
  name   = "permissions"
  values = ["read", "write"]
}
```

## Important Notes

1. **HTTPS Only**: JWT verification only works with HTTPS listeners
2. **Mandatory Claims**: ALB automatically validates `iss` (issuer) and `exp` (expiration)
3. **Optional Claims**: ALB also validates `nbf` (not before) and `iat` (issued at) if present
4. **Algorithm**: Only RS256 algorithm is supported
5. **Max Claims**: Up to 10 additional claims can be validated
6. **JWKS Endpoint**: Must be publicly accessible HTTPS endpoint
7. **Action Order**: JWT validation (order=1) executes before forward action (order=2)
