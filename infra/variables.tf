variable "project_name" {
  type    = string
  default = "mean-crud"
}

variable "db_name" {
  type    = string
  default = "appdb"
}

variable "db_username" {
  type    = string
  default = "appuser"
}

variable "db_password" {
  type      = string
  sensitive = true
}

# Your current public IP in CIDR form, e.g. "1.2.3.4/32"
variable "my_ip_cidr" {
  type = string
}

# Pick a valid EB solution stack available in us-east-1.
# If this errors, we’ll swap it to the exact one from your EB console.
variable "eb_solution_stack" {
  type    = string
  default = "64bit Amazon Linux 2023 v6.7.2 running Node.js 20"
}
