output "instance_id" {
  description = "The Jenkins server instance ID."
  value       = aws_instance.jenkins_server.id
}

output "public_ip" {
  description = "The public IP address of the Jenkins server."
  value       = aws_eip.jenkins_ip.public_ip
}