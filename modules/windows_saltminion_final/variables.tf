variable "minion_private_dns_name" {
  default = "10.0.2.4"
}
variable "minion_user" {
  default = "saltmaster"
}

variable "minion_password" {
  default = "altair@123456"
}

variable "bastion_public_ip_address" {
    default = "137.116.115.149"
}

variable "bastion_user" {
    default = "ubuntu"
}

variable "ssh_private_key" {
    default = "~/.ssh/a365-admin"
}

variable "minion_name" {
    default = "winrm"
}

variable "saltmaster_private_dns_name" {
    default = "earth-saltmaster.altair365.com"
}

variable "saltmaster_user" {
    default = "saltmaster"
}