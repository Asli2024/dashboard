
# Find RDS instances by tag
data "aws_resourcegroupstaggingapi_resources" "rds" {
  resource_type_filters = ["rds:db"]

  tag_filter {
    key    = "Environment"
    values = [var.environment]
  }
}

# Find API Gateway APIs by tag
data "aws_resourcegroupstaggingapi_resources" "apigw" {
  resource_type_filters = ["apigateway:restapis"]

  tag_filter {
    key    = "Environment"
    values = [var.environment]
  }
}

# Amplify app IDs are provided directly via var.amplify_app_ids

# Find EC2 instances by tag
data "aws_resourcegroupstaggingapi_resources" "ec2" {
  resource_type_filters = ["ec2:instance"]

  tag_filter {
    key    = "Environment"
    values = [var.environment]
  }
}

# Find Lambda functions by tag
data "aws_resourcegroupstaggingapi_resources" "lambdas" {
  resource_type_filters = ["lambda:function"]

  tag_filter {
    key    = "Environment"
    values = [var.environment]
  }
}

locals {
  rds_identifiers = sort([
    for resource in data.aws_resourcegroupstaggingapi_resources.rds.resource_tag_mapping_list :
    split(":", resource.resource_arn)[6]
  ])

  function_names = sort([
    for resource in data.aws_resourcegroupstaggingapi_resources.lambdas.resource_tag_mapping_list :
    split(":", resource.resource_arn)[6]
  ])

  # Requires API Gateway REST APIs to be tagged with a "Name" tag matching the API name,
  # since the CloudWatch ApiName dimension uses the name, not the ID.
  api_names = sort([
    for resource in data.aws_resourcegroupstaggingapi_resources.apigw.resource_tag_mapping_list :
    lookup(resource.tags, "Name", regex("/restapis/([^/]+)", resource.resource_arn)[0])
  ])

  amplify_app_ids = var.amplify_app_ids

  ec2_instance_ids = sort([
    for resource in data.aws_resourcegroupstaggingapi_resources.ec2.resource_tag_mapping_list :
    split("/", resource.resource_arn)[1]
  ])
}

resource "aws_cloudwatch_dashboard" "this" {
  dashboard_name = "${var.environment}-monitoring"

  dashboard_body = jsonencode({
    widgets = [

      # -------------------------------------------------------
      # Lambda - Errors
      # -------------------------------------------------------
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 6
        height = 6

        properties = {
          title  = "Lambda Errors - ${var.environment}"
          region = var.aws_region
          stat   = "Sum"
          period = 300
          view   = "timeSeries"

          metrics = [
            for fn in local.function_names :
            ["AWS/Lambda", "Errors", "FunctionName", fn]
          ]
        }
      },

      # -------------------------------------------------------
      # Lambda - Invocations
      # -------------------------------------------------------
      {
        type   = "metric"
        x      = 6
        y      = 0
        width  = 6
        height = 6

        properties = {
          title  = "Lambda Invocations - ${var.environment}"
          region = var.aws_region
          stat   = "Sum"
          period = 300
          view   = "timeSeries"

          metrics = [
            for fn in local.function_names :
            ["AWS/Lambda", "Invocations", "FunctionName", fn]
          ]
        }
      },

      # -------------------------------------------------------
      # API Gateway - 5XX Errors
      # -------------------------------------------------------
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 6
        height = 6

        properties = {
          title  = "API Gateway 5XX Errors - ${var.environment}"
          region = var.aws_region
          stat   = "Sum"
          period = 300
          view   = "timeSeries"

          metrics = [
            for api in local.api_names :
            ["AWS/ApiGateway", "5XXError", "ApiName", api]
          ]
        }
      },

      # -------------------------------------------------------
      # API Gateway - Latency
      # -------------------------------------------------------
      {
        type   = "metric"
        x      = 18
        y      = 0
        width  = 6
        height = 6

        properties = {
          title  = "API Gateway Latency - ${var.environment}"
          region = var.aws_region
          stat   = "Average"
          period = 300
          view   = "timeSeries"

          metrics = [
            for api in local.api_names :
            ["AWS/ApiGateway", "Latency", "ApiName", api]
          ]
        }
      },

      # -------------------------------------------------------
      # RDS - CPU Utilization
      # -------------------------------------------------------
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 6
        height = 6

        properties = {
          title  = "RDS CPU Utilization - ${var.environment}"
          region = var.aws_region
          stat   = "Average"
          period = 300
          view   = "timeSeries"

          metrics = [
            for db in local.rds_identifiers :
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", db]
          ]
        }
      },

      # -------------------------------------------------------
      # RDS - Freeable Memory
      # -------------------------------------------------------
      {
        type   = "metric"
        x      = 6
        y      = 6
        width  = 6
        height = 6

        properties = {
          title  = "RDS Freeable Memory - ${var.environment}"
          region = var.aws_region
          stat   = "Average"
          period = 300
          view   = "timeSeries"

          metrics = [
            for db in local.rds_identifiers :
            ["AWS/RDS", "FreeableMemory", "DBInstanceIdentifier", db]
          ]
        }
      },

      # -------------------------------------------------------
      # RDS - Database Connections
      # -------------------------------------------------------
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 6
        height = 6

        properties = {
          title  = "RDS Database Connections - ${var.environment}"
          region = var.aws_region
          stat   = "Average"
          period = 300
          view   = "timeSeries"

          metrics = [
            for db in local.rds_identifiers :
            ["AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", db]
          ]
        }
      },

      # -------------------------------------------------------
      # Amplify - 5XX Errors
      # -------------------------------------------------------
      {
        type   = "metric"
        x      = 18
        y      = 6
        width  = 6
        height = 6

        properties = {
          title  = "Amplify 5XX Errors - ${var.environment}"
          region = var.aws_region
          stat   = "Sum"
          period = 300
          view   = "timeSeries"

          metrics = [
            for app_id in local.amplify_app_ids :
            ["AWS/AmplifyHosting", "5xxErrors", "App", app_id]
          ]
        }
      },

      # -------------------------------------------------------
      # Amplify - Latency
      # -------------------------------------------------------
      {
        type   = "metric"
        x      = 0
        y      = 12
        width  = 6
        height = 6

        properties = {
          title  = "Amplify Latency - ${var.environment}"
          region = var.aws_region
          stat   = "Average"
          period = 300
          view   = "timeSeries"

          metrics = [
            for app_id in local.amplify_app_ids :
            ["AWS/AmplifyHosting", "Latency", "App", app_id]
          ]
        }
      },

      # -------------------------------------------------------
      # Amplify - Bytes Downloaded
      # -------------------------------------------------------
      {
        type   = "metric"
        x      = 6
        y      = 12
        width  = 6
        height = 6

        properties = {
          title  = "Amplify Bytes Downloaded - ${var.environment}"
          region = var.aws_region
          stat   = "Sum"
          period = 300
          view   = "timeSeries"

          metrics = [
            for app_id in local.amplify_app_ids :
            ["AWS/AmplifyHosting", "BytesDownloaded", "App", app_id]
          ]
        }
      },

      # -------------------------------------------------------
      # EC2 - CPU Utilization
      # -------------------------------------------------------
      {
        type   = "metric"
        x      = 12
        y      = 12
        width  = 6
        height = 6

        properties = {
          title  = "EC2 CPU Utilization - ${var.environment}"
          region = var.aws_region
          stat   = "Average"
          period = 300
          view   = "timeSeries"

          metrics = [
            for id in local.ec2_instance_ids :
            ["AWS/EC2", "CPUUtilization", "InstanceId", id]
          ]
        }
      },

      # -------------------------------------------------------
      # EC2 - Status Check Failed
      # -------------------------------------------------------
      {
        type   = "metric"
        x      = 18
        y      = 12
        width  = 6
        height = 6

        properties = {
          title  = "EC2 Status Check Failed - ${var.environment}"
          region = var.aws_region
          stat   = "Maximum"
          period = 300
          view   = "timeSeries"

          metrics = [
            for id in local.ec2_instance_ids :
            ["AWS/EC2", "StatusCheckFailed", "InstanceId", id]
          ]
        }
      }
    ]
  })
}

