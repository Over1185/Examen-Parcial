# Configurar el provider de Azure
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

# Configurar el provider de Azure
provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
  
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
  subscription_id = var.subscription_id
}

# Variables
variable "client_id" {
  description = "Azure Service Principal Client ID"
  type        = string
}

variable "client_secret" {
  description = "Azure Service Principal Client Secret"
  type        = string
  sensitive   = true
}

variable "tenant_id" {
  description = "Azure Tenant ID"
  type        = string
}

variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "Central US"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

# Usar el Resource Group existente
data "azurerm_resource_group" "quarkus_rg" {
  name = "rg-quarkus-app"
}

# Usar el Container Registry existente
data "azurerm_container_registry" "acr" {
  name                = "ACquarkusapp"
  resource_group_name = data.azurerm_resource_group.quarkus_rg.name
}

# Usar el PostgreSQL existente
data "azurerm_postgresql_flexible_server" "postgres" {
  name                = "postgres-quarkus-app"
  resource_group_name = data.azurerm_resource_group.quarkus_rg.name
}

# Usar el App Service Plan existente
data "azurerm_service_plan" "app_service_plan" {
  name                = "webapp-quarkus-movies"
  resource_group_name = data.azurerm_resource_group.quarkus_rg.name
}

# Outputs
output "resource_group_name" {
  description = "Name of the resource group"
  value       = data.azurerm_resource_group.quarkus_rg.name
}

output "app_service_name" {
  description = "Name of the App Service"
  value       = data.azurerm_service_plan.app_service_plan.name
}

output "container_registry_url" {
  description = "Container Registry URL"
  value       = data.azurerm_container_registry.acr.login_server
}

output "postgres_fqdn" {
  description = "PostgreSQL FQDN"
  value       = data.azurerm_postgresql_flexible_server.postgres.fqdn
}

output "postgres_connection_string" {
  description = "PostgreSQL connection string"
  value       = "jdbc:postgresql://${data.azurerm_postgresql_flexible_server.postgres.fqdn}:5432/quarkusdb"
  sensitive   = true
}
