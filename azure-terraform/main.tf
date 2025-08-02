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

# ==========================================
# CREAR TODA LA INFRAESTRUCTURA DESDE CERO
# ==========================================

# Crear Resource Group
resource "azurerm_resource_group" "quarkus_rg" {
  name     = "rg-quarkus-jenkins"
  location = var.location
}

# Crear Container Registry
resource "azurerm_container_registry" "acr" {
  name                = "acquarkusjenkins"
  resource_group_name = azurerm_resource_group.quarkus_rg.name
  location            = azurerm_resource_group.quarkus_rg.location
  sku                 = "Basic"
  admin_enabled       = true
}

# Crear PostgreSQL Flexible Server
resource "azurerm_postgresql_flexible_server" "postgres" {
  name                   = "postgres-quarkus-jenkins"
  resource_group_name    = azurerm_resource_group.quarkus_rg.name
  location               = azurerm_resource_group.quarkus_rg.location
  version                = "14"
  administrator_login    = "postgres"
  administrator_password = "QuarkusApp2024!"
  storage_mb             = 32768
  sku_name               = "B_Standard_B1ms"
}

# Crear App Service Plan
resource "azurerm_service_plan" "app_service_plan" {
  name                = "asp-quarkus-jenkins"
  resource_group_name = azurerm_resource_group.quarkus_rg.name
  location            = azurerm_resource_group.quarkus_rg.location
  os_type             = "Linux"
  sku_name            = "B1"
}

# Crear Web App
resource "azurerm_linux_web_app" "quarkus_app" {
  name                = "webapp-quarkus-jenkins"
  resource_group_name = azurerm_resource_group.quarkus_rg.name
  location            = azurerm_service_plan.app_service_plan.location
  service_plan_id     = azurerm_service_plan.app_service_plan.id

  site_config {
    application_stack {
      docker_image_name        = "quarkus-microservice:latest"
      docker_registry_url      = "https://${azurerm_container_registry.acr.login_server}"
      docker_registry_username = azurerm_container_registry.acr.admin_username
      docker_registry_password = azurerm_container_registry.acr.admin_password
    }

    always_on = false
  }

  app_settings = {
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "false"
    "QUARKUS_DATASOURCE_USERNAME"         = "postgres"
    "QUARKUS_DATASOURCE_PASSWORD"         = "QuarkusApp2024!"
    "QUARKUS_DATASOURCE_JDBC_URL"         = "jdbc:postgresql://${azurerm_postgresql_flexible_server.postgres.fqdn}:5432/quarkusdb?sslmode=require"
    "QUARKUS_HIBERNATE_ORM_DATABASE_GENERATION" = "update"
    "WEBSITES_PORT"                        = "8080"
  }

  tags = {
    Environment = var.environment
    Project     = "QuarkusMoviesAPI"
  }
}

# Outputs
output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.quarkus_rg.name
}

output "app_service_name" {
  description = "Name of the Web App"
  value       = azurerm_linux_web_app.quarkus_app.name
}

output "app_service_url" {
  description = "URL of the Web App"
  value       = "https://${azurerm_linux_web_app.quarkus_app.default_hostname}"
}

output "container_registry_url" {
  description = "Container Registry URL"
  value       = azurerm_container_registry.acr.login_server
}

output "postgres_fqdn" {
  description = "PostgreSQL FQDN"
  value       = azurerm_postgresql_flexible_server.postgres.fqdn
}

output "postgres_connection_string" {
  description = "PostgreSQL connection string"
  value       = "jdbc:postgresql://${azurerm_postgresql_flexible_server.postgres.fqdn}:5432/quarkusdb"
  sensitive   = true
}
