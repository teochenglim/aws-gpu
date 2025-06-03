region          = "ap-southeast-1"     # Change this to your desired AWS region
aws_sso_profile = "default"            # Change this to your AWS SSO profile name if needed
vpc_cidr        = "10.14.0.0/16"       # Change this to your desired VPC CIDR
public_subnet   = "10.14.1.0/24"       # Change this to your desired public subnet CIDR
allowed_ip      = "115.66.129.211/32"  # Add your actual IP, curl ifconfig.me/ip to get your public IP
key_name        = "chenglimteo"        # Change this to your EC2 key pair name
spot_max_price  = "0.15"               # Change this to your desired spot instance max price