# EC2 インスタンスおよび AMI の定義

# Canonical 公式の Ubuntu 24.04 LTS（ARM64）の最新 AMI を動的に取得する
# owners の "099720109477" は Canonical の AWS アカウント ID
data "aws_ami" "ubuntu_arm64" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-arm64-server-*"]
  }

  filter {
    name   = "architecture"
    values = ["arm64"]
  }
}

resource "aws_instance" "minecraft" {
  # ARM64 対応 AMI（t4g 系インスタンスと組み合わせることでコスト削減）
  ami                         = data.aws_ami.ubuntu_arm64.id
  instance_type               = var.instance_type
  # Session Manager 接続用の IAM インスタンスプロファイルを付与
  iam_instance_profile        = aws_iam_instance_profile.minecraft.name
  vpc_security_group_ids      = [aws_security_group.minecraft.id]
  # パブリック IP を付与（Minecraft クライアントからの接続に必要）
  associate_public_ip_address = true

  root_block_device {
    # gp3 は gp2 より低コストで高スループット
    volume_type = "gp3"
    volume_size = 8
  }

  # 初回起動時にサーバーセットアップを自動実行するシェルスクリプトをテンプレートから生成
  # scripts/ と services/ の各ファイルをインラインで埋め込んでいる
  user_data = templatefile("${path.module}/user_data.sh.tftpl", {
    start_sh_content          = file("${path.module}/../scripts/start.sh")
    stop_sh_content           = file("${path.module}/../scripts/stop.sh")
    backup_sh_content         = file("${path.module}/../scripts/backup.sh")
    minecraft_service_content = file("${path.module}/../services/minecraft.service")
    backup_service_content    = file("${path.module}/../services/minecraft-backup.service")
    backup_timer_content      = file("${path.module}/../services/minecraft-backup.timer")
    whitelist_json_content    = fileexists("${path.module}/../config/whitelist.json") ? file("${path.module}/../config/whitelist.json") : ""
  })

  # user_data 変更時にインスタンスを自動再作成しない
  # scripts/ や services/ を変更した場合は terraform apply で手動再作成が必要
  user_data_replace_on_change = false

  tags = {
    Name = "minecraft-server"
  }
}
