data "azurerm_network_interface" "nicdata" {
  for_each            = var.association
  name                = each.value.nic_name
  resource_group_name = each.value.resource_group_name
}

data "azurerm_network_security_group" "nsgdata" {
  for_each            = var.association
  name                = each.value.nsg_name
  resource_group_name = each.value.resource_group_name
}

resource "azurerm_network_interface_security_group_association" "nsgassociation" {
  for_each                  = var.association
  network_interface_id      = data.azurerm_network_interface.nicdata[each.key].id
  network_security_group_id = data.azurerm_network_security_group.nsgdata[each.key].id
}

