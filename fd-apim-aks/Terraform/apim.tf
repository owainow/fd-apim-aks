resource "random_id" "apim_endpoint" {
  byte_length = 8
}
# Create APIM instance
resource "azurerm_api_management" "apim" {
  name                = "apim-aks-demo-${lower(random_id.apim_endpoint.hex)}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  publisher_name      = var.apim_publisher_name
  publisher_email     = var.apim_publisher_email

  sku_name            = "Developer_1"

  identity {
    type = "SystemAssigned"
  }
}

# Create APIM Products and Policy
# create product
resource "azurerm_api_management_product" "product" {
  product_id            = "Demo_Product"
  api_management_name   = azurerm_api_management.apim.name
  resource_group_name   = azurerm_resource_group.rg.name
  display_name          = "Demo Product"
  subscription_required = true
  approval_required     = false
  published             = true
}

# assign policy to product
resource "azurerm_api_management_product_policy" "productPolicy" {
  product_id          = azurerm_api_management_product.product.product_id
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = azurerm_resource_group.rg.name
  xml_content = <<XML
    <policies>
      <inbound>
        <base />
      </inbound>
      <backend>
        <base />
      </backend>
      <outbound>
        <set-header name="Server" exists-action="delete" />
        <set-header name="X-Powered-By" exists-action="delete" />
        <set-header name="X-AspNet-Version" exists-action="delete" />
        <base />
      </outbound>
      <on-error>
        <base />
      </on-error>
    </policies>
  XML
  depends_on = [azurerm_api_management_product.product]
}

# create API
resource "azurerm_api_management_api" "Platforms_API" {
name                = "Platforms-API"
resource_group_name = azurerm_resource_group.rg.name
api_management_name = azurerm_api_management.apim.name
revision            = "1"
display_name        = "Platforms API"
path                = "health-probe"
protocols           = ["https"]

  subscription_key_parameter_names  {
    header = "AppKey"
    query = "AppKey"
  }

  import {
    content_format = "swagger-json"
    content_value  = <<JSON
{
    "swagger": "2.0",
    "info": {
        "title": "Platforms API",
        "version": "v1",
        "description": "An API to access the platforms microservices in AKS. "
    },
    "host": "greggs-apim.azure-api.net",
    "basePath": "/api",
    "schemes": [
        "http",
        "https"
    ],
    "securityDefinitions": {
        "apiKeyHeader": {
            "type": "apiKey",
            "name": "Ocp-Apim-Subscription-Key",
            "in": "header"
        },
        "apiKeyQuery": {
            "type": "apiKey",
            "name": "subscription-key",
            "in": "query"
        }
    },
    "security": [
        {
            "apiKeyHeader": []
        },
        {
            "apiKeyQuery": []
        }
    ],
    "paths": {
        "/platforms/": {
            "get": {
                "description": "Get all platforms",
                "operationId": "get-platforms",
                "summary": "Get Platforms",
                "responses": {
                    "200": {
                        "description": null
                    }
                }
            }
        },
        "/platforms": {
            "post": {
                "description": "Upload a platform",
                "operationId": "postplatforms",
                "summary": "PostPlatforms",
                "parameters": [
                    {
                        "name": "Content-Type",
                        "in": "header",
                        "required": true,
                        "type": "string",
                        "enum": [
                            "application/json"
                        ]
                    }
                ],
                "responses": {
                    "200": {
                        "description": null
                    }
                }
            }
        },
        "/platforms/{id}": {
            "get": {
                "operationId": "get-platforms-id",
                "summary": "Get Platforms ID",
                "parameters": [
                    {
                        "name": "id",
                        "in": "path",
                        "description": "Platform ID",
                        "required": true,
                        "type": "integer"
                    }
                ],
                "responses": {
                    "200": {
                        "description": null
                    }
                }
            }
        }
    },
    "tags": []
}
    JSON
  }
}

# set api level policy
# Add FD check header as optional step in setup guide. 
resource "azurerm_api_management_api_policy" "apiHealthProbePolicy" {
  api_name            = azurerm_api_management_api.Platforms_API.name
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = azurerm_resource_group.rg.name

  xml_content = <<XML
<policies>
    <inbound>
        <base />
        <set-backend-service base-url="http://10.224.0.200/api/" />
        <set-query-parameter name="subscription-key" exists-action="delete" />
        <rate-limit-by-key calls="5" renewal-period="60" counter-key="@(context.Subscription?.Key ?? "anonymous")" />
    </inbound>
    <backend>
        <base />
    </backend>
    <outbound>
        <base />
    </outbound>
    <on-error>
        <base />
        <return-response>
            <set-status code="405" reason="Method not allowed" />
            <set-body>@{
                        return new JObject(
                            new JProperty("status", "HTTP 405"),
                            new JProperty("message", "Method not allowed")
                        ).ToString();
                    }</set-body>
        </return-response>
    </on-error>
</policies>
  XML
}

# assign api to product
resource "azurerm_api_management_product_api" "apiProduct" {
  api_name            = azurerm_api_management_api.Platforms_API.name
  product_id          = azurerm_api_management_product.product.product_id
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = azurerm_resource_group.rg.name
}

