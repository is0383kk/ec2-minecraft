output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.minecraft.id
}

output "public_ip" {
  description = "Minecraft server IP (changes each time the instance starts)"
  value       = aws_instance.minecraft.public_ip
}

output "ssm_connect_command" {
  description = "AWS CLI command to connect via Session Manager"
  value       = "aws ssm start-session --target ${aws_instance.minecraft.id} --region ${var.aws_region}"
}
