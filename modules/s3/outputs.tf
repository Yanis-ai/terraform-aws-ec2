output "bucket_name" {
  description = "S3バケットの名前"
  value       = aws_s3_bucket.normal_bucket.bucket
}