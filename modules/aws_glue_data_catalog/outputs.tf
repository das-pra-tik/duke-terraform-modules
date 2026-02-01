output "source_bucket_name" {
  value       = aws_s3_bucket.duke_src_s3.bucket
  description = "Name of the created source bucket."
}

output "source_bucket_arn" {
  value       = aws_s3_bucket.duke_src_s3.arn
  description = "Name of the created source bucket."
}

output "source_prefix" {
  value       = var.src_s3_prefix
  description = "Prefix used for the source data."
}

# output "destination_bucket_name" {
#   value       = module.s3-gluedatacatalog-dst.s3_bucket_name
#   description = "Name of the created source bucket."
# }

# output "destination_bucket_arn" {
#   value       = module.s3-gluedatacatalog-dst.s3_bucket_arn
#   description = "Name of the created source bucket."
# }

# output "destination_prefix" {
#   value       = var.dst_s3_prefix
#   description = "Prefix used for the source data."
# }

output "glue_catalog_database_name" {
  value       = aws_glue_catalog_database.this.name
  description = "Glue database name."
}

output "glue_catalog_database_arn" {
  value       = aws_glue_catalog_database.this.arn
  description = "Glue database name."
}

output "glue_crawler_name" {
  value       = aws_glue_crawler.this.name
  description = "Glue crawler name."
}

output "glue_crawler_role_arn" {
  value       = aws_iam_role.glue_role.arn
  description = "IAM role ARN used by the Glue crawler."
}

output "glue_cw_alarms" {
  description = "Map of Glue CloudWatch alarm resources."
  value       = length(module.glue_cw_alarms) > 0 ? module.glue_cw_alarms[0].alarms : {}
}

output "glue_cw_alarm_arns" {
  description = "Map of Glue CloudWatch alarm ARNs."
  value       = length(module.glue_cw_alarms) > 0 ? module.glue_cw_alarms[0].alarm_arns : {}
}

output "glue_cw_alarm_names" {
  description = "List of Glue CloudWatch alarm names."
  value       = length(module.glue_cw_alarms) > 0 ? module.glue_cw_alarms[0].alarm_names : []
}
