# main.tf for the Developer Workspace

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    tfe = {
      source  = "hashicorp/tfe"
      version = "~> 0.50"
    }
  }
  cloud {
    organization = "hashi-org-TF" # <-- Make sure to update this

    workspaces {
      name = "terraform-azure-developer-api"
    }
  }
}

provider "azurerm" {
  features {}
}

# Read the outputs from the platform workspace to get the APIM instance details
data "tfe_outputs" "platform" {
  organization = "hashi-org-TF" 
  workspace    = "terraform-azure-platform-apim"
}

# Define the developer's API within the existing APIM instance
resource "azurerm_api_management_api" "developer_api" {
  name                = "alpha-app-api"
  resource_group_name = data.tfe_outputs.platform.values.resource_group_name
  api_management_name = data.tfe_outputs.platform.values.api_management_name
  revision            = "1"
  display_name        = "Alpha Application API"
  path                = "alpha"
  protocols           = ["https"]

  # This points to the actual backend service where requests will be forwarded
  service_url = "http://httpbin.org"
}

# Define a specific operation (e.g., GET /ip) for our new API
resource "azurerm_api_management_api_operation" "get_ip" {
  api_name            = azurerm_api_management_api.developer_api.name
  resource_group_name = data.tfe_outputs.platform.values.resource_group_name
  api_management_name = data.tfe_outputs.platform.values.api_management_name
  
  operation_id        = "get-ip-address" # This ID is used to target the policy
  display_name        = "Get Caller IP"
  method              = "GET"
  url_template        = "/ip"
}

# CORRECTED RESOURCE: Apply policy to the specific operation
# This replaces your old "azurerm_api_management_api_policy" resource
resource "azurerm_api_management_api_operation_policy" "rate_limit_policy" {
  # These four attributes correctly target the single operation
  operation_id        = azurerm_api_management_api_operation.get_ip.operation_id
  api_name            = azurerm_api_management_api.developer_api.name
  api_management_name = data.tfe_outputs.platform.values.api_management_name
  resource_group_name = data.tfe_outputs.platform.values.resource_group_name

  xml_content = <<XML
<policies>
    <inbound>
        <base />
        <rate-limit calls="5" renewal-period="60" />
    </inbound>
    <backend>
        <base />
    </backend>
    <outbound>
        <base />
    </outbound>
    <on-error>
        <base />
    </on-error>
</policies>
XML
}
