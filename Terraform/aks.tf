# Create AKS cluster
resource "random_id" "log_analytics_workspace_name_suffix" {
  byte_length = 8
}

resource "azurerm_log_analytics_workspace" "apim-aks-aw" {
  location            = azurerm_resource_group.rg.location
  name                = "apim-aks-demo-${random_id.log_analytics_workspace_name_suffix.dec}"
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Free"
}

resource "azurerm_log_analytics_solution" "apim-aks-as" {
  location              = azurerm_log_analytics_workspace.apim-aks-aw.location
  resource_group_name   = azurerm_resource_group.rg.name
  solution_name         = "ContainerInsights"
  workspace_name        = azurerm_log_analytics_workspace.apim-aks-aw.name
  workspace_resource_id = azurerm_log_analytics_workspace.apim-aks-aw.id

  plan {
    product   = "OMSGallery/ContainerInsights"
    publisher = "Microsoft"
  }
}

resource "azurerm_kubernetes_cluster" "aks-backend" {
  location            = azurerm_resource_group.rg.location
  name                = "apim-aks-demo-cluster"
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix = "apimaksdemocluster"

  default_node_pool {
    name       = "agentpool"
    vm_size    = "Standard_D2_v2"
    vnet_subnet_id = azurerm_virtual_network.aks-vnet-1.id
    node_count = 1
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "azure"
    load_balancer_sku = "standard"
  }
  
}