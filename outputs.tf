# Outputs
output "instance_public_ip" {
  value = aws_instance.gpu_spot.public_ip
}

output "grafana_url" {
  value = "http://${aws_instance.gpu_spot.public_ip}:3000"
}

output "prometheus_url" {
  value = "http://${aws_instance.gpu_spot.public_ip}:9090"
}

output "nvidia_exporter" {
  value = "curl http://${aws_instance.gpu_spot.public_ip}:9835/metrics"
}

output "grafana_login_credentials" {
  value = "admin / StrongPassword123!"
}

output "nvidia_smi_check" {
  value = "ssh -i your-key.pem ubuntu@${aws_instance.gpu_spot.public_ip} nvidia-smi"
}