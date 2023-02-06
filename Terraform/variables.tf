variable "location" {
  type    = string
  default = "uksouth"
}

variable "resource_group_name" {
  type    = string
  default = "FrontDoor"
}

variable "apim_publisher_name"{
  type = string
  default = "Owain Osborne-Walsh"
}

variable "apim_publisher_email"{
  type = string
  default = "owaino@microsoft.com"
}

variable "front_door_sku_name" {
  type    = string
  default = "Standard_AzureFrontDoor"
  validation {
    condition     = contains(["Standard_AzureFrontDoor", "Premium_AzureFrontDoor"], var.front_door_sku_name)
    error_message = "The SKU value must be Standard_AzureFrontDoor or Premium_AzureFrontDoor."
  }
}
