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
  name                = "postgres-quarkus-app-ac"
  resource_group_name = data.azurerm_resource_group.quarkus_rg.name
}

# Usar el App Service Plan existente
data "azurerm_service_plan" "app_service_plan" {
  name                = "asp-quarkus-app"
  resource_group_name = data.azurerm_resource_group.quarkus_rg.name
}

# Crear Web App
resource "azurerm_linux_web_app" "quarkus_app" {
  name                = "webapp-quarkus-dev"
  resource_group_name = data.azurerm_resource_group.quarkus_rg.name
  location            = data.azurerm_service_plan.app_service_plan.location
  service_plan_id     = data.azurerm_service_plan.app_service_plan.id

  site_config {
    application_stack {
      docker_image_name        = "quarkus-microservice:latest"
      docker_registry_url      = "https://${data.azurerm_container_registry.acr.login_server}"
      docker_registry_username = data.azurerm_container_registry.acr.admin_username
      docker_registry_password = data.azurerm_container_registry.acr.admin_password
    }

    always_on = false
  }

  app_settings = {
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "false"
    "POSTGRES_USER"                       = data.azurerm_postgresql_flexible_server.postgres.administrator_login
    "POSTGRES_PASSWORD"                   = "QuarkusAdmin123!"
    "POSTGRES_URL"                        = "jdbc:postgresql://${data.azurerm_postgresql_flexible_server.postgres.fqdn}:5432/quarkusdb"
    "QUARKUS_PROFILE"                     = "azure"
    "PORT"                                = "8080"
  }

  tags = {
    Environment = var.environment
    Project     = "QuarkusMoviesAPI"
  }
}

# Outputs
output "resource_group_name" {
  description = "Name of the resource group"
  value       = data.azurerm_resource_group.quarkus_rg.name
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
