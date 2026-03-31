terraform {
  backend "azurerm" {
    resource_group_name  = "platform-tfstate-rg"
    storage_account_name = "kootfstate001"
    container_name       = "tfstate"
    key                  = "beingax-prd.terraform.tfstate"
  }
}