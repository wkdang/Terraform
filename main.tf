# Configure the Microsoft Azure Provider
provider "azurerm" {
  version = "1.30.1"
}

provider "azuread" {
 version = "~> 0.3"

}

variable "prefix" {
  default = "tfvmex"
}

variable "appname" {
  default = "azterraform"
}


data "azurerm_subscription" "primary" {
}

data "azurerm_client_config" "current" {}


resource "azuread_application" "auth" {
 name = "${var.appname}"
}

resource "azuread_service_principal" "auth" {
  application_id = "${azuread_application.auth.application_id}"
}

resource "random_string" "password" {
  length = 16
  special = true
  override_special = "/@\" "
}

resource "azuread_service_principal_password" "auth" {
  service_principal_id = "${azuread_service_principal.auth.id}"
  value                = "${random_string.password.result}"
  end_date_relative    = "240h"
}


resource "azurerm_resource_group" "main" {
  name     = "${var.prefix}-resources"
  location = "francecentral"
}

resource "azurerm_virtual_network" "main" {
  name                = "${var.prefix}-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefix       = "10.0.2.0/24"
}

resource "azurerm_public_ip" "main" {
  name                = "${var.prefix}-pip"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  public_ip_address_allocation = "Static"
  domain_name_label            = "${var.prefix}-dns"

  idle_timeout_in_minutes = 30

}

resource "azurerm_network_interface" "main" {
  depends_on          = [azurerm_public_ip.main]
  name                = "${var.prefix}-nic"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "testconfiguration1"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.main.id
}
}


resource "azurerm_virtual_machine" "main" {
  name                  = "${var.prefix}-vm"
  location              = azurerm_resource_group.main.location
  resource_group_name   = azurerm_resource_group.main.name
  network_interface_ids = [azurerm_network_interface.main.id]
  vm_size               = "Standard_DS1_v2"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  # delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  # delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
  }
  os_profile {
    computer_name  = "tfvmex"
    admin_username = "terraform"
    admin_password = "Welcome123456"
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  tags = {
    environment = "staging"
  }
}



resource "azurerm_virtual_machine_extension" "main" {
  name                 = "PostOp"  
  virtual_machine_name = "${azurerm_virtual_machine.main.name}"
  location 	       = "${azurerm_virtual_machine.main.location}"
  resource_group_name  = "${azurerm_virtual_machine.main.resource_group_name}"
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

  settings = <<SETTINGS
    {
  
         "fileUris": [ "https://raw.githubusercontent.com/wkdang/Terraform/master/Terraform_ansible.sh" ],
         "commandToExecute": "sh Terraform_ansible.sh ${data.azurerm_subscription.primary.id} ${azuread_application.auth.application_id} ${azuread_application.auth.homepage} ${azuread_service_principal_password.auth.id} ${data.azurerm_client_config.current.tenant_id}"

    }   

SETTINGS


  tags = {
    environment = "Production"
  }
}



















