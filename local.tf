# Get current public IP
data "http" "my_ip" {
  url = "https://ifconfig.me/ip"
}

locals {
  allowed_ip = "${chomp(data.http.my_ip.response_body)}/32"
}

locals {
  ssh_public_key = file("~/.ssh/id_rsa.pub")
}

resource "aws_key_pair" "chenglimteo" {
  key_name   = var.key_name
  public_key = local.ssh_public_key
}