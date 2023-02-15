module "static_website" {
  source = "../modules/static-website"

  bucket_name              = "sqt-${var.product}-${var.environment}"
  origin_access_control_id = "oca-id-${var.product}-${var.environment}"
  cf_distribution_comment  = "${var.product}-${var.environment}"

}
