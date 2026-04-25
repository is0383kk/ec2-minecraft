# terraform apply / terraform output で確認できる出力値の定義

# EC2 インスタンスの ID（aws ec2 start/stop-instances コマンドで使用する）
output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.minecraft.id
}

# Minecraft サーバーの接続先 IP アドレス
# ※ Elastic IP 未使用のため、インスタンス起動のたびに変わる
output "public_ip" {
  description = "Minecraft server IP (changes each time the instance starts)"
  value       = aws_instance.minecraft.public_ip
}

# SSH 不要で EC2 に接続するための Session Manager コマンド
output "ssm_connect_command" {
  description = "AWS CLI command to connect via Session Manager"
  value       = "aws ssm start-session --target ${aws_instance.minecraft.id} --region ${var.aws_region}"
}
