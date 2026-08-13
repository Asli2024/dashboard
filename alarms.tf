# -------------------------------------------------------
# Lambda Alarms — account-level aggregate metrics
#
# Lambda publishes metrics with no FunctionName dimension
# that aggregate all functions in the account. Since this
# module is deployed once per environment (separate AWS
# account or assumed role), these 4 alarms effectively
# cover all env-tagged functions without creating one
# alarm per function.
# -------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "${var.environment}-lambda-errors"
  alarm_description   = "Total Lambda errors across the ${var.environment} account are too high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 10
  treat_missing_data  = "notBreaching"
}

resource "aws_cloudwatch_metric_alarm" "lambda_throttles" {
  alarm_name          = "${var.environment}-lambda-throttles"
  alarm_description   = "Total Lambda throttles across the ${var.environment} account are too high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "Throttles"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 20
  treat_missing_data  = "notBreaching"
}

resource "aws_cloudwatch_metric_alarm" "lambda_duration" {
  alarm_name          = "${var.environment}-lambda-duration"
  alarm_description   = "p95 Lambda duration across the ${var.environment} account is too high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "Duration"
  namespace           = "AWS/Lambda"
  period              = 300
  extended_statistic  = "p95"
  threshold           = 10000
  treat_missing_data  = "notBreaching"
}

resource "aws_cloudwatch_metric_alarm" "lambda_concurrent_executions" {
  alarm_name          = "${var.environment}-lambda-concurrency"
  alarm_description   = "Total concurrent Lambda executions across the ${var.environment} account are too high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "ConcurrentExecutions"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Maximum"
  threshold           = 500
  treat_missing_data  = "notBreaching"
}

# -------------------------------------------------------
# API Gateway Alarms (filtered by Environment tag)
# -------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "apigw_5xx" {
  for_each = toset(local.api_names)

  alarm_name          = "${var.environment}-apigw-5xx-${each.value}"
  alarm_description   = "API Gateway ${each.value} 5XX error rate is too high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  threshold           = 10
  treat_missing_data  = "notBreaching"

  metric_query {
    id          = "e5xx"
    label       = "5XX Errors"
    return_data = true
    metric {
      metric_name = "5XXError"
      namespace   = "AWS/ApiGateway"
      period      = 300
      stat        = "Sum"
      dimensions = {
        ApiName = each.value
      }
    }
  }
}

resource "aws_cloudwatch_metric_alarm" "apigw_4xx" {
  for_each = toset(local.api_names)

  alarm_name          = "${var.environment}-apigw-4xx-${each.value}"
  alarm_description   = "API Gateway ${each.value} 4XX error rate is too high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  threshold           = 50
  treat_missing_data  = "notBreaching"

  metric_query {
    id          = "e4xx"
    label       = "4XX Errors"
    return_data = true
    metric {
      metric_name = "4XXError"
      namespace   = "AWS/ApiGateway"
      period      = 300
      stat        = "Sum"
      dimensions = {
        ApiName = each.value
      }
    }
  }
}

resource "aws_cloudwatch_metric_alarm" "apigw_latency" {
  for_each = toset(local.api_names)

  alarm_name          = "${var.environment}-apigw-latency-${each.value}"
  alarm_description   = "API Gateway ${each.value} p99 latency is too high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  threshold           = 3000
  treat_missing_data  = "notBreaching"

  metric_query {
    id          = "latency"
    label       = "p99 Latency"
    return_data = true
    metric {
      metric_name = "Latency"
      namespace   = "AWS/ApiGateway"
      period      = 300
      stat        = "p99"
      dimensions = {
        ApiName = each.value
      }
    }
  }
}

resource "aws_cloudwatch_metric_alarm" "apigw_count_low" {
  for_each = toset(local.api_names)

  alarm_name          = "${var.environment}-apigw-count-low-${each.value}"
  alarm_description   = "API Gateway ${each.value} request count dropped unexpectedly"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 3
  threshold           = 1
  treat_missing_data  = "breaching"

  metric_query {
    id          = "count"
    label       = "Request Count"
    return_data = true
    metric {
      metric_name = "Count"
      namespace   = "AWS/ApiGateway"
      period      = 300
      stat        = "Sum"
      dimensions = {
        ApiName = each.value
      }
    }
  }
}

# -------------------------------------------------------
# Amplify Alarms (no env filter — uses var.amplify_app_ids)
# -------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "amplify_5xx" {
  for_each = toset(local.amplify_app_ids)

  alarm_name          = "amplify-5xx-${each.value}"
  alarm_description   = "Amplify app ${each.value} is returning 5XX errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  threshold           = 10
  treat_missing_data  = "notBreaching"

  metric_query {
    id          = "e5xx"
    label       = "5XX Errors"
    return_data = true
    metric {
      metric_name = "5xxErrors"
      namespace   = "AWS/AmplifyHosting"
      period      = 300
      stat        = "Sum"
      dimensions = {
        App = each.value
      }
    }
  }
}

resource "aws_cloudwatch_metric_alarm" "amplify_4xx" {
  for_each = toset(local.amplify_app_ids)

  alarm_name          = "amplify-4xx-${each.value}"
  alarm_description   = "Amplify app ${each.value} is returning 4XX errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  threshold           = 50
  treat_missing_data  = "notBreaching"

  metric_query {
    id          = "e4xx"
    label       = "4XX Errors"
    return_data = true
    metric {
      metric_name = "4xxErrors"
      namespace   = "AWS/AmplifyHosting"
      period      = 300
      stat        = "Sum"
      dimensions = {
        App = each.value
      }
    }
  }
}

resource "aws_cloudwatch_metric_alarm" "amplify_bytes_downloaded" {
  for_each = toset(local.amplify_app_ids)

  alarm_name          = "amplify-bytes-downloaded-${each.value}"
  alarm_description   = "Amplify app ${each.value} bytes downloaded spike detected"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  threshold           = 5368709120 # 5 GB
  treat_missing_data  = "notBreaching"

  metric_query {
    id          = "bytes"
    label       = "Bytes Downloaded"
    return_data = true
    metric {
      metric_name = "BytesDownloaded"
      namespace   = "AWS/AmplifyHosting"
      period      = 300
      stat        = "Sum"
      dimensions = {
        App = each.value
      }
    }
  }
}

resource "aws_cloudwatch_metric_alarm" "amplify_requests_low" {
  for_each = toset(local.amplify_app_ids)

  alarm_name          = "amplify-requests-low-${each.value}"
  alarm_description   = "Amplify app ${each.value} request count dropped — possible outage"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 3
  threshold           = 1
  treat_missing_data  = "breaching"

  metric_query {
    id          = "requests"
    label       = "Requests"
    return_data = true
    metric {
      metric_name = "Requests"
      namespace   = "AWS/AmplifyHosting"
      period      = 300
      stat        = "Sum"
      dimensions = {
        App = each.value
      }
    }
  }
}

# -------------------------------------------------------
# EC2 Alarms (filtered by Environment tag)
# -------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "ec2_cpu" {
  for_each = toset(local.ec2_instance_ids)

  alarm_name          = "${var.environment}-ec2-cpu-${each.value}"
  alarm_description   = "EC2 instance ${each.value} CPU utilization is too high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  threshold           = 80
  treat_missing_data  = "notBreaching"

  metric_query {
    id          = "cpu"
    label       = "CPU Utilization"
    return_data = true
    metric {
      metric_name = "CPUUtilization"
      namespace   = "AWS/EC2"
      period      = 300
      stat        = "Average"
      dimensions = {
        InstanceId = each.value
      }
    }
  }
}

resource "aws_cloudwatch_metric_alarm" "ec2_status_check" {
  for_each = toset(local.ec2_instance_ids)

  alarm_name          = "${var.environment}-ec2-status-check-${each.value}"
  alarm_description   = "EC2 instance ${each.value} status check failed"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  threshold           = 0
  treat_missing_data  = "breaching"

  metric_query {
    id          = "status"
    label       = "Status Check Failed"
    return_data = true
    metric {
      metric_name = "StatusCheckFailed"
      namespace   = "AWS/EC2"
      period      = 60
      stat        = "Maximum"
      dimensions = {
        InstanceId = each.value
      }
    }
  }
}

resource "aws_cloudwatch_metric_alarm" "ec2_network_in" {
  for_each = toset(local.ec2_instance_ids)

  alarm_name          = "${var.environment}-ec2-network-in-${each.value}"
  alarm_description   = "EC2 instance ${each.value} inbound network traffic is unusually high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  threshold           = 52428800 # 50 MB
  treat_missing_data  = "notBreaching"

  metric_query {
    id          = "net_in"
    label       = "Network In"
    return_data = true
    metric {
      metric_name = "NetworkIn"
      namespace   = "AWS/EC2"
      period      = 300
      stat        = "Average"
      dimensions = {
        InstanceId = each.value
      }
    }
  }
}

resource "aws_cloudwatch_metric_alarm" "ec2_disk_read_ops" {
  for_each = toset(local.ec2_instance_ids)

  alarm_name          = "${var.environment}-ec2-disk-read-ops-${each.value}"
  alarm_description   = "EC2 instance ${each.value} disk read I/O is saturated"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  threshold           = 10000
  treat_missing_data  = "notBreaching"

  metric_query {
    id          = "disk_reads"
    label       = "Disk Read Ops"
    return_data = true
    metric {
      metric_name = "DiskReadOps"
      namespace   = "AWS/EC2"
      period      = 300
      stat        = "Average"
      dimensions = {
        InstanceId = each.value
      }
    }
  }
}


resource "aws_cloudwatch_metric_alarm" "prod_lambda_errors" {
  alarm_name        = "prod-lambda-errors"
  alarm_description = "Errors in any Lambda tagged Environment=prod"

  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  threshold           = 0
  treat_missing_data  = "notBreaching"

  alarm_actions = [var.sns_topic_arn]
  ok_actions    = [var.sns_topic_arn]

  metric_query {
    id          = "q1"
    return_data = true
    period      = 300

    expression = <<-EOT
      SELECT SUM(Errors)
      FROM SCHEMA("AWS/Lambda", FunctionName)
      WHERE tag.Environment = 'prod'
    EOT
  }
}

variable "sns_topic_arn" {
  type = string
}
