# Outputs
output "instance_public_ip" {
  value = aws_instance.gpu_spot.public_ip
}

output "grafana_url" {
  value = "http://${aws_instance.gpu_spot.public_ip}:3000"
}

output "login_credentials" {
  value = "admin / StrongPassword123!"
}

output "nvidia_smi_check" {
  value = "ssh -i your-key.pem ubuntu@${aws_instance.gpu_spot.public_ip} nvidia-smi"
}