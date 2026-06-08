terraform {
  backend "azurerm" {
    resource_group_name  = "auditax-tfstate-dev-rg"
    storage_account_name = "auditaxtfstatedevstg"
    container_name       = "tfstate"
    key                  = "auditax-dev.terraform.tfstate"
  }
}