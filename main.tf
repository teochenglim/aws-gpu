# # Get Ubuntu 22.04 Deep Learning AMI
# https://docs.aws.amazon.com/dlami/latest/devguide/aws-deep-learning-base-gpu-ami-ubuntu-22-04.html
# $ aws ec2 describe-images --region ap-southeast-1 \
#       --owners amazon \
#       --filters 'Name=name,Values=Deep Learning Base OSS Nvidia Driver GPU AMI (Ubuntu 22.04) ????????' 'Name=state,Values=available' \
#       --query 'reverse(sort_by(Images, &CreationDate))[:1].ImageId' \
#       --output text
# ami-0fd15162cb8ee54b8

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
  ami           = data.aws_ami.deep_learning_gpu.id
  instance_type = "g4dn.xlarge"
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

  user_data = <<-EOF
              #!/bin/bash
              # Install NVIDIA GPU exporter
              wget https://github.com/utkuozdemir/nvidia_gpu_exporter/releases/download/v1.3.2/nvidia_gpu_exporter_1.3.2_linux_x86_64.tar.gz
              tar -xzf nvidia_gpu_exporter_*.tar.gz
              sudo mv nvidia_gpu_exporter /usr/local/bin/

              # Create systemd service for GPU exporter
              sudo tee /etc/systemd/system/nvidia_gpu_exporter.service > /dev/null <<SERVICE
              [Unit]
              Description=NVIDIA GPU Metrics Exporter
              After=network.target

              [Service]
              ExecStart=/usr/local/bin/nvidia_gpu_exporter
              Restart=always

              [Install]
              WantedBy=multi-user.target
              SERVICE

              sudo systemctl daemon-reload
              sudo systemctl enable nvidia_gpu_exporter
              sudo systemctl start nvidia_gpu_exporter

              # Install Docker
              sudo apt-get update
              sudo apt-get install -y docker.io
              sudo systemctl enable docker
              sudo systemctl start docker

              # Create Prometheus config
              sudo tee /home/ubuntu/prometheus.yml > /dev/null <<CONFIG
              global:
                scrape_interval: 15s

              scrape_configs:
                - job_name: 'gpu_metrics'
                  static_configs:
                  - targets: ['172.17.0.1:9835']
              CONFIG

              # Install Prometheus
              sudo docker run -d \
                --name=prometheus \
                --network=host \
                -p 9090:9090 \
                -v /home/ubuntu/prometheus.yml:/etc/prometheus/prometheus.yml \
                --restart=always \
                prom/prometheus

              # Restart Prometheus
              sudo docker restart prometheus

              # Install Grafana
              sudo docker run -d \
                --name=grafana \
                -p 3000:3000 \
                --network=host \
                -e "GF_SECURITY_ADMIN_PASSWORD=StrongPassword123!" \
                -e "GF_INSTALL_PLUGINS=grafana-clock-panel" \
                grafana/grafana-oss

              # Install DGCM exporter
              sudo docker run -d \
                --gpus all \
                --cap-add SYS_ADMIN \
                --rm \
                --network=host \
                -p 9400:9400 \
                nvcr.io/nvidia/k8s/dcgm-exporter:4.2.3-4.1.2-ubuntu22.04
              EOF

  tags = {
    Name = "GPU-Grafana-Instance"
  }
}
