# Outputs
output "instance_public_ip" {
  value = aws_instance.gpu_spot.public_ip
}

output "grafana_url" {
  value = "http://${aws_instance.gpu_spot.public_ip}:3000"
}

output "grafana_login_credentials" {
  value = "admin / StrongPassword123!"
}

output "prometheus_url" {
  value = "http://${aws_instance.gpu_spot.public_ip}:9090"
}

output "nvidia_exporter" {
  value = "curl http://${aws_instance.gpu_spot.public_ip}:9835/metrics"
}

output "dgcm_nvidia_exporter" {
  value = "curl http://${aws_instance.gpu_spot.public_ip}:9400/metrics"
}

output "ec2_nvidia_smi_check" {
  value = "ssh ubuntu@${aws_instance.gpu_spot.public_ip} nvidia-smi"
}