resource "null_resource" "install_configure_saltminion" {

  connection {
    host     = var.minion_private_dns_name
    type     = "winrm"
    port     = 5985
    https    = false
    timeout  = "5m"
    user     = var.minion_user
    password = var.minion_password
    bastion_host = var.bastion_public_ip_address
    bastion_user = var.bastion_user
    bastion_private_key = file(var.ssh_private_key)
  }
  provisioner "file" {
    source = "${path.module}/script/install-saltminion.ps1"
    destination = "C:/install-saltminion.ps1"
  }
  provisioner "remote-exec" {
    inline = [ 
      "powershell.exe -sta -ExecutionPolicy Unrestricted -file C:/install-saltminion.ps1 ${var.minion_name} ${var.saltmaster_private_dns_name}"
    ]
    on_failure = continue
  }


  provisioner "remote-exec" {
    inline = [
      "sudo salt-key -y -a ${var.minion_name}",
    ]

    connection {
      type = "ssh"
      host = var.saltmaster_private_dns_name
      user = var.saltmaster_user
      private_key = file(var.ssh_private_key)
      timeout = "5m"
      bastion_host = var.bastion_public_ip_address
      bastion_user = var.bastion_user
      bastion_private_key = file(var.ssh_private_key)
    }
  }


  provisioner "remote-exec" {
  when = destroy
  inline = [
    "sudo salt-key -y -d ${var.minion_name}",
  ]

  connection {
    type = "ssh"
    host = var.saltmaster_private_dns_name
    user = var.saltmaster_user
    private_key = file(var.ssh_private_key)
    timeout = "5m"
    bastion_host = var.bastion_public_ip_address
    bastion_user = var.bastion_user
    bastion_private_key = file(var.ssh_private_key)
  }
  }

}
