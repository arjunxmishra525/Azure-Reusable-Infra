data "azurerm_subnet" "nat_subnet_data" {
  for_each             = var.nat_gateway
  name                 = each.value.subnet_name
  virtual_network_name = each.value.virtual_network_name
  resource_group_name  = each.value.resource_group_name
}

resource "azurerm_public_ip" "nat_pip" {
  for_each            = var.nat_gateway
  name                = each.value.public_ip_name
  location            = each.value.location
  resource_group_name = each.value.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_nat_gateway" "nat_gw" {
  for_each            = var.nat_gateway
  name                = each.value.name
  location            = each.value.location
  resource_group_name = each.value.resource_group_name
  sku_name            = lookup(each.value, "sku_name", "Standard")
}

resource "azurerm_nat_gateway_public_ip_association" "nat_pip_assoc" {
  for_each             = var.nat_gateway
  nat_gateway_id       = azurerm_nat_gateway.nat_gw[each.key].id
  public_ip_address_id = azurerm_public_ip.nat_pip[each.key].id
}

resource "azurerm_subnet_nat_gateway_association" "nat_subnet_assoc" {
  for_each       = var.nat_gateway
  subnet_id      = data.azurerm_subnet.nat_subnet_data[each.key].id
  nat_gateway_id = azurerm_nat_gateway.nat_gw[each.key].id
}
