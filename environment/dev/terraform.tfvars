RG = {
  RG1 = {
    name     = "VNET-RG"
    location = "Central India"
  }
}

vnet = {
  vnet1 = {
    name                = "dev-vent-arjun-private"
    location            = "central India"
    resource_group_name = "VNET-RG"
    address_space       = ["10.20.0.0/16", "10.10.0.0/16"]
  }
}

subnet = {
  subnet1 = {
    name                 = "private_subnet_frontend"
    resource_group_name  = "VNET-RG"
    virtual_network_name = "dev-vent-arjun-private"
    address_prefixes     = ["10.20.3.0/24", "10.10.10.0/24"]
  }
  subnet2 = {
    name                 = "AzureBastionSubnet"
    resource_group_name  = "VNET-RG"
    virtual_network_name = "dev-vent-arjun-private"
    address_prefixes     = ["10.10.12.0/26"]
  }
  subnet3 = {
    name                 = "appgw_subnet"
    resource_group_name  = "VNET-RG"
    virtual_network_name = "dev-vent-arjun-private"
    address_prefixes     = ["10.20.4.0/24"]
  }
}

nsg = {
  nsg1 = {
    name                       = "dev-nsg"
    location                   = "Central India"
    resource_group_name        = "VNET-RG"
    rule_name                  = "SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = 22
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

nic_card = {
  nic1 = {
    subnet_name          = "private_subnet_frontend"
    name                 = "dev-nic"
    location             = "central India"
    resource_group_name  = "VNET-RG"
    virtual_network_name = "dev-vent-arjun-private"
    ip_name              = "internal"
    private_ip_address   = "Dynamic"
  }
}

association = {
  association1 = {
    nic_name            = "dev-nic"
    nsg_name            = "dev-nsg"
    resource_group_name = "VNET-RG"
  }
}

public_ip = {
  public_ip1 = {
    name                = "Dev-PublicIP"
    resource_group_name = "VNET-RG"
    location            = "Central India"
    allocation_method   = "Static"
    name1               = "LB_Public_IP"
  }
}

bastion = {
  bastion1 = {
    public_name          = "Dev-PublicIP"
    resource_group_name  = "VNET-RG"
    virtual_network_name = "dev-vent-arjun-private"
    config_name          = "Bastionhost"
    location             = "Central India"
    name                 = "Bastion_Consle_SSH"
  }
}

vm = {
  vm1 = {
    name                            = "Dev-machine"
    resource_group_name             = "VNET-RG"
    location                        = "Central India"
    size                            = "Standard_D2s_v3"
    admin_username                  = "adminuser"
    key_vault_name                  = "dev-landing-kv-arjun"
    secret_name                     = "vm-admin-password"
    disable_password_authentication = false
    nic_name                        = "dev-nic"
    caching                         = "ReadWrite"
    storage_account_type            = "Standard_LRS"
    publisher                       = "Canonical"
    offer                           = "0001-com-ubuntu-server-jammy"
    sku                             = "22_04-lts"
    version                         = "latest"
  }
}

key_vault = {
  kv1 = {
    name                = "dev-landing-kv-arjun"
    location            = "Central India"
    resource_group_name = "VNET-RG"
    secret_name         = "vm-admin-password"
    secret_value        = "Arjun!@#123"
  }
}

nat_gateway = {
  nat1 = {
    name                 = "dev-nat-gateway"
    public_ip_name       = "NAT-PublicIP"
    location             = "Central India"
    resource_group_name  = "VNET-RG"
    subnet_name          = "private_subnet_frontend"
    virtual_network_name = "dev-vent-arjun-private"
  }
}

app_gateway = {
  appgw1 = {
    name                 = "dev-app-gateway"
    public_ip_name       = "AppGW-PublicIP"
    location             = "Central India"
    resource_group_name  = "VNET-RG"
    subnet_name          = "appgw_subnet"
    virtual_network_name = "dev-vent-arjun-private"
    backend_nic_name     = "dev-nic"
  }
}

