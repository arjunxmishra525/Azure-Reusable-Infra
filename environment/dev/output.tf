output "vm_passwords" {
  value     = module.key_vault.secret_value
  sensitive = true
}
