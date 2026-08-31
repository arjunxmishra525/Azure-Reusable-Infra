data "azurerm_subnet" "subnetdata" {
  for_each             = var.nic_card
  name                 = each.value.subnet_name
  virtual_network_name = each.value.virtual_network_name
  resource_group_name  = each.value.resource_group_name
}

resource "azurerm_network_interface" "nic" {
  for_each            = var.nic_card
  name                = each.value.name
  location            = each.value.location
  resource_group_name = each.value.resource_group_name

  ip_configuration {
    name                          = each.value.ip_name
    subnet_id                     = data.azurerm_subnet.subnetdata[each.key].id
    private_ip_address_allocation = each.value.private_ip_address
    # private_ip_address = each.value.private_ip_address

  }
}