# Fixed Response Implementation Summary

## Overview
This document summarizes the changes made to support fixed response actions in the ALB Listener Terraform module.

## Changes Made

### 1. **variables.tf**
- Made `target_application_id` optional (only required for forward actions)
- Added optional `fixed_response` object to listener rules configuration
- Structure includes:
  - `content_type`: Response content type (required)
  - `message_body`: Response body content (optional)
  - `status_code`: HTTP status code (required)
- Added validation to ensure correct configuration per action type

### 2. **main.tf**
- Modified `aws_lb_listener_rule` resource action block
- Made `target_group_arn` conditional (only for forward actions)
- Added dynamic `fixed_response` block for fixed-response actions
- Maintained proper action ordering with JWT validation

### 3. **EXAMPLE_FIXED_RESPONSE.md** (New File)
Created comprehensive examples demonstrating:
- Basic health check endpoints
- Maintenance mode pages
- API rate limit responses
- Mixed rules (forward + fixed response)
- Custom error pages
- All five content types
- Various status codes

### 4. **README.md**
- Added Fixed Response to features list
- Added fixed response example in usage section
- Updated `listener_config` structure documentation
- Added reference to EXAMPLE_FIXED_RESPONSE.md

### 5. **CHANGELOG.md**
- Added v1.2.0 release notes
- Documented all new features and changes
- Listed requirements and use cases

## Key Features

### Fixed Response Configuration
```hcl
fixed_response = {
  content_type = "text/plain"
  message_body = "HEALTHY"
  status_code  = "200"
}
```

### Action Type Logic
- **forward**: Requires `target_application_id` and target group
- **fixed-response**: Requires `fixed_response` configuration, no target group needed

### Backward Compatibility
- Existing forward actions continue to work unchanged
- `target_application_id` is optional but validated based on action type
- No breaking changes to existing functionality

## AWS ALB Fixed Response Capabilities

### Content Types
Five supported content types:
1. `text/plain` - Plain text responses
2. `text/css` - CSS stylesheets
3. `text/html` - HTML pages
4. `application/javascript` - JavaScript code
5. `application/json` - JSON data

### Status Codes
Two formats supported:
1. **Specific codes**: `200`, `404`, `503`, etc.
2. **Patterns**: `2XX`, `4XX`, `5XX`

### Message Body
- Optional field
- Can contain any text content
- Must match the specified content_type
- Useful for user-friendly error messages

## Use Cases

### 1. Health Check Endpoints
Return static health responses without backend:
```hcl
action = { type = "fixed-response" }
fixed_response = {
  content_type = "text/plain"
  message_body = "HEALTHY"
  status_code  = "200"
}
```

**Benefits:**
- No backend processing required
- Faster response times
- Reduced backend load
- Cost savings (no data transfer to targets)

### 2. Maintenance Mode
Display maintenance pages during deployments:
```hcl
action = { type = "fixed-response" }
fixed_response = {
  content_type = "text/html"
  message_body = "<html><body><h1>Under Maintenance</h1></body></html>"
  status_code  = "503"
}
```

**Benefits:**
- No need to deploy maintenance app
- Instant activation/deactivation
- Consistent user experience

### 3. Custom Error Pages
Provide branded error pages:
```hcl
action = { type = "fixed-response" }
fixed_response = {
  content_type = "text/html"
  message_body = "<html><body><h1>404 - Page Not Found</h1></body></html>"
  status_code  = "404"
}
```

**Benefits:**
- Better user experience
- Brand consistency
- No backend required

### 4. API Responses
Return static API responses:
```hcl
action = { type = "fixed-response" }
fixed_response = {
  content_type = "application/json"
  message_body = "{\"status\":\"ok\",\"version\":\"1.0\"}"
  status_code  = "200"
}
```

**Benefits:**
- Fast API responses
- No backend processing
- Useful for version endpoints

### 5. Rate Limiting
Return rate limit errors:
```hcl
action = { type = "fixed-response" }
fixed_response = {
  content_type = "application/json"
  message_body = "{\"error\":\"Rate limit exceeded\"}"
  status_code  = "429"
}
```

**Benefits:**
- Protect backend from overload
- Clear error messages
- Standard HTTP status codes

## Technical Details

### Action Ordering
When combined with JWT validation:
1. JWT validation action: `order = 1`
2. Fixed response or forward action: `order = 2`

### Validation Logic
```hcl
validation {
  condition = alltrue([
    for rule in rules :
    (rule.action.type == "forward" && rule.target_application_id != null) ||
    (rule.action.type == "fixed-response" && rule.fixed_response != null)
  ])
  error_message = "Forward actions require target_application_id. Fixed-response actions require fixed_response."
}
```

### Resource Logic
```hcl
action {
  type  = each.value.rule.action.type
  order = each.value.rule.jwt_validation != null ? 2 : 1

  # Only set target_group_arn for forward actions
  target_group_arn = each.value.rule.action.type == "forward" ? 
    aws_lb_target_group.lb_target_group[each.value.rule.target_application_id].arn : null

  # Only add fixed_response block for fixed-response actions
  dynamic "fixed_response" {
    for_each = each.value.rule.action.type == "fixed-response" ? [1] : []
    content {
      content_type = each.value.rule.fixed_response.content_type
      message_body = each.value.rule.fixed_response.message_body
      status_code  = each.value.rule.fixed_response.status_code
    }
  }
}
```

## Benefits

### Performance
- **Faster responses**: No backend processing or network hops
- **Lower latency**: Response generated at ALB level
- **Reduced load**: Backend servers not involved

### Cost Savings
- **No data transfer**: No traffic to backend targets
- **No compute**: No backend processing required
- **Reduced infrastructure**: Fewer backend instances needed for static responses

### Operational
- **Simplified architecture**: No need for dedicated health check or maintenance apps
- **Quick changes**: Update responses without backend deployments
- **High availability**: ALB handles responses even if backends are down

## Migration Guide

### For Existing Users
No migration needed! Fixed response is optional and backward compatible.

### For New Fixed Response Users
1. Identify endpoints that can use static responses
2. Add `fixed_response` configuration to rules
3. Set `action.type = "fixed-response"`
4. Remove `target_application_id` (not needed)
5. Deploy and test

### Example Migration
**Before (Forward to backend):**
```hcl
{
  priority              = 100
  target_application_id = "health-check"
  action = { type = "forward" }
  conditions = [...]
}
```

**After (Fixed response):**
```hcl
{
  priority = 100
  action = { type = "fixed-response" }
  fixed_response = {
    content_type = "text/plain"
    message_body = "HEALTHY"
    status_code  = "200"
  }
  conditions = [...]
}
```

## Testing Recommendations

### Unit Tests
1. Validate fixed_response is optional
2. Validate target_application_id is optional
3. Validate action type validation logic
4. Validate content_type values
5. Validate status_code formats

### Integration Tests
1. Deploy rule with fixed response
2. Test response content and status code
3. Test mixed rules (forward + fixed response)
4. Test with JWT validation + fixed response
5. Verify no backend traffic for fixed responses

### Functional Tests
1. Health check endpoint returns correct response
2. Maintenance mode displays correct page
3. Error pages show correct content
4. API responses return valid JSON
5. Status codes match configuration

## Limitations

1. **Content Types**: Only five types supported
2. **Message Body Size**: Limited by ALB constraints
3. **Dynamic Content**: Cannot generate dynamic responses
4. **No Backend Logic**: Cannot execute business logic
5. **Static Only**: Content is fixed at deployment time

## Best Practices

### 1. Use for Static Content Only
Fixed responses are ideal for content that doesn't change frequently:
- Health checks
- Version endpoints
- Static error pages
- Maintenance pages

### 2. Keep Message Bodies Small
- Minimize response size for better performance
- Use external resources for large content (CSS, images)

### 3. Use Appropriate Status Codes
- `200` for successful responses
- `404` for not found
- `503` for maintenance/unavailable
- `429` for rate limiting

### 4. Provide User-Friendly Messages
Always include message_body for better user experience:
```hcl
message_body = "Service temporarily unavailable. Please try again later."
```

### 5. Mix with Forward Actions
Use fixed responses for static endpoints, forward for dynamic:
```hcl
rules = [
  { priority = 10, action = { type = "fixed-response" }, ... },  # /health
  { priority = 100, action = { type = "forward" }, ... }         # /api/*
]
```

## Support

For questions or issues:
1. Review EXAMPLE_FIXED_RESPONSE.md for comprehensive examples
2. Check AWS documentation: https://docs.aws.amazon.com/elasticloadbalancing/latest/application/listener-rules.html
3. Contact CloudOps team at Pragma

## Version History

- **v1.2.0** (2026-02-02): Added fixed response support
- **v1.1.0** (2026-02-02): Added JWT verification support
- **v1.0.0** (2026-01-26): Initial release

---

**Maintained by:** Pragma CloudOps Team  
**Last Updated:** 2026-02-02
