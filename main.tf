terraform {
  backend "azurerm" {
    resource_group_name   = "IC3000"
    storage_account_name  = "ic3000"
    container_name        = "tfstate"
    key                   = "terraform.tfstate"
  }
}

# Configure the Azure provider
provider "azurerm" { 
  # The "feature" block is required for AzureRM provider 2.x. 
  # If you are using version 1.x, the "features" block is not allowed.
  version = "~>2.0"
  features {}
}