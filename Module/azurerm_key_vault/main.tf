data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "kv" {
  for_each                    = var.key_vault
  name                        = each.value.name
  location                    = each.value.location
  resource_group_name         = each.value.resource_group_name
  enabled_for_disk_encryption = lookup(each.value, "enabled_for_disk_encryption", true)
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = lookup(each.value, "soft_delete_retention_days", 7)
  purge_protection_enabled    = lookup(each.value, "purge_protection_enabled", false)
  sku_name                    = lookup(each.value, "sku_name", "standard")

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "Get", "List", "Create", "Delete"
    ]

    secret_permissions = [
      "Get", "List", "Set", "Delete", "Purge", "Recover"
    ]

    storage_permissions = [
      "Get"
    ]
  }
}

resource "azurerm_key_vault_secret" "vm_secret" {
  for_each     = var.key_vault
  name         = each.value.secret_name
  value        = lookup(each.value, "secret_value", "Arjun!@#123")
  key_vault_id = azurerm_key_vault.kv[each.key].id
}
