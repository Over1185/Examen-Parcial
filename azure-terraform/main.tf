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
  default     = "East US"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

# Crear grupo de recursos
resource "azurerm_resource_group" "quarkus_rg" {
  name     = "rg-quarkus-${var.environment}"
  location = var.location

  tags = {
    Environment = var.environment
    Project     = "QuarkusMoviesAPI"
    CreatedBy   = "Terraform"
  }
}

# Crear Azure Container Registry
resource "azurerm_container_registry" "acr" {
  name                = "acrquarkus${var.environment}${random_integer.suffix.result}"
  resource_group_name = azurerm_resource_group.quarkus_rg.name
  location            = azurerm_resource_group.quarkus_rg.location
  sku                 = "Basic"
  admin_enabled       = true

  tags = {
    Environment = var.environment
    Project     = "QuarkusMoviesAPI"
  }
}

# Generar sufijo aleatorio para nombres únicos
resource "random_integer" "suffix" {
  min = 1000
  max = 9999
}

# Crear PostgreSQL Flexible Server
resource "azurerm_postgresql_flexible_server" "postgres" {
  name                   = "psql-quarkus-${var.environment}-${random_integer.suffix.result}"
  resource_group_name    = azurerm_resource_group.quarkus_rg.name
  location               = azurerm_resource_group.quarkus_rg.location
  version                = "15"
  administrator_login    = "postgres"
  administrator_password = "QuarkusAdmin123!"
  
  storage_mb   = 32768
  sku_name     = "B_Standard_B1ms"
  
  backup_retention_days = 7
  
  tags = {
    Environment = var.environment
    Project     = "QuarkusMoviesAPI"
  }
}

# Crear base de datos
resource "azurerm_postgresql_flexible_server_database" "quarkusdb" {
  name      = "quarkusdb"
  server_id = azurerm_postgresql_flexible_server.postgres.id
  collation = "en_US.utf8"
  charset   = "utf8"
}

# Configurar firewall para PostgreSQL
resource "azurerm_postgresql_flexible_server_firewall_rule" "allow_azure" {
  name             = "AllowAzureServices"
  server_id        = azurerm_postgresql_flexible_server.postgres.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# Crear App Service Plan
resource "azurerm_service_plan" "app_service_plan" {
  name                = "asp-quarkus-${var.environment}"
  resource_group_name = azurerm_resource_group.quarkus_rg.name
  location            = azurerm_resource_group.quarkus_rg.location
  os_type             = "Linux"
  sku_name            = "B1"

  tags = {
    Environment = var.environment
    Project     = "QuarkusMoviesAPI"
  }
}

# Crear Web App (Container)
resource "azurerm_linux_web_app" "quarkus_app" {
  name                = "app-quarkus-${var.environment}-${random_integer.suffix.result}"
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
    "POSTGRES_USER"                       = azurerm_postgresql_flexible_server.postgres.administrator_login
    "POSTGRES_PASSWORD"                   = azurerm_postgresql_flexible_server.postgres.administrator_password
    "POSTGRES_URL"                        = "jdbc:postgresql://${azurerm_postgresql_flexible_server.postgres.fqdn}:5432/quarkusdb"
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
  value       = azurerm_resource_group.quarkus_rg.name
}

output "app_service_name" {
  description = "Name of the App Service"
  value       = azurerm_linux_web_app.quarkus_app.name
}

output "app_service_url" {
  description = "URL of the App Service"
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
