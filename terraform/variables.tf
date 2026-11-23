variable "region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "us-east-1"
}

variable "project" {
  description = "The name of the project"
  type    = string
  default = "team_1"
}

variable "ip_cidr" {
  description = "IP: x.x.x.x/32"
  type        = string
}

variable "public_key_path" {
  description = "The path to the public key file"
  type    = string
  default = "~/.ssh/id_ed25519.pub"
}