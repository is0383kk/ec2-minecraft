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
  ami                         = data.aws_ami.ubuntu_arm64.id
  instance_type               = var.instance_type
  iam_instance_profile        = aws_iam_instance_profile.minecraft.name
  vpc_security_group_ids      = [aws_security_group.minecraft.id]
  associate_public_ip_address = true

  root_block_device {
    volume_type = "gp3"
    volume_size = 8
  }

  user_data = templatefile("${path.module}/user_data.sh.tftpl", {
    start_sh_content          = file("${path.module}/../scripts/start.sh")
    stop_sh_content           = file("${path.module}/../scripts/stop.sh")
    backup_sh_content         = file("${path.module}/../scripts/backup.sh")
    minecraft_service_content = file("${path.module}/../services/minecraft.service")
    backup_service_content    = file("${path.module}/../services/minecraft-backup.service")
    backup_timer_content      = file("${path.module}/../services/minecraft-backup.timer")
  })

  user_data_replace_on_change = false

  tags = {
    Name = "minecraft-server"
  }
}
