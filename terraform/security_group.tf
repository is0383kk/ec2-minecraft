# Minecraft サーバー用のセキュリティグループ定義
# SSH ポートは開放せず、Minecraft の接続ポートのみ許可する

# デフォルト VPC の情報を参照する（新規 VPC は作成しない）
data "aws_vpc" "default" {
  default = true
}

resource "aws_security_group" "minecraft" {
  name        = "minecraft-server-sg"
  description = "Minecraft server security group"
  vpc_id      = data.aws_vpc.default.id

  # Minecraft Java Edition のデフォルトポート（全 IP から接続を許可）
  ingress {
    description = "Minecraft Java Edition"
    from_port   = 25565
    to_port     = 25565
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # アウトバウンドは全許可（パッケージ更新・PaperMC ダウンロード等に必要）
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
