data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-*-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

output "ec2_ami_id" {
  value = data.aws_ami.ubuntu.id
}

resource "tls_private_key" "ec2_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "ec2_key" {
  key_name   = "${var.project_name}-ec2-key"
  public_key = tls_private_key.ec2_key.public_key_openssh
}

resource "local_file" "ec2_key_pem" {
  content         = tls_private_key.ec2_key.private_key_pem
  filename        = "./key.pem"
  file_permission = "0600"
}

output "ec2_key_name" {
  value = aws_key_pair.ec2_key.key_name
}

output "ec2_key_pem_path" {
  value = local_file.ec2_key_pem.filename
}
