resource "aws_s3_bucket" "codepipeline_artifacts" {
  bucket = "codepipeline-artifacts-${random_string.random.result}"
}

resource "aws_s3_bucket_public_access_block" "codepipeline_bucket_pab" {
  bucket = aws_s3_bucket.codepipeline_artifacts.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "random_string" "random" {
  length = 8
  upper = false
  lower = true
  special = false
}