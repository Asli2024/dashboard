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
