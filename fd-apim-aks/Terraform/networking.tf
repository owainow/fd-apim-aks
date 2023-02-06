# Create networking components VNET, Route Tables, Subnets
resource "azurerm_resource_group" "rg" {
  name     = "aks-apim-demo"
  location =  "uksouth"  
}

resource "azurerm_network_security_group" "nsg" {
  name                = "TF-AKS-APIM-NSG-1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "Allow3443Inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "3443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
    security_rule {
    name                       = "Allow80Inbound"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
    security_rule {
    name                       = "Allow443Inbound"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

    security_rule {
    name                       = "Allow6390Inbound"
    priority                   = 130
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "6390"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
    security_rule {
    name                       = "Allow443Outbound"
    priority                   = 1110
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
    security_rule {
    name                       = "Allow1433Outbound"
    priority                   = 1120
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "1433"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Create VNETS & Subnets

  resource "azurerm_virtual_network" "apim-vnet-1" {
  name                = "TF-APIM-VNET-1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["172.0.0.0/16"]
 
}

  resource "azurerm_virtual_network" "aks-vnet-1" {
  name                = "TF-AKS-VNET-1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.224.0.0/16"]
 
}

resource "azurerm_subnet" "apim-subnet-1" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.apim-vnet-1.name
  address_prefixes     = ["172.0.1.0/24"]
}

resource "azurerm_subnet" "aks-subnet-1" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.aks-vnet-1.name
  address_prefixes     = ["10.224.0.0/24"]
}

# VNET Peering
resource "azurerm_virtual_network_peering" "peer-apim-to-aks" {
  name                      = "peerapimtoaks"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.apim-vnet-1.name
  remote_virtual_network_id = azurerm_virtual_network.aks-vnet-1.id
}

resource "azurerm_virtual_network_peering" "peer-aks-to-apim" {
  name                      = "peerakstoapim"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.aks-vnet-1.name
  remote_virtual_network_id = azurerm_virtual_network.apim-vnet-1.id
}


#Create route table & routes
resource "azurerm_route_table" "route-table" {
  name                          = "route-table-apim-test"
  location                      = azurerm_resource_group.rg.location
  resource_group_name           = azurerm_resource_group.rg.name
  disable_bgp_route_propagation = false

  route {
    name           = "ControlPlanePublicAllow"
    address_prefix = "51.145.56.125/32"
    next_hop_type  = "Internet"
  }
}

resource "azurerm_subnet_route_table_association" "route-table-submet" {
  subnet_id      = azurerm_subnet.apim-subnet-1.id
  route_table_id = azurerm_route_table.route-table.id
}

resource "azurerm_subnet_network_security_group_association" "nsg-apim-subnet" {
  subnet_id                 = azurerm_subnet.apim-subnet-1.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}