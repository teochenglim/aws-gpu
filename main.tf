# # Get Ubuntu 22.04 Deep Learning AMI
# https://docs.aws.amazon.com/dlami/latest/devguide/aws-deep-learning-base-gpu-ami-ubuntu-22-04.html
# $ aws ec2 describe-images --region ap-southeast-1 \
#       --owners amazon \
#       --filters 'Name=name,Values=Deep Learning Base OSS Nvidia Driver GPU AMI (Ubuntu 22.04) ????????' 'Name=state,Values=available' \
#       --query 'reverse(sort_by(Images, &CreationDate))[:1].ImageId' \
#       --output text
# ami-0fd15162cb8ee54b8
# aws ssm get-parameter --region ap-southeast-1 \
#     --name /aws/service/deeplearning/ami/x86_64/base-oss-nvidia-driver-gpu-ubuntu-22.04/latest/ami-id \
#     --query "Parameter.Value" \
#     --output text
# ami-0fd15162cb8ee54b8

data "aws_ssm_parameter" "gpu_ami" {
  name = "/aws/service/deeplearning/ami/x86_64/base-oss-nvidia-driver-gpu-ubuntu-22.04/latest/ami-id"
}

data "aws_ami" "deep_learning_gpu" {
  owners      = ["amazon"]
  most_recent = true

  filter {
    name   = "name"
    values = ["Deep Learning Base OSS Nvidia Driver GPU AMI (Ubuntu 22.04) *"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# GPU Spot Instance with Grafana
resource "aws_instance" "gpu_spot" {
  ami           = data.aws_ami.deep_learning_gpu.id # data.aws_ssm_parameter.gpu_ami.value
  instance_type = var.instance_type # "g4dn.xlarge"
  # g4dn.xlarge: https://instances.vantage.sh/aws/ec2/g4dn.xlarge?region=ap-southeast-1
  # NVIDIA T4: https://aws.amazon.com/blogs/aws/now-available-ec2-instances-g4-with-nvidia-t4-tensor-core-gpus/
  subnet_id     = aws_subnet.public_subnet.id
  key_name      = var.key_name

  # Spot configuration
  instance_market_options {
    market_type = "spot"
    spot_options {
      max_price = var.spot_max_price
    }
  }

  vpc_security_group_ids = [aws_security_group.gpu_sg.id]
  user_data = templatefile("user_data.sh.tpl", {})

  tags = {
    Name = "GPU-Grafana-Instance"
  }
}
