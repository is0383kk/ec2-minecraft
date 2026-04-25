# Session Manager 経由で EC2 に接続するための IAM リソース定義
# SSH キーペア不要でシェル接続できるようにするためのロール構成

# EC2 が引き受ける IAM ロール（AssumeRole で EC2 サービスに委任）
resource "aws_iam_role" "minecraft_ssm" {
  name = "MinecraftEC2SSMRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "ec2.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

# Session Manager の利用に必要な AWS 管理ポリシーをロールにアタッチする
resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.minecraft_ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# EC2 インスタンスに IAM ロールを紐づけるためのインスタンスプロファイル
resource "aws_iam_instance_profile" "minecraft" {
  name = "MinecraftEC2InstanceProfile"
  role = aws_iam_role.minecraft_ssm.name
}
