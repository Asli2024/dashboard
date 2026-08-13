variable "environment" {
  description = "The Environment for which the dashboard is being created (e.g., dev, staging, prod)."
  type        = string
}


variable "aws_region" {
  description = "The AWS region where the resources are located."
  type        = string
}

variable "amplify_app_ids" {
  description = "List of Amplify app IDs to monitor."
  type        = list(string)
  default     = []
}

variable "sns_topic_arn" {
  description = "ARN of the SNS topic to notify when an alarm fires or recovers."
  type        = string
}

variable "alarm_email" {
  description = "Email address subscribed to the SNS topic for alarm notifications."
  type        = string
}
