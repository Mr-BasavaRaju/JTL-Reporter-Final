variable "file_system" {
  description = "The ID of the file system."
  type        = string
  default     = ""
}

variable "public_subnets" {
  type = list(string)

}

variable "private_subnets" {
  type = list(string)
}

variable "vpc_id" {
  type    = string
  default = ""

}

variable "lb_sg" {
  description = "The ID of the security group to associate with the ECS service"
  type        = list(string)
  default = [ "" ]
  
}

variable "psql_host" {
  description = "Hostname for PostgreSQL database"
  type        = string
}

variable "psql_password" {
  description = "Password for PostgreSQL database"
  type        = string
}

variable "psql_user" {
  description = "Username for PostgreSql Database"
  type        = string
}