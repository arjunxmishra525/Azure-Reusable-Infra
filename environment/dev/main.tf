module "Rg" {
  source = "../../Module/azurerm_resource_group"
  RG     = var.RG
}

module "VNET" {
  depends_on = [module.Rg]
  source     = "../../Module/azurerm_virtual_network"
  vnet       = var.vnet
}

module "subnet" {
  depends_on = [module.VNET]
  source     = "../../Module/azurerm_subnet"
  subnet     = var.subnet
}

module "nsg" {
  depends_on = [module.Rg]
  source     = "../../Module/azurerm_NSG"
  nsg        = var.nsg
}

module "nic" {
  depends_on = [module.subnet]
  source     = "../../Module/azurerm_NIC"
  nic_card   = var.nic_card
}

module "nic_nsg_asso" {
  depends_on  = [module.nic]
  source      = "../../Module/azurerm_NIC+NSG_Assocition"
  association = var.association
}

module "pip" {
  depends_on = [module.Rg]
  source     = "../../Module/azurerm_PublicIP"
  public_ip  = var.public_ip
}

module "bastion" {
  depends_on = [module.subnet]
  source     = "../../Module/azurerm_bastion"
  bastion    = var.bastion
}

module "key_vault" {
  depends_on = [module.Rg]
  source     = "../../Module/azurerm_key_vault"
  key_vault  = var.key_vault
}

module "vm" {
  depends_on = [module.nic, module.key_vault]
  source     = "../../Module/azurerm_Virtual_Machine"
  vm         = var.vm
}

module "nat_gateway" {
  depends_on  = [module.subnet]
  source      = "../../Module/azurerm_nat_gateway"
  nat_gateway = var.nat_gateway
}

module "app_gateway" {
  depends_on  = [module.subnet, module.nic]
  source      = "../../Module/azurerm_application_gateway"
  app_gateway = var.app_gateway
}