# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.5] - 2026-06-22

### Added
- Target registration support via `targets` field in `target_groups`
- New `aws_lb_target_group_attachment` resource to register EC2 instances, IPs or Lambda ARNs
- `targets` is optional (empty list by default) — backward compatible with all existing configurations
- Supports all target types: `instance` (EC2 ID), `ip` (IP address), `lambda` (Lambda ARN)
- Optional `port` override per target

### Notes
- ECS services self-register and do not need this field
- EC2 instances require explicit target registration via this field
- Lambda targets also require explicit registration



### Added
- Cognito Authentication support for Application Load Balancer listener rules
- Optional `authenticate_cognito` configuration block in listener rules
- Support for user_pool_arn, user_pool_client_id, user_pool_domain configuration
- Support for session_timeout, scope, and on_unauthenticated_request options
- New action type `authenticate-cognito-forward` for combined auth + forward
- Automatic redirect to Cognito login for unauthenticated users

### Features
- ✅ ALB-managed Cognito authentication (no app changes required)
- ✅ Automatic redirect to Cognito Hosted UI
- ✅ Session management via ALB cookies
- ✅ Configurable session timeout (default: 7 days)
- ✅ Configurable OAuth scopes
- ✅ Backward compatible (authenticate_cognito is optional)

### Requirements
- HTTPS listener required for Cognito authentication
- Cognito User Pool with configured App Client
- Callback URL configured in Cognito: `https://<domain>/oauth2/idpresponse`

## [1.0.3] - 2026-04-13

### Changed
- Added support for `prod` environment in variable validation
- Environment validation now accepts: dev, qa, pdn, prod

## [1.0.2] - 2026-04-06

### Added
- Stickiness support for Target Groups (lb_cookie and app_cookie)
- Optional `stickiness` configuration block in target groups

### Changed
- **BREAKING**: Target Group naming now follows PC-IAC-003 convention: `{client}-{project}-{environment}-tg-{key}` (previously `{environment}-target-{key}`)
- **BREAKING**: Listener naming now follows PC-IAC-003: `{client}-{project}-{environment}-listener-{key}`
- **BREAKING**: Rule naming now follows PC-IAC-003: `{client}-{project}-{environment}-rule-{key}`
- Naming construction centralized in `locals.tf` per PC-IAC-003
- Tags cleaned per PC-IAC-004: removed hardcoded `client`, `project`, `environment` from resource tags (now come from provider `default_tags`)
- Tags now only contain `Name` + `additional_tags` per PC-IAC-004
- Removed non-standard documentation files (JWT_IMPLEMENTATION.md, EXAMPLE_JWT.md, FIXED_RESPONSE_IMPLEMENTATION.md, EXAMPLE_FIXED_RESPONSE.md) per PC-IAC-001
- Renamed `sample/terraform.tfvars.example` to `sample/terraform.tfvars` per PC-IAC-001

### Migration Guide
- Existing target groups will be recreated due to name change
- Tags `client`, `project`, `environment` must come from provider `default_tags`
- Stickiness is optional (null by default), no impact on existing configs

## [1.2.0] - 2026-02-02

### Added
- Fixed Response action support for listener rules
- Optional `fixed_response` configuration block in listener rules
- Support for static HTTP responses without backend targets
- Five content types: text/plain, text/css, text/html, application/javascript, application/json
- Flexible status codes: specific (200, 404, 503) or patterns (2XX, 4XX, 5XX)
- Optional message body for custom response content
- Comprehensive fixed response examples in EXAMPLE_FIXED_RESPONSE.md
- Fixed response documentation in README

### Changed
- Made `target_application_id` optional in listener rules (required only for forward actions)
- Updated `main.tf` to support conditional action types (forward vs fixed-response)
- Enhanced validation to ensure correct configuration per action type
- Updated listener_config structure documentation

### Features
- ✅ Static responses without backend processing
- ✅ Health check endpoints without target groups
- ✅ Maintenance mode pages
- ✅ Custom error pages (404, 503, etc.)
- ✅ API responses (JSON, plain text)
- ✅ Cost-effective (no backend data transfer)
- ✅ Backward compatible (existing forward actions unchanged)

### Requirements
- Terraform >= 1.0
- AWS Provider >= 4.31.0
- Valid content type from supported list
- Valid status code (specific or pattern)

### Notes
- Fixed response rules don't require target groups
- Message body is optional but recommended for user-friendly responses
- Fixed responses are faster and more cost-effective than forwarding
- Can be mixed with forward and JWT validation actions in same listener

## [1.1.0] - 2026-02-02

### Added
- JWT Verification support for Application Load Balancer listener rules
- Optional `jwt_validation` configuration block in listener rules
- Support for JWT issuer and JWKS endpoint configuration
- Support for additional JWT claims validation (up to 10 claims)
- Three claim formats: single-string, string-array, space-separated-values
- Action ordering support (JWT validation executes before forward action)
- Comprehensive JWT examples in EXAMPLE_JWT.md
- JWT verification documentation in README

### Changed
- Updated `variables.tf` to include optional `jwt_validation` object in rules
- Updated `main.tf` to support dynamic JWT validation action with proper ordering
- Enhanced README with JWT verification example and documentation
- Updated listener_config structure documentation

### Features
- ✅ JWT token signature validation at ALB level
- ✅ Automatic validation of mandatory claims (iss, exp)
- ✅ Optional validation of nbf and iat claims
- ✅ Custom additional claims validation
- ✅ Pre-routing authentication for secure APIs
- ✅ Backward compatible (JWT validation is optional)

### Requirements
- Terraform >= 1.0
- AWS Provider >= 4.31.0
- HTTPS listener required for JWT verification
- Publicly accessible JWKS endpoint

### Notes
- JWT verification only works with HTTPS listeners
- Only RS256 algorithm is supported by AWS ALB
- JWT validation action executes before forward action (order: 1 vs 2)
- Existing configurations without JWT validation continue to work unchanged

## [1.0.0] - 2026-01-26

### Added
- Initial release of ELB Listener module
- Support for Target Groups creation with health checks
- Support for Listeners (HTTP, HTTPS, TCP, TLS)
- Support for Listener Rules with conditions
- Host header routing support
- Path pattern routing support
- PC-IAC compliance implementation (14 rules)
- Comprehensive variable validations
- Complete documentation and examples
- Sample directory with working example
- Standardized nomenclature for all resources
- Three-level tagging system
- Support for multiple target groups per configuration
- Support for multiple listeners per configuration
- Support for multiple rules per listener

### Features
- ✅ Creates Target Groups with configurable health checks
- ✅ Creates Listeners for ALB and NLB
- ✅ Creates Listener Rules with advanced conditions
- ✅ Supports host-based routing
- ✅ Supports path-based routing
- ✅ Requires existing Load Balancer (separation of concerns)
- ✅ Map-based configuration for stability
- ✅ Comprehensive validations
- ✅ PC-IAC compliant structure

### Requirements
- Terraform >= 1.0
- AWS Provider >= 4.31.0
- Existing Load Balancer (created with cloudops-ref-repo-aws-elb-terraform)

### Breaking Changes
- N/A (initial release)

### Notes
- This module is designed to work with cloudops-ref-repo-aws-elb-terraform v1.0.0
- Requires Load Balancer ARN from existing Load Balancer
- Listener Rules only apply to Application Load Balancers
- Each rule must have unique priority per listener
