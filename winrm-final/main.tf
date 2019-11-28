resource "azurerm_resource_group" "winrm" {
  name     = "winrm"
  location = "eastus"

}

resource "azurerm_virtual_network" "winrm" {
  name                = "winrm"
  location            = "eastus"
  resource_group_name = "winrm"
  address_space       = ["10.0.0.0/16"] 

}

module "bastion-to-winrm-peering" {
  source                         = "../modules/azure_peering"
  virtual_network_peering_name   = "bastion-to-winrm"
  resource_group_name            = "bastion"
  virtual_network_name           = "a365-bastion-prod-network"
  remote_virtual_network_id      = azurerm_virtual_network.winrm.id
  allow_virtual_network_access   = "true"
}

module "license-server-to-bastion-peering" {
  source                         = "../modules/azure_peering"
  virtual_network_peering_name   = "license-server-to-bastion"
  resource_group_name            = "winrm"
  virtual_network_name           = azurerm_virtual_network.winrm.name
  remote_virtual_network_id      = "/subscriptions/2da5fd81-ee52-47c3-b7b4-a2fe97db421d/resourceGroups/bastion/providers/Microsoft.Network/virtualNetworks/a365-bastion-prod-network"
  allow_virtual_network_access   = "false"
}

resource "azurerm_subnet" "winrm" {
  name                 = "winrm"
  resource_group_name  = "winrm"
  address_prefix       = "10.0.2.0/24"
  virtual_network_name = "winrm"
}


resource "azurerm_network_security_group" "winrm" {
  name                = "winrm"
  location            = "eastus"
  resource_group_name = "winrm"

  security_rule {
    name                       = "RDP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "10.3.1.4"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "WinRM"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5985"
    source_address_prefix      = "10.3.1.4"
    destination_address_prefix = "*"
  }
}


resource "azurerm_network_interface" "winrm" {
  name                = "winrm"
  location            = "eastus"
  resource_group_name = "winrm"
  network_security_group_id = "${azurerm_network_security_group.winrm.id}"

  ip_configuration {
    name                          = "winrm"
    subnet_id                     = "${azurerm_subnet.winrm.id}"
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.2.4"
  }

}

resource "azurerm_virtual_machine" "winrm" {
    name                  = "winrm"
    location              = "eastus"
    resource_group_name   = "winrm"
    network_interface_ids = ["${azurerm_network_interface.winrm.id}"]
    vm_size               = "Standard_D4s_v3"

    storage_os_disk {
        name              = "winrm"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Standard_LRS"
    }

    storage_image_reference {
      publisher = "MicrosoftWindowsServer"  
      offer     = "WindowsServer"  
      sku       = "2016-Datacenter"  
      version   = "latest"  
    }  

    os_profile {
      computer_name  = "winrm"  
      admin_username = "${var.admin_username}"
      admin_password = "${var.admin_password}"
      custom_data    = file("./files/winrm.ps1")
    }  

    # os_profile_secrets {
    #   source_vault_id  = "/subscriptions/2da5fd81-ee52-47c3-b7b4-a2fe97db421d/resourceGroups/winrm/providers/Microsoft.KeyVault/vaults/win" 
       
    #   vault_certificates {
    #     certificate_url = "https://win.vault.azure.net/secrets/winrm/609bba8bf89a4729bc5cb2261c7901a2"
    #     certificate_store = "My"
    #   }
    # }

    os_profile_windows_config {
    provision_vm_agent = "true"
    winrm {
      protocol = "http"
    }
      # Auto-Login's required to configure WinRM
    additional_unattend_config {
      pass         = "oobeSystem"
      component    = "Microsoft-Windows-Shell-Setup"
      setting_name = "AutoLogon"
      content      = "<AutoLogon><Password><Value>${var.admin_password}</Value></Password><Enabled>true</Enabled><LogonCount>1</LogonCount><Username>${var.admin_username}</Username></AutoLogon>"
    }

    # Unattend config is to enable basic auth in WinRM, required for the provisioner stage.
    additional_unattend_config {
      pass         = "oobeSystem"
      component    = "Microsoft-Windows-Shell-Setup"
      setting_name = "FirstLogonCommands"
      content      = file("./files/FirstLogonCommands.xml")
    }
    }



    # os_profile_windows_config {
    #   enable_automatic_upgrades = true  
    #   provision_vm_agent        = true  
    
    #   winrm {
    #     protocol = "https"
    #     certificate_url = "https://win.vault.azure.net/secrets/windows/609bba8bf89a4729bc5cb2261c7901a2"
    #   }
    #   winrm {
    #     protocol = "http"
    #   }

    # }
}

module "saltmaster-to-license-server-peering" {
  source                         = "../modules/azure_peering"
  virtual_network_peering_name   = "saltmaster-to-winrm"
  resource_group_name            = "saltmaster"
  virtual_network_name           = "a365-earth-saltmaster-network"
  remote_virtual_network_id      = azurerm_virtual_network.winrm.id
  allow_virtual_network_access   = "true"
}

module "license-server-to-saltmaster-peering" {
  source                         = "../modules/azure_peering"
  virtual_network_peering_name   = "winrm-to-saltmaster"
  resource_group_name            = "winrm"
  virtual_network_name           = "winrm"
  remote_virtual_network_id      = "/subscriptions/2da5fd81-ee52-47c3-b7b4-a2fe97db421d/resourceGroups/saltmaster/providers/Microsoft.Network/virtualNetworks/a365-earth-saltmaster-network"
  allow_virtual_network_access   = "true"
}


module "minion" {
  source                      = "../modules/windows_saltminion_final"
}