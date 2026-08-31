data "azurerm_network_interface" "vmdata" {
  for_each            = var.vm
  name                = each.value.nic_name
  resource_group_name = each.value.resource_group_name
}

data "azurerm_key_vault" "kvdata" {
  for_each            = var.vm
  name                = each.value.key_vault_name
  resource_group_name = each.value.resource_group_name
}

data "azurerm_key_vault_secret" "secretdata" {
  for_each     = var.vm
  name         = each.value.secret_name
  key_vault_id = data.azurerm_key_vault.kvdata[each.key].id
}

resource "azurerm_linux_virtual_machine" "vm" {
  for_each                        = var.vm
  name                            = each.value.name
  resource_group_name             = each.value.resource_group_name
  location                        = each.value.location
  size                            = each.value.size
  admin_username                  = each.value.admin_username
  admin_password                  = data.azurerm_key_vault_secret.secretdata[each.key].value
  disable_password_authentication = each.value.disable_password_authentication

  network_interface_ids = [data.azurerm_network_interface.vmdata[each.key].id]

  os_disk {
    caching              = each.value.caching
    storage_account_type = each.value.storage_account_type
  }

  source_image_reference {
    publisher = each.value.publisher
    offer     = each.value.offer
    sku       = each.value.sku
    version   = each.value.version
  }
}