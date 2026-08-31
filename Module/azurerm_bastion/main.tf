data "azurerm_public_ip" "pipdata" {
  for_each            = var.bastion
  name                = each.value.public_name
  resource_group_name = each.value.resource_group_name
}

data "azurerm_subnet" "subnetdata1" {
  for_each             = var.bastion
  name                 = "AzureBastionSubnet"
  virtual_network_name = each.value.virtual_network_name
  resource_group_name  = each.value.resource_group_name
}



resource "azurerm_bastion_host" "bzhost" {
  for_each            = var.bastion
  name                = each.value.name
  location            = each.value.location
  resource_group_name = each.value.resource_group_name

  ip_configuration {
    name                 = each.value.config_name
    subnet_id            = data.azurerm_subnet.subnetdata1[each.key].id
    public_ip_address_id = data.azurerm_public_ip.pipdata[each.key].id
  }
}
