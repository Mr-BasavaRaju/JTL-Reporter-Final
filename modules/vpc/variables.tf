variable "vpc_cidr" {
  type = string
}
variable "public_subnet_count" {
  type = number
}
variable "private_subnet_count" {
  type = number
}
variable "public_subnet_cidrs" {
  type = list(string)

}
variable "private_subnet_cidrs" {
  type = list(string)

}
variable "availability_zones" {
  type = list(string)

}