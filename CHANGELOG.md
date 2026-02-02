# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
