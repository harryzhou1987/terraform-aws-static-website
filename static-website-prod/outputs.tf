output "Static_Web_URL" {
  value = "https://${module.static_website.cf_distribution_domain_name}"
}