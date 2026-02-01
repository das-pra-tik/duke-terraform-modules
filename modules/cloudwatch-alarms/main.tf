resource "aws_cloudwatch_metric_alarm" "this" {
  for_each = { for alarm in var.alarms : alarm.name => alarm }
  # count               = each.value.count != null ? each.value.count : 1
  alarm_name          = each.value.name
  alarm_description   = each.value.description
  comparison_operator = each.value.comparison_operator
  evaluation_periods  = each.value.evaluation_periods
  threshold           = each.value.threshold
  datapoints_to_alarm = each.value.datapoints_to_alarm
  treat_missing_data  = coalesce(each.value.treat_missing_data, "missing")
  unit                = each.value.unit

  # Single metric configuration

  metric_name        = each.value.metric_name
  namespace          = each.value.namespace
  period             = each.value.period
  statistic          = each.value.statistic
  extended_statistic = each.value.extended_statistic
  dimensions         = each.value.dimensions

  # Metric math configuration

  dynamic "metric_query" {
    for_each = coalesce(each.value.metric_queries, [])
    content {
      id          = metric_query.value.id
      label       = metric_query.value.label
      return_data = coalesce(metric_query.value.return_data, true)
      expression  = metric_query.value.expression
      dynamic "metric" {
        for_each = metric_query.value.metric != null ? [metric_query.value.metric] : []
        content {
          namespace   = metric.value.namespace
          metric_name = metric.value.metric_name
          period      = metric.value.period
          stat        = metric.value.stat
          unit        = metric.value.unit
          dimensions  = metric.value.dimensions
        }
      }
    }
  }

  # Actions with defaults
  alarm_actions             = coalesce(each.value.alarm_actions, var.default_alarm_actions)
  ok_actions                = coalesce(each.value.ok_actions, var.default_ok_actions)
  insufficient_data_actions = coalesce(each.value.insufficient_data_actions, var.default_insufficient_data_actions)
  tags                      = merge(var.tags, coalesce(each.value.tags, {}))
}

