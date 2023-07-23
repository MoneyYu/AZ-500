terraform {
  required_version = ">=0.12"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

variable "group_postfix" {
  type = string
}

variable "user_name" {
  type    = string
  default = "demouser"
}

variable "user_passowrd" {
  type    = string
  default = "Azuredemo2020"
}

locals {
  group_name    = "AZ500-${var.group_postfix}"
  location      = "japaneast"
  random_str    = "dog"
  vm_size       = "Standard_B4ms"
  admin_oid     = "b8e50bc5-6559-4643-a003-2807a8d707f7"
  lab01_name    = "lab01"
  lab02_name    = "lab02"
  lab02a_name   = "lab02a"
  lab02b_name   = "lab02b"
  lab02c_name   = "lab02c"
  lab02d_name   = "lab02d"
  lab02e_name   = "lab02e"
  lab03_name    = "lab03"
  lab03a_name   = "lab03a"
  lab03b_name   = "lab03b"
  lab03c_name   = "lab03c"
  lab03d_name   = "lab03d"
  lab03e_name   = "lab03e"
  lab03f_name   = "lab03f"
  lab03g_name   = "lab03g"
  lab04_name    = "lab04"
  lab04a_name    = "lab04a"
  lab04b_name    = "lab04b"
  user_name     = "demouser"
  user_passowrd = "Azuredemo2020"
}

data "http" "myip" {
  url = "http://ipv4.icanhazip.com"
}

data "azurerm_client_config" "current" {}

resource "random_string" "rid" {
  length  = 3
  special = false
  numeric = false
  upper   = false
}

resource "random_integer" "rint" {
  min = 100
  max = 999
}

# Create a resource group if it doesn't exist
resource "azurerm_resource_group" "az500" {
  name     = local.group_name
  location = local.location

  tags = {
    environment = local.group_name
  }
}
