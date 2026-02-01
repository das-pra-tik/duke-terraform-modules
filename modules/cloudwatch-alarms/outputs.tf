output "alarms" {
  description = "Map of created CloudWatch alarms keyed by alarm name."
  value       = aws_cloudwatch_metric_alarm.this
}

output "alarm_arns" {
  description = "Map of alarm ARNs keyed by alarm name."
  value       = { for k, v in aws_cloudwatch_metric_alarm.this : k => v.arn }
}

output "alarm_names" {
  description = "List of all alarm names."
  value       = [for k, v in aws_cloudwatch_metric_alarm.this : v.alarm_name]
}
