# Get current public IP
data "http" "my_ip" {
  url = "https://ifconfig.me/ip"
}

locals {
  allowed_ip = var.allowed_ip != "" ? var.allowed_ip : "${chomp(data.http.my_ip.response_body)}/32"
}