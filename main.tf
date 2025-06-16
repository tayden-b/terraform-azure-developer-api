terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
  cloud {
    organization = "hashi-org-TF" # 

    workspaces {
      name = "platform-azure-api-management"
    }
  }
}

provider "azurerm" {
  features {}
}


resource "azurerm_resource_group" "platform_rg" {
  name     = "platform-rg"
  location = "East US" # You can choose a different region
}

# (APIM) INSTANCE
################################################################################

resource "azurerm_api_management" "platform_apim" {
  name                = "hcp-demo-platform-apim" # Must be globally unique
  location            = azurerm_resource_group.platform_rg.location
  resource_group_name = azurerm_resource_group.platform_rg.name
  publisher_name      = "Platform Engineering"
  publisher_email     = "tpbarret@outlook.com"

  sku_name = "Consumption_0" # This is the free tier SKU

  tags = {
    "team"      = "platform"
    "managedBy" = "terraform"
  }
}

################################################################################
# OUTPUTS
#
# These values will be shared with the developer workspace. Using outputs
# is the standard way to expose resource information for cross-workspace
# communication.
################################################################################

output "api_management_id" {
  description = "The resource ID of the API Management instance."
  value       = azurerm_api_management.platform_apim.id
}

output "api_management_name" {
  description = "The name of the API Management instance."
  value       = azurerm_api_management.platform_apim.name
}

output "resource_group_name" {
  description = "The name of the resource group for the APIM instance."
  value       = azurerm_resource_group.platform_rg.name
}
