resource "aws_cloudwatch_dashboard" "application_monitoring" {
  dashboard_name = "Application-Monitoring-Dashboard"

  dashboard_body = jsonencode({
    widgets = [

      # -----------------------------------------------------
      # Lambda - Errors
      # -----------------------------------------------------
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 6
        height = 6

        properties = {
          title  = "Lambda Function - Errors (Environment=prod)"
          view   = "timeSeries"
          region = var.aws_region
          period = 300
          stat   = "Sum"

          metrics = [
            [
              {
                expression = "SEARCH('{AWS/Lambda,FunctionName} MetricName=\"Errors\"', 'Sum', 300)"
                id         = "lambda_errors"
              }
            ]
          ]
        }
      },

      # -----------------------------------------------------
      # API Gateway - 5XX
      # -----------------------------------------------------
      {
        type   = "metric"
        x      = 6
        y      = 0
        width  = 6
        height = 6

        properties = {
          title  = "Api - 5XXError"
          view   = "timeSeries"
          region = var.aws_region
          period = 300
          stat   = "Sum"

          metrics = [
            [
              {
                expression = "SEARCH('{AWS/ApiGateway,ApiName} MetricName=\"5XXError\"', 'Sum', 300)"
                id         = "api_5xx"
              }
            ]
          ]
        }
      },

      # -----------------------------------------------------
      # RDS CPU
      # -----------------------------------------------------
      {
        type   = "metric"
        x      = 18
        y      = 0
        width  = 6
        height = 6

        properties = {
          title  = "RDS - CPUUtilization"
          view   = "timeSeries"
          region = var.aws_region
          period = 300
          stat   = "Average"

          metrics = [
            [
              {
                expression = "SEARCH('{AWS/RDS,DBInstanceIdentifier} MetricName=\"CPUUtilization\"', 'Average', 300)"
                id         = "rds_cpu"
              }
            ]
          ]
        }
      },

      # -----------------------------------------------------
      # API Gateway Latency
      # -----------------------------------------------------
      {
        type   = "metric"
        x      = 6
        y      = 6
        width  = 6
        height = 6

        properties = {
          title  = "Api - Latency"
          view   = "timeSeries"
          region = var.aws_region
          period = 300
          stat   = "Average"

          metrics = [
            [
              {
                expression = "SEARCH('{AWS/ApiGateway,ApiName} MetricName=\"Latency\"', 'Average', 300)"
                id         = "api_latency"
              }
            ]
          ]
        }
      },

      # -----------------------------------------------------
      # Lambda Duration
      # -----------------------------------------------------
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 6
        height = 6

        properties = {
          title  = "Lambda - Duration"
          view   = "timeSeries"
          region = var.aws_region
          period = 300
          stat   = "Average"

          metrics = [
            [
              {
                expression = "SEARCH('{AWS/Lambda,FunctionName} MetricName=\"Duration\"', 'Average', 300)"
                id         = "lambda_duration"
              }
            ]
          ]
        }
      },

      # -----------------------------------------------------
      # RDS Freeable Memory
      # -----------------------------------------------------
      {
        type   = "metric"
        x      = 18
        y      = 6
        width  = 6
        height = 6

        properties = {
          title  = "RDS - FreeableMemory"
          view   = "timeSeries"
          region = var.aws_region
          period = 300
          stat   = "Average"

          metrics = [
            [
              {
                expression = "SEARCH('{AWS/RDS,DBInstanceIdentifier} MetricName=\"FreeableMemory\"', 'Average', 300)"
                id         = "rds_memory"
              }
            ]
          ]
        }
      },

      # -----------------------------------------------------
      # RDS Database Connections
      # -----------------------------------------------------
      {
        type   = "metric"
        x      = 0
        y      = 12
        width  = 6
        height = 6

        properties = {
          title  = "RDS - DatabaseConnections"
          view   = "timeSeries"
          region = var.aws_region
          period = 300
          stat   = "Average"

          metrics = [
            [
              {
                expression = "SEARCH('{AWS/RDS,DBInstanceIdentifier} MetricName=\"DatabaseConnections\"', 'Average', 300)"
                id         = "rds_connections"
              }
            ]
          ]
        }
      }
    ]
  })
}


# ---------------------------------------------------------
# Lambda - Errors
# Automatically discovers Lambdas tagged environment=prod
# ---------------------------------------------------------

{
  type   = "explorer"
  x      = 0
  y      = 0
  width  = 6
  height = 6

  properties = {
    metrics = [
      {
        metricName = "Errors"
        resourceType = "AWS::Lambda::Function"
        stat = "Sum"
      }
    ]

    labels = [
      {
        key   = "environment"
        value = "prod"
      }
    ]

    widgetOptions = {
      legend = {
        position = "bottom"
      }

      view    = "timeSeries"
      stacked = false
      rowsPerPage = 50
    }

    period = 300
  }
}

data "aws_resourcegroupstaggingapi_resources" "prod_lambdas" {
  resource_type_filters = ["lambda:function"]

  tag_filter {
    key    = "environment"
    values = ["prod"]
  }
}

locals {
  prod_function_names = sort([
    for resource in data.aws_resourcegroupstaggingapi_resources.prod_lambdas.resource_tag_mapping_list :
    split(":", resource.resource_arn)[6]
  ])
}

resource "aws_cloudwatch_dashboard" "prod_lambdas" {
  dashboard_name = "prod-lambdas"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 24
        height = 8

        properties = {
          title  = "Lambda Errors - prod"
          region = var.aws_region
          stat   = "Sum"
          period = 300
          view   = "timeSeries"

          metrics = [
            for fn in local.prod_function_names :
            ["AWS/Lambda", "Errors", "FunctionName", fn]
          ]
        }
      },

      {
        type   = "metric"
        x      = 0
        y      = 8
        width  = 24
        height = 8

        properties = {
          title  = "Lambda Invocations - prod"
          region = var.aws_region
          stat   = "Sum"
          period = 300
          view   = "timeSeries"

          metrics = [
            for fn in local.prod_function_names :
            ["AWS/Lambda", "Invocations", "FunctionName", fn]
          ]
        }
      }
    ]
  })
}
