output "nlb_dns_name" {
  description = "DNS name of the NLB - send HTTP requests here to test"
  value       = aws_lb.main.dns_name
}

output "bastion_public_ip" {
  description = "Public IP of the bastion host"
  value       = aws_instance.bastion.public_ip
}

output "ecr_app_url" {
  description = "ECR URL for the app image"
  value       = aws_ecr_repository.app.repository_url
}

output "ecr_nginx_url" {
  description = "ECR URL for the nginx image"
  value       = aws_ecr_repository.nginx.repository_url
}

output "ecr_registry" {
  description = "Base URL of the ECR registry"
  value       = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com"
}

output "server_private_ips" {
  description = "Private IPs of the application servers"
  value       = [for i in aws_instance.server : i.private_ip]
}

output "ssh_to_bastion" {
  description = "Command to connect to the bastion host"
  value       = "ssh -i ${var.key_pair_name}.pem ec2-user@${aws_instance.bastion.public_ip}"
}

output "ssh_to_server_via_bastion" {
  description = "Commands to reach the application servers through the bastion"
  value = [
    for i in aws_instance.server :
    "ssh -i ${var.key_pair_name}.pem -J ec2-user@${aws_instance.bastion.public_ip} ec2-user@${i.private_ip}"
  ]
}

output "app_url" {
  description = "Public URL of the application"
  value       = "http://${aws_lb.main.dns_name}"
}

output "region" {
  description = "AWS region the infrastructure is deployed in"
  value       = var.region
}