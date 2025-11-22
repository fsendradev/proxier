output "service_url" {
  value = google_cloud_run_service.default.status[0].url
}

output "connection_name" {
  value = google_sql_database_instance.instance.connection_name
}
