output "secret_value" {
  value     = { for k, v in azurerm_key_vault_secret.vm_secret : k => v.value }
  sensitive = true
}
