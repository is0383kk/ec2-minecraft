data "aws_vpc" "default" {
  default = true
}

resource "aws_security_group" "minecraft" {
  name        = "minecraft-server-sg"
  description = "Minecraft server security group"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "Minecraft Java Edition"
    from_port   = 25565
    to_port     = 25565
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
