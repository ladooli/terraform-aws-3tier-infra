resource "tls_private_key" "main" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "main" {
  key_name   = "${var.project_name}-key"
  public_key = tls_private_key.main.public_key_openssh
}

resource "local_file" "private_key" {
  content         = tls_private_key.main.private_key_pem
  filename        = "${path.module}/../${var.project_name}-key.pem"
  file_permission = "0600"
}

resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = var.bastion_instance_type
  subnet_id                   = aws_subnet.public[0].id
  vpc_security_group_ids      = [aws_security_group.bastion.id]
  key_name                    = aws_key_pair.main.key_name
  associate_public_ip_address = true

  tags = {
    Name = "${var.project_name}-bastion"
  }
}


resource "aws_instance" "server" {
  count                  = length(aws_subnet.private_server)
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.ec2_instance_type
  subnet_id              = aws_subnet.private_server[count.index].id
  vpc_security_group_ids = [aws_security_group.server.id]
  key_name               = aws_key_pair.main.key_name
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  user_data = templatefile("${path.module}/templates/user_data.sh.tpl", {
    ecr_registry   = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com"
    ecr_app_repo   = aws_ecr_repository.app.repository_url
    ecr_nginx_repo = aws_ecr_repository.nginx.repository_url
    region         = var.region
  })

  depends_on = [aws_nat_gateway.main]

  tags = {
    Name = "${var.project_name}-server-${count.index + 1}"
  }
}
