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

# Resource group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.resource_group_location
}

# Cosmos DB account
resource "azurerm_cosmosdb_account" "db" {
  name                = "ic3000-cosmos-db"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"

  enable_automatic_failover = true

  consistency_policy {
    consistency_level       = "BoundedStaleness"
    max_interval_in_seconds = 10
    max_staleness_prefix    = 200
  }

  geo_location {
    location          = var.failover_location
    failover_priority = 1
  }

  geo_location {
    location          = azurerm_resource_group.rg.location
    failover_priority = 0
  }
}

# Service Bus
resource "azurerm_servicebus_namespace" "servicebusnamespace" {
  name                = "ic3000-servicebus-namespace"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Standard"
}

# Service Bus topic
resource "azurerm_servicebus_topic" "servicebustopic" {
  name                = "ic3000_servicebus_topic"
  resource_group_name = azurerm_resource_group.rg.name
  namespace_name      = azurerm_servicebus_namespace.servicebusnamespace.name

  enable_partitioning = true
}

# Backend web REST API app service plan
resource "azurerm_app_service_plan" "backendsp" {
  name                = "IC3000-backend-sp"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  sku {
    tier = "Standard"
    size = "S1"
  }
}

# Backend web REST API app
resource "azurerm_app_service" "backend" {
  name                = "IC3000-backend"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  app_service_plan_id = azurerm_app_service_plan.backendsp.id
  https_only          = true

  site_config {
    always_on = true
    linux_fx_version = "DOCKER|simennielsen/ic3000:latest"
  }

  app_settings = {
    "" = "some-value"
  }

  connection_string {
    name  = "COSMOS_DB"
    type  = "Custom"
    value = "${azurerm_cosmosdb_account.db.endpoint};AccountKey=${data.azurerm_cosmosdb_account.db.primary_master_key};"
  }
  connection_string {
    name = "SERVICE_BUS"
    type = "Custom"
    value = azurerm_servicebus_namespace.servicebusnamespace.default_primary_connection_string
  }
}