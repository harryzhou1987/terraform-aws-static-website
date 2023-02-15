

resource "aws_s3_bucket" "s3_bucket" {
  bucket = var.bucket_name
}

resource "aws_s3_bucket_public_access_block" "public_access_block" {
  bucket = aws_s3_bucket.s3_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "bucket_versioning" {
  bucket = aws_s3_bucket.s3_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "bucket_server_side_encryption_configuration" {
  bucket = aws_s3_bucket.s3_bucket.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_policy" "all_from_cloudfront" {
  bucket = aws_s3_bucket.s3_bucket.id
  policy = data.aws_iam_policy_document.all_from_cloudfront.json
}

data "aws_iam_policy_document" "all_from_cloudfront" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions = [
      "s3:PutObject",
      "s3:GetObject"
    ]

    resources = ["${aws_s3_bucket.s3_bucket.arn}/*"]
    condition {
      variable = "AWS:SourceArn"
      test     = "StringEquals"
      values   = ["${aws_cloudfront_distribution.s3_distribution.arn}"]
    }
  }
}


# CloudFront
resource "aws_cloudfront_origin_access_control" "origin_access_control" {
  name                              = var.origin_access_control_id
  description                       = "Origin Control Access - ${var.origin_access_control_id}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name              = aws_s3_bucket.s3_bucket.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.origin_access_control.id
    origin_id                = var.bucket_name
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = var.cf_distribution_comment
  default_root_object = "index.html"


  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = var.bucket_name
    cache_policy_id  = data.aws_cloudfront_cache_policy.managed_caching_optimized_policy.id

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 0
    compress               = true
  }

  restrictions {
    geo_restriction {
      locations        = []
      restriction_type = "none"
    }
  }


  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

data "aws_cloudfront_cache_policy" "managed_caching_optimized_policy" {
  name = "Managed-CachingOptimized"
}
