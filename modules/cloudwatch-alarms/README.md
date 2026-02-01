# AWS CloudWatch Alarms Terraform Module

A reusable, generic Terraform module for creating AWS CloudWatch metric alarms for any AWS service or custom metrics. This module supports single metrics, metric math expressions, and anomaly detection.

## Table of Contents

- [Features](#features)
- [Requirements](#requirements)
- [Usage](#usage)
  - [Basic Example](#basic-example)
  - [Metric Math Example](#metric-math-example)
  - [Multiple Resources Example](#multiple-resources-example)
- [Supported AWS Services](#supported-aws-services)
- [Inputs](#inputs)
  - [Alarm Object Schema](#alarm-object-schema)
  - [Metric Query Object Schema](#metric-query-object-schema)
- [Outputs](#outputs)
- [Common Alarm Patterns](#common-alarm-patterns)
  - [EC2 Alarms](#ec2-alarms)
  - [RDS Alarms](#rds-alarms)
  - [Lambda Alarms](#lambda-alarms)
  - [ALB Alarms](#alb-alarms)
  - [SQS Alarms](#sqs-alarms)
  - [DynamoDB Alarms](#dynamodb-alarms)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)

---

## Features

- ✅ **Universal Compatibility** - Works with any AWS service metrics (EC2, RDS, Lambda, ALB, SQS, DynamoDB, etc.)
- ✅ **Custom Metrics Support** - Create alarms on custom application metrics
- ✅ **Metric Math** - Support for metric math expressions and complex calculations
- ✅ **Flexible Actions** - Configure alarm, OK, and insufficient data actions (SNS, Lambda, Auto Scaling, etc.)
- ✅ **Sensible Defaults** - Pre-configured defaults with full override capability
- ✅ **Validation** - Built-in input validation to catch configuration errors early
- ✅ **Tagging** - Global and per-alarm tagging support
- ✅ **Terraform Native** - Clean, idiomatic Terraform code following best practices

---

## Requirements

| Name | Version |
|------|---------|
| Terraform | >= 1.5.0 |
| AWS Provider | >= 5.0 |

---

## Usage

### Basic Example

Create a simple CPU utilization alarm for an EC2 instance: 

```hcl
module "cloudwatch_alarms" {
  source = "./modules/cloudwatch-alarms"

  default_alarm_actions = ["arn:aws:sns:us-east-1:123456789012:alerts"]

  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }

  alarms = [
    {
      name                = "prod-ec2-cpu-high"
      description         = "EC2 CPU utilization exceeds 80% for 5 minutes"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 1
      threshold           = 80
      period              = 300
      statistic           = "Average"
      metric_name         = "CPUUtilization"
      namespace           = "AWS/EC2"
      dimensions = {
        InstanceId = "i-1234567890abcdef0"
      }
      treat_missing_data = "notBreaching"
    }
  ]
}
```

### Metric Math Example

Create an alarm based on a calculated metric (e.g., ALB 5xx error rate percentage):

```hcl
module "alb_error_rate_alarm" {
  source = "./modules/cloudwatch-alarms"

  default_alarm_actions = ["arn:aws:sns:us-east-1:123456789012:alerts"]

  alarms = [
    {
      name                = "prod-alb-5xx-error-rate"
      description         = "ALB 5xx error rate exceeds 1% of total requests"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 3
      threshold           = 1
      treat_missing_data  = "notBreaching"

      metric_queries = [
        {
          id    = "m1"
          label = "5XX Errors"
          metric = {
            namespace   = "AWS/ApplicationELB"
            metric_name = "HTTPCode_ELB_5XX_Count"
            period      = 300
            stat        = "Sum"
            dimensions = {
              LoadBalancer = "app/my-alb/1234567890abcdef"
            }
          }
        },
        {
          id    = "m2"
          label = "Total Requests"
          metric = {
            namespace   = "AWS/ApplicationELB"
            metric_name = "RequestCount"
            period      = 300
            stat        = "Sum"
            dimensions = {
              LoadBalancer = "app/my-alb/1234567890abcdef"
            }
          }
        },
        {
          id          = "e1"
          label       = "5XX Error Rate (%)"
          expression  = "IF(m2 > 0, 100 * m1 / m2, 0)"
          return_data = true
        }
      ]
    }
  ]
}
```

### Multiple Resources Example

Create alarms for multiple EC2 instances using `for_each`:

```hcl
locals {
  ec2_instances = {
    web-server-1 = "i-1234567890abcdef0"
    web-server-2 = "i-0987654321fedcba0"
    api-server-1 = "i-abcdef1234567890a"
  }

  ec2_alarms = flatten([
    for name, instance_id in local.ec2_instances : [
      {
        name                = "${name}-cpu-high"
        description         = "CPU utilization for ${name} exceeds 80%"
        comparison_operator = "GreaterThanThreshold"
        evaluation_periods  = 2
        threshold           = 80
        period              = 300
        statistic           = "Average"
        metric_name         = "CPUUtilization"
        namespace           = "AWS/EC2"
        dimensions          = { InstanceId = instance_id }
        treat_missing_data  = "notBreaching"
        tags                = { Server = name }
      },
      {
        name                = "${name}-memory-high"
        description         = "Memory utilization for ${name} exceeds 85%"
        comparison_operator = "GreaterThanThreshold"
        evaluation_periods  = 2
        threshold           = 85
        period              = 300
        statistic           = "Average"
        metric_name         = "mem_used_percent"
        namespace           = "CWAgent"
        dimensions          = { InstanceId = instance_id }
        treat_missing_data  = "notBreaching"
        tags                = { Server = name }
      }
    ]
  ])
}

module "ec2_alarms" {
  source = "./modules/cloudwatch-alarms"

  default_alarm_actions = [aws_sns_topic. alerts.arn]
  tags = {
    Environment = "production"
    Service     = "web"
  }

  alarms = local.ec2_alarms
}
```

---

## Supported AWS Services

This module works with **any AWS service** that publishes metrics to CloudWatch.  Common services include:

| Service | Namespace | Common Metrics |
|---------|-----------|----------------|
| EC2 | `AWS/EC2` | CPUUtilization, NetworkIn, NetworkOut, DiskReadOps |
| RDS | `AWS/RDS` | CPUUtilization, FreeableMemory, ReadIOPS, WriteIOPS |
| Lambda | `AWS/Lambda` | Invocations, Errors, Duration, Throttles, ConcurrentExecutions |
| ALB | `AWS/ApplicationELB` | RequestCount, HTTPCode_ELB_5XX_Count, TargetResponseTime |
| NLB | `AWS/NetworkELB` | ActiveFlowCount, ProcessedBytes, TCP_Target_Reset_Count |
| API Gateway | `AWS/ApiGateway` | Count, Latency, 4XXError, 5XXError |
| SQS | `AWS/SQS` | NumberOfMessagesReceived, ApproximateNumberOfMessagesVisible |
| SNS | `AWS/SNS` | NumberOfMessagesPublished, NumberOfNotificationsFailed |
| DynamoDB | `AWS/DynamoDB` | ConsumedReadCapacityUnits, ThrottledRequests |
| ECS | `AWS/ECS` | CPUUtilization, MemoryUtilization |
| EKS | `AWS/ContainerInsights` | pod_cpu_utilization, pod_memory_utilization |
| ElastiCache | `AWS/ElastiCache` | CPUUtilization, CacheHitRate, Evictions |
| Redshift | `AWS/Redshift` | CPUUtilization, PercentageDiskSpaceUsed |
| S3 | `AWS/S3` | BucketSizeBytes, NumberOfObjects |
| CloudFront | `AWS/CloudFront` | Requests, BytesDownloaded, 4xxErrorRate |
| Custom | `Custom/YourApp` | Any custom metrics you publish |

---

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `alarms` | List of alarm definitions | `list(object)` | n/a | ✅ |
| `default_alarm_actions` | Default actions when alarm triggers (e.g., SNS ARNs) | `list(string)` | `[]` | ❌ |
| `default_ok_actions` | Default actions when alarm returns to OK | `list(string)` | `[]` | ❌ |
| `default_insufficient_data_actions` | Default actions for insufficient data | `list(string)` | `[]` | ❌ |
| `tags` | Tags applied to all alarms | `map(string)` | `{}` | ❌ |

### Alarm Object Schema

Each alarm in the `alarms` list supports the following attributes:

| Attribute | Description | Type | Required |
|-----------|-------------|------|: --------:|
| `name` | Unique name for the alarm | `string` | ✅ |
| `description` | Human-readable alarm description | `string` | ❌ |
| `comparison_operator` | Comparison operator for threshold | `string` | ✅ |
| `evaluation_periods` | Number of periods to evaluate | `number` | ✅ |
| `threshold` | Threshold value for the alarm | `number` | ✅ |
| `datapoints_to_alarm` | Datapoints required to trigger alarm | `number` | ❌ |
| `treat_missing_data` | How to treat missing data | `string` | ❌ |
| `unit` | Unit for the metric | `string` | ❌ |
| `metric_name` | Name of the metric (single metric mode) | `string` | ❌* |
| `namespace` | Metric namespace (single metric mode) | `string` | ❌* |
| `period` | Period in seconds (single metric mode) | `number` | ❌* |
| `statistic` | Statistic to use (Average, Sum, etc.) | `string` | ❌ |
| `extended_statistic` | Percentile statistic (e.g., p99) | `string` | ❌ |
| `dimensions` | Metric dimensions | `map(string)` | ❌ |
| `metric_queries` | Metric math queries (advanced mode) | `list(object)` | ❌* |
| `alarm_actions` | Override default alarm actions | `list(string)` | ❌ |
| `ok_actions` | Override default OK actions | `list(string)` | ❌ |
| `insufficient_data_actions` | Override default insufficient data actions | `list(string)` | ❌ |
| `tags` | Per-alarm tags (merged with global) | `map(string)` | ❌ |

> **Note:** Either (`metric_name` + `namespace`) OR `metric_queries` must be provided. 

#### Valid Comparison Operators

- `GreaterThanOrEqualToThreshold`
- `GreaterThanThreshold`
- `LessThanThreshold`
- `LessThanOrEqualToThreshold`
- `LessThanLowerOrGreaterThanUpperThreshold`
- `LessThanLowerThreshold`
- `GreaterThanUpperThreshold`

#### Valid treat_missing_data Values

| Value | Description |
|-------|-------------|
| `missing` | (Default) Alarm state remains unchanged |
| `notBreaching` | Treat missing data as within threshold |
| `breaching` | Treat missing data as exceeding threshold |
| `ignore` | Current state is maintained |

#### Valid Units

`Seconds`, `Microseconds`, `Milliseconds`, `Bytes`, `Kilobytes`, `Megabytes`, `Gigabytes`, `Terabytes`, `Bits`, `Kilobits`, `Megabits`, `Gigabits`, `Terabits`, `Percent`, `Count`, `Bytes/Second`, `Kilobytes/Second`, `Megabytes/Second`, `Gigabytes/Second`, `Terabytes/Second`, `Bits/Second`, `Kilobits/Second`, `Megabits/Second`, `Gigabits/Second`, `Terabits/Second`, `Count/Second`, `None`

### Metric Query Object Schema

For metric math expressions, each metric query supports: 

| Attribute | Description | Type | Required |
|-----------|-------------|------|: --------:|
| `id` | Unique ID for the metric (e.g., m1, e1) | `string` | ✅ |
| `label` | Human-readable label | `string` | ❌ |
| `return_data` | Whether this metric is used for the alarm | `bool` | ❌ |
| `expression` | Metric math expression | `string` | ❌ |
| `metric` | Metric definition object | `object` | ❌ |

#### Metric Object (within metric_query)

| Attribute | Description | Type | Required |
|-----------|-------------|------|:--------:|
| `namespace` | AWS metric namespace | `string` | ✅ |
| `metric_name` | Name of the metric | `string` | ✅ |
| `period` | Period in seconds | `number` | ✅ |
| `stat` | Statistic (Average, Sum, Maximum, etc.) | `string` | ✅ |
| `unit` | Metric unit | `string` | ❌ |
| `dimensions` | Metric dimensions | `map(string)` | ❌ |

---

## Outputs

| Name | Description |
|------|-------------|
| `alarms` | Map of all created CloudWatch alarm resources |
| `alarm_arns` | Map of alarm ARNs keyed by alarm name |
| `alarm_names` | List of all created alarm names |

### Usage Examples

```hcl
# Get all alarm ARNs
output "all_alarm_arns" {
  value = module.cloudwatch_alarms.alarm_arns
}

# Get a specific alarm ARN
output "cpu_alarm_arn" {
  value = module.cloudwatch_alarms.alarm_arns["prod-ec2-cpu-high"]
}

# Get alarm details
output "cpu_alarm_details" {
  value = module.cloudwatch_alarms.alarms["prod-ec2-cpu-high"]
}
```

---

## Common Alarm Patterns

### EC2 Alarms

```hcl
alarms = [
  # CPU High
  {
    name                = "ec2-cpu-high"
    description         = "EC2 CPU > 80% for 10 minutes"
    comparison_operator = "GreaterThanThreshold"
    evaluation_periods  = 2
    threshold           = 80
    period              = 300
    statistic           = "Average"
    metric_name         = "CPUUtilization"
    namespace           = "AWS/EC2"
    dimensions          = { InstanceId = "i-1234567890abcdef0" }
    treat_missing_data  = "notBreaching"
  },

  # Status Check Failed
  {
    name                = "ec2-status-check-failed"
    description         = "EC2 instance or system status check failed"
    comparison_operator = "GreaterThanThreshold"
    evaluation_periods  = 2
    threshold           = 0
    period              = 60
    statistic           = "Maximum"
    metric_name         = "StatusCheckFailed"
    namespace           = "AWS/EC2"
    dimensions          = { InstanceId = "i-1234567890abcdef0" }
    treat_missing_data  = "breaching"
  },

  # Network In High (possible attack or spike)
  {
    name                = "ec2-network-in-high"
    description         = "EC2 network ingress > 1GB in 5 minutes"
    comparison_operator = "GreaterThanThreshold"
    evaluation_periods  = 1
    threshold           = 1073741824  # 1 GB in bytes
    period              = 300
    statistic           = "Sum"
    metric_name         = "NetworkIn"
    namespace           = "AWS/EC2"
    dimensions          = { InstanceId = "i-1234567890abcdef0" }
    treat_missing_data  = "notBreaching"
  }
]
```

### RDS Alarms

```hcl
alarms = [
  # CPU High
  {
    name                = "rds-cpu-high"
    description         = "RDS CPU > 80% for 15 minutes"
    comparison_operator = "GreaterThanThreshold"
    evaluation_periods  = 3
    threshold           = 80
    period              = 300
    statistic           = "Average"
    metric_name         = "CPUUtilization"
    namespace           = "AWS/RDS"
    dimensions          = { DBInstanceIdentifier = "my-database" }
    treat_missing_data  = "notBreaching"
  },

  # Free Storage Space Low
  {
    name                = "rds-storage-low"
    description         = "RDS free storage < 10GB"
    comparison_operator = "LessThanThreshold"
    evaluation_periods  = 1
    threshold           = 10737418240  # 10 GB in bytes
    period              = 300
    statistic           = "Average"
    metric_name         = "FreeStorageSpace"
    namespace           = "AWS/RDS"
    dimensions          = { DBInstanceIdentifier = "my-database" }
    treat_missing_data  = "notBreaching"
  },

  # Database Connections High
  {
    name                = "rds-connections-high"
    description         = "RDS connections > 100"
    comparison_operator = "GreaterThanThreshold"
    evaluation_periods  = 2
    threshold           = 100
    period              = 300
    statistic           = "Average"
    metric_name         = "DatabaseConnections"
    namespace           = "AWS/RDS"
    dimensions          = { DBInstanceIdentifier = "my-database" }
    treat_missing_data  = "notBreaching"
  },

  # Read Latency High
  {
    name                = "rds-read-latency-high"
    description         = "RDS read latency > 20ms"
    comparison_operator = "GreaterThanThreshold"
    evaluation_periods  = 3
    threshold           = 0. 020  # 20ms in seconds
    period              = 300
    statistic           = "Average"
    metric_name         = "ReadLatency"
    namespace           = "AWS/RDS"
    dimensions          = { DBInstanceIdentifier = "my-database" }
    treat_missing_data  = "notBreaching"
  }
]
```

### Lambda Alarms

```hcl
alarms = [
  # Error Rate High
  {
    name                = "lambda-errors-high"
    description         = "Lambda error count > 10 in 5 minutes"
    comparison_operator = "GreaterThanThreshold"
    evaluation_periods  = 1
    threshold           = 10
    period              = 300
    statistic           = "Sum"
    metric_name         = "Errors"
    namespace           = "AWS/Lambda"
    dimensions          = { FunctionName = "my-function" }
    treat_missing_data  = "notBreaching"
  },

  # Duration High (approaching timeout)
  {
    name                = "lambda-duration-high"
    description         = "Lambda p99 duration > 25 seconds"
    comparison_operator = "GreaterThanThreshold"
    evaluation_periods  = 3
    threshold           = 25000  # milliseconds
    period              = 300
    extended_statistic  = "p99"
    metric_name         = "Duration"
    namespace           = "AWS/Lambda"
    dimensions          = { FunctionName = "my-function" }
    treat_missing_data  = "notBreaching"
  },

  # Throttles
  {
    name                = "lambda-throttles"
    description         = "Lambda throttled > 5 times in 5 minutes"
    comparison_operator = "GreaterThanThreshold"
    evaluation_periods  = 1
    threshold           = 5
    period              = 300
    statistic           = "Sum"
    metric_name         = "Throttles"
    namespace           = "AWS/Lambda"
    dimensions          = { FunctionName = "my-function" }
    treat_missing_data  = "notBreaching"
  },

  # Concurrent Executions High
  {
    name                = "lambda-concurrency-high"
    description         = "Lambda concurrent executions > 900 (near 1000 limit)"
    comparison_operator = "GreaterThanThreshold"
    evaluation_periods  = 1
    threshold           = 900
    period              = 60
    statistic           = "Maximum"
    metric_name         = "ConcurrentExecutions"
    namespace           = "AWS/Lambda"
    dimensions          = { FunctionName = "my-function" }
    treat_missing_data  = "notBreaching"
  }
]
```

### ALB Alarms

```hcl
alarms = [
  # Target 5XX Errors
  {
    name                = "alb-target-5xx-high"
    description         = "ALB target 5XX errors > 50 in 5 minutes"
    comparison_operator = "GreaterThanThreshold"
    evaluation_periods  = 1
    threshold           = 50
    period              = 300
    statistic           = "Sum"
    metric_name         = "HTTPCode_Target_5XX_Count"
    namespace           = "AWS/ApplicationELB"
    dimensions = {
      LoadBalancer = "app/my-alb/1234567890abcdef"
    }
    treat_missing_data = "notBreaching"
  },

  # Response Time High
  {
    name                = "alb-response-time-high"
    description         = "ALB target response time > 2 seconds"
    comparison_operator = "GreaterThanThreshold"
    evaluation_periods  = 3
    threshold           = 2
    period              = 300
    statistic           = "Average"
    metric_name         = "TargetResponseTime"
    namespace           = "AWS/ApplicationELB"
    dimensions = {
      LoadBalancer = "app/my-alb/1234567890abcdef"
    }
    treat_missing_data = "notBreaching"
  },

  # Unhealthy Hosts
  {
    name                = "alb-unhealthy-hosts"
    description         = "ALB has unhealthy targets"
    comparison_operator = "GreaterThanThreshold"
    evaluation_periods  = 2
    threshold           = 0
    period              = 300
    statistic           = "Average"
    metric_name         = "UnHealthyHostCount"
    namespace           = "AWS/ApplicationELB"
    dimensions = {
      LoadBalancer = "app/my-alb/1234567890abcdef"
      TargetGroup  = "targetgroup/my-tg/1234567890abcdef"
    }
    treat_missing_data = "notBreaching"
  },

  # 5XX Error Rate (using metric math)
  {
    name                = "alb-5xx-error-rate"
    description         = "ALB 5XX error rate > 5%"
    comparison_operator = "GreaterThanThreshold"
    evaluation_periods  = 3
    threshold           = 5
    treat_missing_data  = "notBreaching"
    metric_queries = [
      {
        id    = "errors"
        label = "5XX Errors"
        metric = {
          namespace   = "AWS/ApplicationELB"
          metric_name = "HTTPCode_ELB_5XX_Count"
          period      = 300
          stat        = "Sum"
          dimensions  = { LoadBalancer = "app/my-alb/1234567890abcdef" }
        }
      },
      {
        id    = "requests"
        label = "Total Requests"
        metric = {
          namespace   = "AWS/ApplicationELB"
          metric_name = "RequestCount"
          period      = 300
          stat        = "Sum"
          dimensions  = { LoadBalancer = "app/my-alb/1234567890abcdef" }
        }
      },
      {
        id          = "error_rate"
        label       = "Error Rate %"
        expression  = "IF(requests > 0, 100 * errors / requests, 0)"
        return_data = true
      }
    ]
  }
]
```

### SQS Alarms

```hcl
alarms = [
  # Queue Depth High
  {
    name                = "sqs-queue-depth-high"
    description         = "SQS queue has > 1000 messages"
    comparison_operator = "GreaterThanThreshold"
    evaluation_periods  = 3
    threshold           = 1000
    period              = 300
    statistic           = "Average"
    metric_name         = "ApproximateNumberOfMessagesVisible"
    namespace           = "AWS/SQS"
    dimensions          = { QueueName = "my-queue" }
    treat_missing_data  = "notBreaching"
  },

  # Dead Letter Queue Has Messages
  {
    name                = "sqs-dlq-not-empty"
    description         = "Dead letter queue has messages"
    comparison_operator = "GreaterThanThreshold"
    evaluation_periods  = 1
    threshold           = 0
    period              = 300
    statistic           = "Sum"
    metric_name         = "ApproximateNumberOfMessagesVisible"
    namespace           = "AWS/SQS"
    dimensions          = { QueueName = "my-queue-dlq" }
    treat_missing_data  = "notBreaching"
  },

  # Message Age High (processing delay)
  {
    name                = "sqs-message-age-high"
    description         = "SQS oldest message age > 1 hour"
    comparison_operator = "GreaterThanThreshold"
    evaluation_periods  = 1
    threshold           = 3600  # 1 hour in seconds
    period              = 300
    statistic           = "Maximum"
    metric_name         = "ApproximateAgeOfOldestMessage"
    namespace           = "AWS/SQS"
    dimensions          = { QueueName = "my-queue" }
    treat_missing_data  = "notBreaching"
  }
]
```

### DynamoDB Alarms

```hcl
alarms = [
  # Read Throttle Events
  {
    name                = "dynamodb-read-throttle"
    description         = "DynamoDB read requests throttled"
    comparison_operator = "GreaterThanThreshold"
    evaluation_periods  = 1
    threshold           = 0
    period              = 300
    statistic           = "Sum"
    metric_name         = "ReadThrottleEvents"
    namespace           = "AWS/DynamoDB"
    dimensions          = { TableName = "my-table" }
    treat_missing_data  = "notBreaching"
  },

  # Write Throttle Events
  {
    name                = "dynamodb-write-throttle"
    description         = "DynamoDB write requests throttled"
    comparison_operator = "GreaterThanThreshold"
    evaluation_periods  = 1
    threshold           = 0
    period              = 300
    statistic           = "Sum"
    metric_name         = "WriteThrottleEvents"
    namespace           = "AWS/DynamoDB"
    dimensions          = { TableName = "my-table" }
    treat_missing_data  = "notBreaching"
  },

  # Consumed Read Capacity High
  {
    name                = "dynamodb-read-capacity-high"
    description         = "DynamoDB consumed read capacity > 80% of provisioned"
    comparison_operator = "GreaterThanThreshold"
    evaluation_periods  = 3
    threshold           = 80
    treat_missing_data  = "notBreaching"
    metric_queries = [
      {
        id = "consumed"
        metric = {
          namespace   = "AWS/DynamoDB"
          metric_name = "ConsumedReadCapacityUnits"
          period      = 300
          stat        = "Sum"
          dimensions  = { TableName = "my-table" }
        }
      },
      {
        id = "provisioned"
        metric = {
          namespace   = "AWS/DynamoDB"
          metric_name = "ProvisionedReadCapacityUnits"
          period      = 300
          stat        = "Average"
          dimensions  = { TableName = "my-table" }
        }
      },
      {
        id          = "utilization"
        expression  = "100 * consumed / (provisioned * 300)"
        label       = "Read Capacity Utilization %"
        return_data = true
      }
    ]
  },

  # System Errors
  {
    name                = "dynamodb-system-errors"
    description         = "DynamoDB system errors detected"
    comparison_operator = "GreaterThanThreshold"
    evaluation_periods  = 1
    threshold           = 0
    period              = 60
    statistic           = "Sum"
    metric_name         = "SystemErrors"
    namespace           = "AWS/DynamoDB"
    dimensions          = { TableName = "my-table" }
    treat_missing_data  = "notBreaching"
  }
]
```

---

## Best Practices

### 1. Use Meaningful Alarm Names

```hcl
# ✅ Good - includes environment, resource, and metric
name = "prod-api-server-cpu-high"

# ❌ Bad - too generic
name = "cpu-alarm"
```

### 2. Set Appropriate Evaluation Periods

```hcl
# For transient spikes (ignore brief spikes)
evaluation_periods  = 3
datapoints_to_alarm = 2  # 2 out of 3 periods must breach

# For critical issues (react quickly)
evaluation_periods = 1
period             = 60
```

### 3. Use `treat_missing_data` Wisely

```hcl
# For metrics that may not exist when healthy (e.g., error counts)
treat_missing_data = "notBreaching"

# For metrics that should always exist (e.g., instance status)
treat_missing_data = "breaching"
```

### 4. Leverage Metric Math for Rates/Percentages

```hcl
# Calculate error rate instead of absolute count
metric_queries = [
  { id = "errors", metric = { ...  } },
  { id = "total", metric = { ... } },
  { id = "rate", expression = "100 * errors / total", return_data = true }
]
```

### 5. Tag Alarms for Organization

```hcl
tags = {
  Environment = "production"
  Service     = "payment-api"
  Team        = "platform"
  CostCenter  = "engineering"
}
```

### 6. Use Different Actions for Severity

```hcl
# Critical alarms - page on-call
alarm_actions = [aws_sns_topic. pagerduty. arn]

# Warning alarms - Slack notification only
alarm_actions = [aws_sns_topic.slack_warnings.arn]
```

---

## Troubleshooting

### Alarm Stays in INSUFFICIENT_DATA

**Cause:** Metric doesn't exist or dimensions are incorrect. 

**Solution:**
1.  Verify metric exists in CloudWatch console
2. Check dimension names and values match exactly
3. Ensure the resource is active and generating metrics

```hcl
# Verify dimensions match exactly
dimensions = {
  InstanceId = "i-1234567890abcdef0"  # Must match exactly
}
```

### Alarm Not Triggering

**Cause:** Threshold, period, or evaluation settings too lenient.

**Solution:**
1. Check CloudWatch console for actual metric values
2. Adjust threshold to match observed values
3. Reduce evaluation periods for faster detection

### Metric Math Expression Errors

**Cause:** Invalid expression syntax or undefined metric IDs.

**Solution:**
1. Ensure all referenced IDs (m1, m2, etc.) are defined
2. Use `IF()` to handle division by zero
3. Only one metric query should have `return_data = true`

```hcl
# Handle division by zero
expression = "IF(m2 > 0, 100 * m1 / m2, 0)"
```

### Validation Errors

**Cause:** Invalid values for comparison_operator, unit, or treat_missing_data. 

**Solution:** Refer to the [valid values](#valid-comparison-operators) section above.

---

## Contributing

Contributions are welcome! Please submit pull requests with: 

1. Clear description of changes
2. Updated documentation
3. Test cases if applicable

---

## License

This module is released under the MIT License.  See [LICENSE](LICENSE) for details.

---

## Authors

Maintained by your infrastructure team.  For questions or support, contact:  infrastructure@yourcompany.com