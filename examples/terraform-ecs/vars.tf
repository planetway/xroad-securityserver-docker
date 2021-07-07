variable "profile" {
  description = "AWS profile name"
  type        = string
}

variable "region" {
  description = "AWS region name"
  type        = string
}

variable "name_prefix" {
  description = "Prefix for names of resources"
  type        = string
  default     = "ss"
}

variable "instance_type" {
  description = "ECS instance type"
  type        = string
  default     = "t3.medium"
}

variable "myip" {
  description = "My Global IP"
  type        = string
}

variable "termination_protection" {
  description = "Enable deletion/termination protection for possible resources"
  type        = bool
  default     = true
}

variable "enable_execute_command" {
  description = "Enable AWS ECS Exec in the Security server services"
  type        = bool
  default     = false
}

variable "public_zone_name" {
  description = "Public zone name to create the Security server domain name in"
  type        = string
}

variable "private_zone_name" {
  description = "Private zone name to create the Security server domain name in"
  type        = string
}
