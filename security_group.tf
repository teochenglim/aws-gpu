# Security Group
resource "aws_security_group" "gpu_sg" {
  name        = "gpu-security-group"
  description = "Allow limited access to GPU instance"
  vpc_id      = aws_vpc.gpu_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [local.allowed_ip]
  }

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = [local.allowed_ip]
  }

  ingress {
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = [local.allowed_ip]
  }

  ingress {
    from_port   = 9835
    to_port     = 9835
    protocol    = "tcp"
    cidr_blocks = [local.allowed_ip]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "GPU-SG"
  }
}