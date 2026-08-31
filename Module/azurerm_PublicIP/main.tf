resource "azurerm_public_ip" "publicip1" {
  for_each            = var.public_ip
  name                = each.value.name
  resource_group_name = each.value.resource_group_name
  location            = each.value.location
  allocation_method   = each.value.allocation_method
}

resource "azurerm_public_ip" "publicip2" {
  for_each            = var.public_ip
  name                = each.value.name1
  resource_group_name = each.value.resource_group_name
  location            = each.value.location
  allocation_method   = each.value.allocation_method
}