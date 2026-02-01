variable "alarms" {
  description = "List of alarm definitions (generic for any AWS metric or metric math)."
  type = list(object({
    count               = optional(number, null)
    name                = string
    description         = optional(string, null)
    comparison_operator = string
    evaluation_periods  = number
    threshold           = number
    datapoints_to_alarm = optional(number, null)
    treat_missing_data  = optional(string, "missing")
    unit                = optional(string, null)

    # Single metric configuration
    metric_name        = optional(string, null)
    namespace          = optional(string, null)
    period             = optional(number, null)
    statistic          = optional(string, null)
    extended_statistic = optional(string, null)
    dimensions         = optional(map(string), null)

    # Metric math configuration
    metric_queries = optional(list(object({
      id          = string
      label       = optional(string, null)
      return_data = optional(bool, true)
      expression  = optional(string, null)
      metric = optional(object({
        namespace   = string
        metric_name = string
        period      = number
        stat        = string
        unit        = optional(string, null)
        dimensions  = optional(map(string), null)
      }), null)
    })), [])

    # Actions
    alarm_actions             = optional(list(string), null)
    ok_actions                = optional(list(string), null)
    insufficient_data_actions = optional(list(string), null)
    tags                      = optional(map(string), {})
  }))

  validation {
    condition = alltrue([
      for alarm in var.alarms :
      alarm.datapoints_to_alarm == null ? true : alarm.datapoints_to_alarm >= 1
    ])
    error_message = "datapoints_to_alarm must be null or >= 1."
  }

  validation {
    condition = alltrue([
      for alarm in var.alarms :
      alarm.datapoints_to_alarm == null ? true : alarm.datapoints_to_alarm <= alarm.evaluation_periods
    ])
    error_message = "datapoints_to_alarm must be <= evaluation_periods."
  }

  validation {
    condition = alltrue([
      for alarm in var.alarms :
      (alarm.metric_name != null && alarm.namespace != null) || length(coalesce(alarm.metric_queries, [])) > 0
    ])
    error_message = "Each alarm must have either (metric_name + namespace) or metric_queries defined."
  }

  validation {
    condition = alltrue([
      for alarm in var.alarms :
      alarm.unit == null ? true : contains([
        "Seconds",
        "Microseconds",
        "Milliseconds",
        "Bytes",
        "Kilobytes",
        "Megabytes",
        "Gigabytes",
        "Terabytes",
        "Bits",
        "Kilobits",
        "Megabits",
        "Gigabits",
        "Terabits",
        "Percent",
        "Count",
        "Bytes/Second",
        "Kilobytes/Second",
        "Megabytes/Second",
        "Gigabytes/Second",
        "Terabytes/Second",
        "Bits/Second",
        "Kilobits/Second",
        "Megabits/Second",
        "Gigabits/Second",
        "Terabits/Second",
        "Count/Second",
        "None"
      ], alarm.unit)
    ])
    error_message = "unit must be null or a valid CloudWatch unit (Seconds, Percent, Count, Bytes, etc.)."
  }

  validation {
    condition = alltrue([
      for alarm in var.alarms :
      contains([
        "GreaterThanOrEqualToThreshold",
        "GreaterThanThreshold",
        "LessThanThreshold",
        "LessThanOrEqualToThreshold",
        "LessThanLowerOrGreaterThanUpperThreshold",
        "LessThanLowerThreshold",
        "GreaterThanUpperThreshold"
      ], alarm.comparison_operator)
    ])
    error_message = "comparison_operator must be a valid CloudWatch comparison operator."
  }

  validation {
    condition = alltrue([
      for alarm in var.alarms :
      alarm.treat_missing_data == null ? true : contains([
        "breaching",
        "notBreaching",
        "ignore",
        "missing"
      ], alarm.treat_missing_data)
    ])
    error_message = "treat_missing_data must be one of: breaching, notBreaching, ignore, missing."
  }
}

variable "default_alarm_actions" {
  description = "Default alarm actions (e.g., SNS topic ARNs)."
  type        = list(string)
  default     = []
}

variable "default_ok_actions" {
  description = "Default OK actions."
  type        = list(string)
  default     = []
}

variable "default_insufficient_data_actions" {
  description = "Default insufficient data actions."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Common tags for all alarms."
  type        = map(string)
  default     = {}
}
