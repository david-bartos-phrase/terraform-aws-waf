variable "region" {
  type        = string
  description = "AWS region"
}

variable "association_config" {
  type = object({
    request_body = map(object({
      default_size_inspection_limit = string
    }))
  })
  default     = null
  nullable    = true
  description = "Optional request body inspection limits forwarded to the WAF module; null preserves service defaults."

  validation {
    condition = var.association_config == null ? true : try(alltrue([
      for resource_type in keys(var.association_config.request_body) :
      contains(["api_gateway", "app_runner_service", "cloudfront", "cognito_user_pool", "verified_access_instance"], resource_type)
    ]), false)
    error_message = "request_body must be a non-null map with only api_gateway, app_runner_service, cloudfront, cognito_user_pool, or verified_access_instance keys."
  }

  validation {
    condition = var.association_config == null ? true : try(alltrue([
      for config in values(var.association_config.request_body) :
      contains(["KB_16", "KB_32", "KB_48", "KB_64"], config.default_size_inspection_limit)
    ]), false)
    error_message = "Each request_body entry must set default_size_inspection_limit to KB_16, KB_32, KB_48, or KB_64."
  }
}
