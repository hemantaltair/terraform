resource "null_resource" "install_configure_saltminion" {

  connection {
    host     = "52.168.111.127"
    type     = "winrm"
    port     = 5985
    https    = false
    timeout  = "5m"
    user     = "saltmaster"
    password = "altair@123456"
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
      "powershell.exe -sta -ExecutionPolicy Unrestricted -file C:/install-saltminion.ps1 hemant 10.4.2.4"
    ]
  }


  provisioner "remote-exec" {
    inline = [
      "sudo salt-key -y -a hemant",
    ]

    connection {
      type = "ssh"
      host = "10.4.2.4"
      user = "saltmaster"
      private_key = file(var.ssh_private_key)
      timeout = "5m"
      bastion_host = var.bastion_public_ip_address
      bastion_user = var.bastion_user
      bastion_private_key = file(var.ssh_private_key)
    }
  }


  provisioner "remote-exec" {
    when = "destroy"

    inline = [
      "salt-key -y -d '${element(profitbricks_server.db.*.name, count.index)}*'",
    ]

    connection {
      private_key         = "${file(var.ssh_private_key)}"
      host                = "${profitbricks_server.saltmaster.primary_ip}"
      bastion_host        = "${profitbricks_server.bastion.primary_ip}"
      bastion_user        = "root"
      bastion_private_key = "${file(var.ssh_private_key)}"
      timeout             = "4m"
    }
  }


}
