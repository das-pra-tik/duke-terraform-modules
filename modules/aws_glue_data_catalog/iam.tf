# IAM role for Glue crawler
/*
data "aws_iam_policy_document" "assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["glue.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "crawler" {
  name               = "${var.name_prefix}-glue-crawler-role-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.assume.json
  tags               = var.tags
}

data "aws_iam_policy_document" "crawler" {
  statement {
    actions = [
      "s3:GetObject",
      "s3:ListBucket",
      "s3:GetBucketLocation"
    ]
    resources = [
      "${module.s3-gluedatacatalog-src.s3_bucket_arn}",
      "${module.s3-gluedatacatalog-src.s3_bucket_arn}/${var.src_s3_prefix}*"
    ]
  }

  statement {
    actions = [
      "glue:GetDatabase",
      "glue:GetDatabases",
      "glue:UpdateDatabase",
      "glue:CreateTable",
      "glue:UpdateTable",
      "glue:GetTable",
      "glue:GetTables",
      "glue:BatchCreatePartition",
      "glue:BatchUpdatePartition",
      "glue:GetPartition",
      "glue:GetPartitions"
    ]
    resources = ["*"]
  }

  statement {
    actions   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["arn:aws:logs:*:*:*"]
  }

  statement {
    actions   = ["cloudwatch:PutMetricData"]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "cloudwatch:namespace"
      values   = ["GlueCrawlerCustom"]
    }
  }
}

resource "aws_iam_policy" "crawler" {
  name   = "${var.name_prefix}-glue-crawler-role-${var.environment}"
  policy = data.aws_iam_policy_document.crawler.json
}

resource "aws_iam_role_policy_attachment" "crawler" {
  role       = aws_iam_role.crawler.name
  policy_arn = aws_iam_policy.crawler.arn
}
*/

resource "aws_iam_role" "glue_role" {
  name               = var.glue_crawler_role_name
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "glue.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "glue_service" {
  role       = aws_iam_role.glue_role.id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

resource "aws_iam_role_policy" "glue_policy" {
  name   = "glue_policy"
  role   = aws_iam_role.glue_role.id
  policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Effect": "Allow",
     "Action": [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket",
      "s3:GetBucketLocation"
     ],
     "Resource": [
     "${aws_s3_bucket.duke_src_s3.arn}",
     "${aws_s3_bucket.duke_src_s3.arn}/*"
     ]
   },
   {
     "Effect": "Allow",
     "Action": [
       "logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"
     ],
     "Resource": ["arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:*"]
   },
   {
  "Effect": "Allow",
  "Action": [
    "kms:Encrypt",
    "kms:ReEncrypt*",
    "kms:Decrypt",
    "kms:GenerateDataKey*",
    "kms:Describe*"
  ],
  "Resource": ["arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:*"],
  "Condition": {
    "StringEquals": {
      "kms:ViaService": [
        "logs.${data.aws_region.current.name}.amazonaws.com"
      ]
    }
  }
},
   {
     "Effect": "Allow",
     "Action": [
       "cloudwatch:PutMetricData"
     ],
     "Resource": ["arn:aws:cloudwatch:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:alarm:*"]
   }
 ]
}
EOF
}
