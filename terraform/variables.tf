# Terraform 変数の定義ファイル
# terraform.tfvars や -var フラグで上書き可能

# リソースをデプロイする AWS リージョン（デフォルト: 東京）
variable "aws_region" {
  type        = string
  description = "AWS region to deploy resources"
  default     = "ap-northeast-1"
}

# EC2 インスタンスタイプ（デフォルト: t4g.small = ARM64 の低コスト 2vCPU/2GB RAM）
variable "instance_type" {
  type        = string
  description = "EC2 instance type"
  default     = "t4g.small"
}
