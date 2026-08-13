# -------------------------------------------------------
# Lambda Alarms (filtered by Environment tag)
#
# Uses CloudWatch Metrics Insights SQL with
# WHERE tag.Environment = '<env>' so only functions
# carrying that tag are included — regardless of name.
# -------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "${var.environment}-lambda-errors"
  alarm_description   = "Total errors across all Lambda functions tagged Environment=${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  threshold           = 10
  treat_missing_data  = "notBreaching"
  alarm_actions       = [var.sns_topic_arn]
  ok_actions          = [var.sns_topic_arn]

  metric_query {
    id          = "errors"
    return_data = true
    period      = 300
    expression  = "SELECT SUM(Errors) FROM SCHEMA(\"AWS/Lambda\", FunctionName) WHERE tag.Environment = '${var.environment}'"
  }
}

resource "aws_cloudwatch_metric_alarm" "lambda_throttles" {
  alarm_name          = "${var.environment}-lambda-throttles"
  alarm_description   = "Total throttles across all Lambda functions tagged Environment=${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  threshold           = 20
  treat_missing_data  = "notBreaching"
  alarm_actions       = [var.sns_topic_arn]
  ok_actions          = [var.sns_topic_arn]

  metric_query {
    id          = "throttles"
    return_data = true
    period      = 300
    expression  = "SELECT SUM(Throttles) FROM SCHEMA(\"AWS/Lambda\", FunctionName) WHERE tag.Environment = '${var.environment}'"
  }
}

resource "aws_cloudwatch_metric_alarm" "lambda_duration" {
  alarm_name          = "${var.environment}-lambda-duration"
  alarm_description   = "p95 duration across all Lambda functions tagged Environment=${var.environment} is too high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  threshold           = 10000
  treat_missing_data  = "notBreaching"
  alarm_actions       = [var.sns_topic_arn]
  ok_actions          = [var.sns_topic_arn]

  metric_query {
    id          = "duration"
    return_data = true
    period      = 300
    expression  = "SELECT PERCENTILE(Duration, 95) FROM SCHEMA(\"AWS/Lambda\", FunctionName) WHERE tag.Environment = '${var.environment}'"
  }
}

resource "aws_cloudwatch_metric_alarm" "lambda_concurrent_executions" {
  alarm_name          = "${var.environment}-lambda-concurrency"
  alarm_description   = "Total concurrency across all Lambda functions tagged Environment=${var.environment} is too high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  threshold           = 500
  treat_missing_data  = "notBreaching"
  alarm_actions       = [var.sns_topic_arn]
  ok_actions          = [var.sns_topic_arn]

  metric_query {
    id          = "concurrency"
    return_data = true
    period      = 300
    expression  = "SELECT MAX(ConcurrentExecutions) FROM SCHEMA(\"AWS/Lambda\", FunctionName) WHERE tag.Environment = '${var.environment}'"
  }
}

# -------------------------------------------------------
# API Gateway Alarms (filtered by Environment tag)
# -------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "apigw_5xx" {
  alarm_name          = "${var.environment}-apigw-5xx"
  alarm_description   = "Total 5XX errors across all API Gateways tagged Environment=${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  threshold           = 10
  treat_missing_data  = "notBreaching"
  alarm_actions       = [var.sns_topic_arn]
  ok_actions          = [var.sns_topic_arn]

  metric_query {
    id          = "e5xx"
    return_data = true
    period      = 300
    expression  = "SELECT SUM(5XXError) FROM SCHEMA(\"AWS/ApiGateway\", ApiName) WHERE tag.Environment = '${var.environment}'"
  }
}

resource "aws_cloudwatch_metric_alarm" "apigw_4xx" {
  alarm_name          = "${var.environment}-apigw-4xx"
  alarm_description   = "Total 4XX errors across all API Gateways tagged Environment=${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  threshold           = 50
  treat_missing_data  = "notBreaching"
  alarm_actions       = [var.sns_topic_arn]
  ok_actions          = [var.sns_topic_arn]

  metric_query {
    id          = "e4xx"
    return_data = true
    period      = 300
    expression  = "SELECT SUM(4XXError) FROM SCHEMA(\"AWS/ApiGateway\", ApiName) WHERE tag.Environment = '${var.environment}'"
  }
}

resource "aws_cloudwatch_metric_alarm" "apigw_latency" {
  alarm_name          = "${var.environment}-apigw-latency"
  alarm_description   = "p99 latency across all API Gateways tagged Environment=${var.environment} is too high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  threshold           = 3000
  treat_missing_data  = "notBreaching"
  alarm_actions       = [var.sns_topic_arn]
  ok_actions          = [var.sns_topic_arn]

  metric_query {
    id          = "latency"
    return_data = true
    period      = 300
    expression  = "SELECT PERCENTILE(Latency, 99) FROM SCHEMA(\"AWS/ApiGateway\", ApiName) WHERE tag.Environment = '${var.environment}'"
  }
}

resource "aws_cloudwatch_metric_alarm" "apigw_count_low" {
  alarm_name          = "${var.environment}-apigw-count-low"
  alarm_description   = "Total request count across all API Gateways tagged Environment=${var.environment} dropped unexpectedly"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 3
  threshold           = 1
  treat_missing_data  = "breaching"
  alarm_actions       = [var.sns_topic_arn]
  ok_actions          = [var.sns_topic_arn]

  metric_query {
    id          = "count"
    return_data = true
    period      = 300
    expression  = "SELECT SUM(Count) FROM SCHEMA(\"AWS/ApiGateway\", ApiName) WHERE tag.Environment = '${var.environment}'"
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
  alarm_actions       = [var.sns_topic_arn]
  ok_actions          = [var.sns_topic_arn]

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
  alarm_actions       = [var.sns_topic_arn]
  ok_actions          = [var.sns_topic_arn]

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
  alarm_actions       = [var.sns_topic_arn]
  ok_actions          = [var.sns_topic_arn]

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
  alarm_actions       = [var.sns_topic_arn]
  ok_actions          = [var.sns_topic_arn]

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
  alarm_name          = "${var.environment}-ec2-cpu"
  alarm_description   = "Average CPU across all EC2 instances tagged Environment=${var.environment} is too high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  threshold           = 80
  treat_missing_data  = "notBreaching"
  alarm_actions       = [var.sns_topic_arn]
  ok_actions          = [var.sns_topic_arn]

  metric_query {
    id          = "cpu"
    return_data = true
    period      = 300
    expression  = "SELECT AVG(CPUUtilization) FROM SCHEMA(\"AWS/EC2\", InstanceId) WHERE tag.Environment = '${var.environment}'"
  }
}

resource "aws_cloudwatch_metric_alarm" "ec2_status_check" {
  alarm_name          = "${var.environment}-ec2-status-check"
  alarm_description   = "At least one EC2 instance tagged Environment=${var.environment} has a failed status check"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  threshold           = 0
  treat_missing_data  = "breaching"
  alarm_actions       = [var.sns_topic_arn]
  ok_actions          = [var.sns_topic_arn]

  metric_query {
    id          = "status"
    return_data = true
    period      = 60
    expression  = "SELECT MAX(StatusCheckFailed) FROM SCHEMA(\"AWS/EC2\", InstanceId) WHERE tag.Environment = '${var.environment}'"
  }
}

resource "aws_cloudwatch_metric_alarm" "ec2_network_in" {
  alarm_name          = "${var.environment}-ec2-network-in"
  alarm_description   = "Average inbound network traffic across EC2 instances tagged Environment=${var.environment} is too high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  threshold           = 52428800 # 50 MB
  treat_missing_data  = "notBreaching"
  alarm_actions       = [var.sns_topic_arn]
  ok_actions          = [var.sns_topic_arn]

  metric_query {
    id          = "net_in"
    return_data = true
    period      = 300
    expression  = "SELECT AVG(NetworkIn) FROM SCHEMA(\"AWS/EC2\", InstanceId) WHERE tag.Environment = '${var.environment}'"
  }
}

resource "aws_cloudwatch_metric_alarm" "ec2_disk_read_ops" {
  alarm_name          = "${var.environment}-ec2-disk-read-ops"
  alarm_description   = "Average disk read I/O across EC2 instances tagged Environment=${var.environment} is saturated"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  threshold           = 10000
  treat_missing_data  = "notBreaching"
  alarm_actions       = [var.sns_topic_arn]
  ok_actions          = [var.sns_topic_arn]

  metric_query {
    id          = "disk_reads"
    return_data = true
    period      = 300
    expression  = "SELECT AVG(DiskReadOps) FROM SCHEMA(\"AWS/EC2\", InstanceId) WHERE tag.Environment = '${var.environment}'"
  }
}



