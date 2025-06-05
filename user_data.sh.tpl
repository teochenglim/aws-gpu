#!/bin/bash
set -euxo pipefail

# Download and install nvidia_gpu_exporter
wget https://github.com/utkuozdemir/nvidia_gpu_exporter/releases/download/v1.3.2/nvidia_gpu_exporter_1.3.2_linux_x86_64.tar.gz
tar -xzf nvidia_gpu_exporter_*.tar.gz
sudo mv nvidia_gpu_exporter /usr/local/bin/

# Write systemd unit for nvidia_gpu_exporter
sudo tee /etc/systemd/system/nvidia_gpu_exporter.service > /dev/null <<'EOT'
[Unit]
Description=NVIDIA GPU Exporter
After=network.target

[Service]
ExecStart=/usr/local/bin/nvidia_gpu_exporter
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOT

# Write Prometheus config
sudo tee /home/ubuntu/prometheus.yml > /dev/null <<'EOT'
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
  - job_name: 'gpu_metrics'
    static_configs:
      - targets: ['172.17.0.1:9835']
  - job_name: 'dcgm_gpu_metrics'
    static_configs:
      - targets: ['172.17.0.1:9400']
EOT
sudo chown ubuntu:ubuntu /home/ubuntu/prometheus.yml

# Prometheus systemd unit with named container
sudo tee /etc/systemd/system/prometheus.service > /dev/null <<'EOT'
[Unit]
Description=Prometheus container
After=docker.service
Requires=docker.service

[Service]
Restart=on-failure
ExecStartPre=-/usr/bin/docker rm -f prometheus-container
ExecStart=/usr/bin/docker run --name=prometheus-container \
  --network=host \
  -p 9090:9090 \
  -v /home/ubuntu/prometheus.yml:/etc/prometheus/prometheus.yml \
  prom/prometheus
ExecStop=/usr/bin/docker stop prometheus-container

[Install]
WantedBy=multi-user.target
EOT

# Grafana systemd unit with named container
sudo tee /etc/systemd/system/grafana.service > /dev/null <<'EOT'
[Unit]
Description=Grafana container
After=docker.service
Requires=docker.service

[Service]
Restart=on-failure
ExecStartPre=-/usr/bin/docker rm -f grafana-container
ExecStart=/usr/bin/docker run --name=grafana-container \
  --network=host \
  -p 3000:3000 \
  -e GF_SECURITY_ADMIN_PASSWORD=StrongPassword123! \
  -e GF_INSTALL_PLUGINS=grafana-clock-panel \
  grafana/grafana-oss
ExecStop=/usr/bin/docker stop grafana-container

[Install]
WantedBy=multi-user.target
EOT

# DCGM exporter systemd unit with named container
sudo tee /etc/systemd/system/dcgm-exporter.service > /dev/null <<'EOT'
[Unit]
Description=DCGM Exporter
After=docker.service
Requires=docker.service

[Service]
Restart=on-failure
ExecStartPre=-/usr/bin/docker rm -f dcgm-exporter-container
ExecStart=/usr/bin/docker run --name=dcgm-exporter-container \
  --gpus all \
  --cap-add SYS_ADMIN \
  --network=host \
  -p 9400:9400 \
  nvcr.io/nvidia/k8s/dcgm-exporter:4.1.1-4.0.4-ubuntu22.04
ExecStop=/usr/bin/docker stop dcgm-exporter-container

[Install]
WantedBy=multi-user.target
EOT

# Ollama systemd unit with named container
sudo tee /etc/systemd/system/ollama.service > /dev/null <<'EOT'
[Unit]
Description=Ollama container
After=docker.service
Requires=docker.service

[Service]
Restart=on-failure
ExecStartPre=-/usr/bin/docker rm -f ollama-container
ExecStart=/usr/bin/docker run --name=ollama-container \
  --gpus all \
  -v ollama-data:/root/.ollama \
  -p 11434:11434 \
  ollama/ollama
ExecStop=/usr/bin/docker stop ollama-container

[Install]
WantedBy=multi-user.target
EOT

# Reload and enable all services
sudo systemctl daemon-reexec
sudo systemctl daemon-reload

sudo systemctl enable nvidia_gpu_exporter
sudo systemctl enable prometheus
sudo systemctl enable grafana
sudo systemctl enable dcgm-exporter
sudo systemctl enable ollama

sudo systemctl start nvidia_gpu_exporter
sudo systemctl start prometheus
sudo systemctl start grafana
sudo systemctl start dcgm-exporter
sudo systemctl start ollama

# Wait for Ollama to start
sleep 10

# Pull the Qwen3:0.6b model using the container name
sudo docker exec ollama-container ollama pull qwen3:0.6b

sudo tee /home/ubuntu/pull_ollama.sh > /dev/null <<'EOT'
#!/bin/bash
sudo docker exec ollama-container ollama pull qwen3:0.6b
EOT

# Create a test script to verify Ollama is working
sudo tee /home/ubuntu/test_ollama.sh > /dev/null <<'EOT'
#!/bin/bash
echo "Testing Ollama with Qwen3:0.6b model..."
response=$(curl -s -X POST http://localhost:11434/api/generate -d '{
  "model": "qwen3:0.6b",
  "prompt": "Why is the sky blue?",
  "stream": false
}')

echo "Response from Ollama:"
echo "$response" | jq .

echo -e "\nContainer status:"
sudo docker ps -f "name=ollama-container" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
EOT

sudo chmod +x /home/ubuntu/test_ollama.sh
sudo chown ubuntu:ubuntu /home/ubuntu/test_ollama.sh

# Create management scripts for all containers
sudo tee /home/ubuntu/container-management.sh > /dev/null <<'EOT'
#!/bin/bash
case "$1" in
  start)
    echo "Starting containers..."
    sudo systemctl start prometheus grafana dcgm-exporter ollama
    ;;
  stop)
    echo "Stopping containers..."
    sudo docker stop prometheus-container grafana-container dcgm-exporter-container ollama-container
    ;;
  status)
    echo "Container status:"
    sudo docker ps -a --filter "name=-container" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    ;;
  *)
    echo "Usage: $0 {start|stop|status}"
    exit 1
    ;;
esac
EOT

sudo chmod +x /home/ubuntu/container-management.sh
sudo chown ubuntu:ubuntu /home/ubuntu/container-management.sh

