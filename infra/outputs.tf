output "db_endpoint" {
  value = aws_db_instance.postgres.address
}

output "database_url" {
  value     = "postgresql://${var.db_username}:***@${aws_db_instance.postgres.address}:5432/${var.db_name}?schema=public"
  sensitive = false
}

output "eb_app_name" {
  value = aws_elastic_beanstalk_application.api.name
}

output "eb_env_name" {
  value = aws_elastic_beanstalk_environment.api_env.name
}
