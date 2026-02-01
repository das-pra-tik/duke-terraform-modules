#-----------------------------------------------------------
# Global or/and default variables
#-----------------------------------------------------------
variable "tags" {
  description = "Common tags to apply."
  type        = map(string)
  default     = {}
}

variable "name_prefix" {
  description = "Prefix for resource names."
  type        = string
  default     = "duke"
}

variable "src_s3_prefix" {
  description = "Prefix (folder) inside the source bucket where data is stored."
  type        = string
  default     = "src_data"
}

# variable "dst_s3_prefix" {
#   description = "Prefix (folder) inside the destination bucket where data is stored."
#   type        = string
#   default     = "iceberg"
# }

variable "s3_bucket_versioning" {
  type = bool
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)."
  type        = string
  default     = "sbx"
}

#-----------------------------------------------------------
# Glue Data Catalog database
#-----------------------------------------------------------
variable "glue_catalog_db_name" {
  description = "Glue Data Catalog database name."
  type        = string
}

variable "glue_catalog_db_description" {
  type        = string
  description = "Glue catalog database description."
  default     = null
}

variable "glue_catalog_id" {
  type        = string
  description = "ID of the Glue Catalog to create the database in. If omitted, this defaults to the AWS Account ID."
  default     = null
}

variable "glue_catalog_database_create_table_default_permission" {
  description = "(Optional) Creates a set of default permissions on the table for principals."
  type        = map(string)
  default     = {}
}

# variable "auto_import_schema" {
#   type        = bool
#   description = "If true, rely on crawler to infer schema; if false, create Iceberg table with provided schema."
#   default     = true
# }

variable "catalog_table_name" {
  type        = string
  description = "Name of the table."
  default     = null
}

variable "table_description" {
  type    = string
  default = "Iceberg table"
}

variable "table_type" {
  type    = string
  default = "EXTERNAL_TABLE"
}

variable "iceberg_metadata_location" {
  type        = string
  default     = null
  description = "Metadata location for Iceberg table (required when auto_import_schema = false)."

}

# variable "table_parameters" {
#   type        = map(string)
#   description = "Additional Glue table parameters (must NOT include table_type or metadata_location for Iceberg)."
#   default = {
#     "table_type"                = "ICEBERG"
#     "metadata_location"         = "${local.src_s3_uri}/metadata"
#     "write.format.default"      = "parquet"
#     "write.parquet.compression" = "snappy"
#   }
# }

# variable "tables" {
#   description = "Map of Iceberg tables with their column definitions"
#   type = map(object({
#     columns = list(object({
#       name = string
#       type = string
#     }))
#   }))
# }

variable "table_partitions" {
  type    = list(object({ name = string, type = string }))
  default = []
}

# Classifier toggles
variable "enable_grok_classifier" {
  description = "Enable Grok classifier."
  type        = bool
  default     = false
}

variable "grok_pattern" {
  description = "Grok pattern (required if grok classifier enabled)."
  type        = string
  default     = "%%{GREEDYDATA:raw}"
}

variable "grok_custom_patterns" {
  description = "Custom Grok patterns."
  type        = string
  default     = null
}

variable "enable_xml_classifier" {
  description = "Enable XML classifier."
  type        = bool
  default     = false
}

variable "xml_row_tag" {
  description = "Row tag for XML classifier."
  type        = string
  default     = "row"
}

variable "enable_json_classifier" {
  description = "Enable JSON classifier."
  type        = bool
  default     = false
}

variable "json_path" {
  description = "JSON path for classifier."
  type        = string
  default     = "$"
}

variable "enable_csv_classifier" {
  description = "Enable CSV classifier."
  type        = bool
  default     = false
}

variable "csv_allow_single_column" {
  description = "Allow single column."
  type        = bool
  default     = true
}

variable "csv_contains_header" {
  description = "Option for header: UNKNOWN, PRESENT, ABSENT."
  type        = string
  default     = "UNKNOWN"
}

variable "csv_delimiter" {
  description = "Delimiter for CSV."
  type        = string
  default     = ","
}

variable "csv_quote_symbol" {
  description = "Quote symbol for CSV."
  type        = string
  default     = "\""
}

variable "csv_header" {
  description = "List of column headers (optional)."
  type        = list(string)
  default     = null
}

#---------------------------------------------------
# AWS Glue crawler
#---------------------------------------------------
variable "glue_crawler_name" {
  description = "Name of the crawler."
  type        = string
  default     = null
}

variable "glue_crawler_role_name" {
  description = "(Required) The IAM role friendly name (including path without leading slash), or ARN of an IAM role, used by the crawler to access other resources."
  type        = string
  default     = "AWSGlueServiceRoleDefault"
}

variable "glue_crawler_table_prefix" {
  description = "(Optional) The table prefix used for catalog tables that are created."
  type        = string
  default     = null
}

variable "crawler_schedule" {
  description = "Crawler schedule: ON_DEMAND, EVERY_6_HOURS, or EVERY_12_HOURS."
  type        = string
  default     = "ON_DEMAND"
  validation {
    condition     = contains(["ON_DEMAND", "EVERY_6_HOURS", "EVERY_12_HOURS"], var.crawler_schedule)
    error_message = "crawler_schedule must be one of: ON_DEMAND, EVERY_6_HOURS, EVERY_12_HOURS."
  }
}

variable "recrawl_behavior" {
  description = "Glue recrawl behavior: CRAWL_EVERYTHING, CRAWL_NEW_FOLDERS_ONLY, or CRAWL_EVENT_MODE."
  type        = string
  default     = "CRAWL_EVERYTHING"
  validation {
    condition     = contains(["CRAWL_EVERYTHING", "CRAWL_NEW_FOLDERS_ONLY", "CRAWL_EVENT_MODE"], var.recrawl_behavior)
    error_message = "recrawl_behavior must be one of: CRAWL_EVERYTHING, CRAWL_NEW_FOLDERS_ONLY, CRAWL_EVENT_MODE."
  }
}

variable "schema_change_policy_update" {
  description = "Update behavior for schema changes: UPDATE_IN_DATABASE or LOG."
  type        = string
  default     = "UPDATE_IN_DATABASE"
  validation {
    condition     = contains(["UPDATE_IN_DATABASE", "LOG"], var.schema_change_policy_update)
    error_message = "schema_change_policy_update must be one of: UPDATE_IN_DATABASE, LOG."
  }
}

variable "schema_change_policy_delete" {
  description = "Delete behavior for schema changes: LOG, DELETE_FROM_DATABASE, or DEPRECATE_IN_DATABASE."
  type        = string
  default     = "LOG"
  validation {
    condition     = contains(["LOG", "DELETE_FROM_DATABASE", "DEPRECATE_IN_DATABASE"], var.schema_change_policy_delete)
    error_message = "schema_change_policy_delete must be one of: LOG, DELETE_FROM_DATABASE, DEPRECATE_IN_DATABASE."
  }
}

variable "crawler_lineage_settings" {
  description = "Lineage setting for the crawler: ENABLE or DISABLE."
  type        = string
  default     = "ENABLE"
  validation {
    condition     = contains(["ENABLE", "DISABLE"], var.crawler_lineage_settings)
    error_message = "crawler_lineage_settings must be one of: ENABLE, DISABLE."
  }
}

variable "crawler_configuration" {
  description = "Structured crawler configuration map (will be jsonencoded)."
  type        = any
  default = {
    Version = 1.0
    CrawlerOutput = {
      Partitions = { AddAndUpdateBehavior = "InheritFromTable" }
    }
    Grouping = { TableGroupingPolicy = "CombineCompatibleSchemas" }
  }
}

# variable "crawler_sample_size" {
#   type    = number
#   default = 1
# }

# variable "crawler_event_queue_arn" {
#   type        = string
#   default     = null
#   description = "Optional SQS event queue ARN for crawler notifications."
# }

#---------------------------------------------------
# Cloudwatch Logs and Alarms
#---------------------------------------------------
variable "cw_log_retention_in_days" {
  type    = number
  default = 5
}

variable "enable_cw_alarms" {
  description = "Enable default postgresql CloudWatch metrics/alarms."
  type        = bool
  default     = true
}

variable "time_running_threshold_seconds" {
  description = "Threshold (seconds) for crawler average run time alarm."
  type        = number
  default     = 1800
}

variable "crawler_duration_threshold_seconds" {
  type    = number
  default = 900
}

variable "ok_actions" {
  description = "ARNs for OK actions."
  type        = list(string)
  default     = []
}

variable "alarm_actions" {
  description = "List of ARNs to notify for CloudWatch alarms (e.g., SNS topics)."
  type        = list(string)
  default     = []
}

variable "create_glue_cloudtrail_logs" {
  type = bool
}

variable "cloudtrail_log_group_name" {
  description = "Optional CloudTrail log group name to watch for Glue Data Catalog delete/update events. If empty, catalog alarms are skipped."
  type        = string
}
