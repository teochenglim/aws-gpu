region          = "ap-southeast-1"
aws_sso_profile = "default"
vpc_cidr        = "10.13.0.0/16"
public_subnet   = "10.13.1.0/24"
allowed_ip      = "115.66.129.211/32"  # Add your actual IP, curl ifconfig.me/ip to get your public IP
key_name        = "chenglimteo"
spot_max_price  = "0.15"