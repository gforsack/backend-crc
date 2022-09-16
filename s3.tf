resource "aws_s3_bucket" "crc_bucket" {
  bucket = ""

  tags = {
    Environment = "production"
  }

  force_destroy = true
}

# create bucket ACL :
resource "aws_s3_bucket_acl" "bucket_acl" {
  bucket = aws_s3_bucket.crc_bucket.id
  acl    = "private"
}

# block public access to bucket
resource "aws_s3_account_public_access_block" "public_block" {
  block_public_acls   = true
  block_public_policy = true
  restrict_public_buckets = true
  ignore_public_acls = true
}

# create S3 website hosting
resource "aws_s3_bucket_website_configuration" "crc_bucket_hosting" {
  bucket = aws_s3_bucket.crc_bucket.bucket

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

output "bucket_name" {
  value = aws_s3_bucket.crc_bucket.id
}
