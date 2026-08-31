data "azurerm_subnet" "appgw_subnet_data" {
  for_each             = var.app_gateway
  name                 = each.value.subnet_name
  virtual_network_name = each.value.virtual_network_name
  resource_group_name  = each.value.resource_group_name
}

data "azurerm_network_interface" "backend_nic_data" {
  for_each            = var.app_gateway
  name                = each.value.backend_nic_name
  resource_group_name = each.value.resource_group_name
}

resource "azurerm_public_ip" "appgw_pip" {
  for_each            = var.app_gateway
  name                = each.value.public_ip_name
  location            = each.value.location
  resource_group_name = each.value.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_application_gateway" "appgw" {
  for_each            = var.app_gateway
  name                = each.value.name
  resource_group_name = each.value.resource_group_name
  location            = each.value.location

  sku {
    name     = lookup(each.value, "sku_name", "Standard_v2")
    tier     = lookup(each.value, "sku_tier", "Standard_v2")
    capacity = lookup(each.value, "capacity", 2)
  }

  gateway_ip_configuration {
    name      = "appGatewayIpConfig"
    subnet_id = data.azurerm_subnet.appgw_subnet_data[each.key].id
  }

  frontend_port {
    name = "frontendPort"
    port = 80
  }

  frontend_ip_configuration {
    name                 = "frontendIpConfig"
    public_ip_address_id = azurerm_public_ip.appgw_pip[each.key].id
  }

  backend_address_pool {
    name         = "backendPool"
    ip_addresses = [data.azurerm_network_interface.backend_nic_data[each.key].private_ip_address]
  }

  backend_http_settings {
    name                  = "httpSettings"
    cookie_based_affinity = "Disabled"
    path                  = "/"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
  }

  http_listener {
    name                           = "httpListener"
    frontend_ip_configuration_name = "frontendIpConfig"
    frontend_port_name             = "frontendPort"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "requestRoutingRule"
    rule_type                  = "Basic"
    http_listener_name         = "httpListener"
    backend_address_pool_name  = "backendPool"
    backend_http_settings_name = "httpSettings"
    priority                   = 100
  }
}
