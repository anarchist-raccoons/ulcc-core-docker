# Azure Variables
variable "subscription_id" {
}

variable "client_id" {
}

variable "client_secret" {
}

variable "tenant_id" {
}

variable "ssh_key" {
}

variable "location" {
  default = "northeurope"
}

variable "account_replication_type" {
  default = "LRS"
}

variable "account_tier" {
  default = "Standard"
}

# Find available VMs with az vm list-skus -l LOCATION --output table
variable "vm_size" { }

variable "admin_user" {
  default = "azureuser"
}
variable "agent_count" {
  default = 1
}
variable "disk_size_gb" {
  default = 30
}

variable "developer_access" {
  type = "list"
}

variable "user_access" {
  type = "list"
}

variable "zone_name" { }
variable "zone_resource_group" { }