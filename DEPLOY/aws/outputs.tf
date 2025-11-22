output "service_url" {
  value = aws_apprunner_service.service.service_url
}

output "db_endpoint" {
  value = aws_db_instance.default.address
}
