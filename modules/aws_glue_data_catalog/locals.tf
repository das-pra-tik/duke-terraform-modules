data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  src_bucket_name       = aws_s3_bucket.duke_src_s3.id
  src_s3_uri            = "s3://${aws_s3_bucket.duke_src_s3.id}/${var.src_s3_prefix}"
  log_retention_in_days = var.cw_log_retention_in_days != null ? var.cw_log_retention_in_days : null
  # dst_bucket_name       = aws_s3_bucket.duke_dst_s3.id
  # dst_s3_uri            = "s3://${aws_s3_bucket.duke_dst_s3.id}/${var.dst_s3_prefix}"
  # crawler_targets = [
  #   {
  #     path = "s3://${module.s3-gluedatacatalog-src.s3_bucket_name}"
  #   }
  # ]
  crawler_schedule_expression = {
    ON_DEMAND = null
    EVERY_6H  = "Cron(0 */6 * * ? *)"
    EVERY_12H = "Cron(0 */12 * * ? *)"
  }[var.crawler_schedule]

  # Defaults for additional alarms (can be adjusted by editing these locals if needed)
  longest_execution_threshold_seconds = 3600 # 1 hour
  succeeded_runs_minimum              = 1
  succeeded_runs_period_seconds       = 86400 # 24 hours
  classifier_enabled = {
    grok = var.enable_grok_classifier
    xml  = var.enable_xml_classifier
    json = var.enable_json_classifier
    csv  = var.enable_csv_classifier
  }
  create_cw_alarms = var.enable_cw_alarms ? 1 : 0
}
