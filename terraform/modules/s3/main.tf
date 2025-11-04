resource "aws_s3_bucket" "elb_logs" {
  bucket = var.bucket_name
  tags = {
    Name        = "${var.environment}-elb logs"
  }
}

data "aws_elb_service_account" "main" {}

resource "aws_s3_bucket_policy" "elb_logs_policy" {
  bucket = aws_s3_bucket.elb_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          AWS = data.aws_elb_service_account.main.arn
        },
        Action = "s3:PutObject",
        Resource = "${aws_s3_bucket.elb_logs.arn}/elb-logs/AWSLogs/${var.account_id}/*"
      },
      {
        Effect = "Allow",
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        },
        Action = "s3:GetBucketAcl",
        Resource = aws_s3_bucket.elb_logs.arn
      }
    ]
  })
}