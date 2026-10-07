mock_provider "aws" {}

variables {
  name  = "association-config-test"
  scope = "CLOUDFRONT"
  visibility_config = {
    cloudwatch_metrics_enabled = false
    metric_name                = "association-config-test"
    sampled_requests_enabled   = false
  }
}

run "omitted_configuration" {
  command = plan

  assert {
    condition     = length(aws_wafv2_web_acl.default[0].association_config) == 0
    error_message = "Omitting association_config must leave the native resource unchanged."
  }
}

run "null_configuration" {
  command = plan

  variables {
    association_config = null
  }

  assert {
    condition     = length(aws_wafv2_web_acl.default[0].association_config) == 0
    error_message = "Explicit null must omit association_config."
  }
}

run "cloudfront_body_limit" {
  command = plan

  variables {
    association_config = {
      request_body = {
        cloudfront = { default_size_inspection_limit = "KB_32" }
      }
    }
  }

  assert {
    condition     = aws_wafv2_web_acl.default[0].association_config[0].request_body[0].cloudfront[0].default_size_inspection_limit == "KB_32"
    error_message = "The CloudFront body inspection limit must reach the native Web ACL."
  }

  assert {
    condition = alltrue([
      length(aws_wafv2_web_acl.default[0].association_config[0].request_body[0].api_gateway) == 0,
      length(aws_wafv2_web_acl.default[0].association_config[0].request_body[0].app_runner_service) == 0,
      length(aws_wafv2_web_acl.default[0].association_config[0].request_body[0].cognito_user_pool) == 0,
      length(aws_wafv2_web_acl.default[0].association_config[0].request_body[0].verified_access_instance) == 0,
    ])
    error_message = "Unconfigured resource types must not produce empty nested blocks."
  }
}

run "all_supported_resource_types" {
  command = plan

  variables {
    scope = "REGIONAL"
    association_config = {
      request_body = {
        api_gateway              = { default_size_inspection_limit = "KB_16" }
        app_runner_service       = { default_size_inspection_limit = "KB_32" }
        cloudfront               = { default_size_inspection_limit = "KB_48" }
        cognito_user_pool        = { default_size_inspection_limit = "KB_64" }
        verified_access_instance = { default_size_inspection_limit = "KB_32" }
      }
    }
  }

  assert {
    condition = alltrue([
      aws_wafv2_web_acl.default[0].association_config[0].request_body[0].api_gateway[0].default_size_inspection_limit == "KB_16",
      aws_wafv2_web_acl.default[0].association_config[0].request_body[0].app_runner_service[0].default_size_inspection_limit == "KB_32",
      aws_wafv2_web_acl.default[0].association_config[0].request_body[0].cloudfront[0].default_size_inspection_limit == "KB_48",
      aws_wafv2_web_acl.default[0].association_config[0].request_body[0].cognito_user_pool[0].default_size_inspection_limit == "KB_64",
      aws_wafv2_web_acl.default[0].association_config[0].request_body[0].verified_access_instance[0].default_size_inspection_limit == "KB_32",
    ])
    error_message = "Every supported resource type must forward its configured limit."
  }
}

run "empty_configuration" {
  command = plan

  variables {
    association_config = { request_body = {} }
  }

  assert {
    condition     = length(aws_wafv2_web_acl.default[0].association_config) == 0
    error_message = "An empty request_body map must not emit an empty association_config block."
  }
}

run "reject_invalid_limit" {
  command = plan

  variables {
    association_config = {
      request_body = {
        cloudfront = { default_size_inspection_limit = "KB_128" }
      }
    }
  }

  expect_failures = [var.association_config]
}

run "reject_unsupported_resource_type" {
  command = plan

  variables {
    association_config = {
      request_body = {
        application_load_balancer = { default_size_inspection_limit = "KB_32" }
      }
    }
  }

  expect_failures = [var.association_config]
}

run "reject_null_request_body" {
  command = plan

  variables {
    association_config = { request_body = null }
  }

  expect_failures = [var.association_config]
}

run "reject_null_resource_configuration" {
  command = plan

  variables {
    association_config = {
      request_body = { cloudfront = null }
    }
  }

  expect_failures = [var.association_config]
}
