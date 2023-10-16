resource "aws_vpc" "Abs_vpc" {
  cidr_block           = "10.1.0.0/16"
  enable_dns_hostnames = true



  tags = {
    Name = "dev"
  }
}

resource "aws_subnet" "Abs_public_subnet" {
  vpc_id                  = aws_vpc.Abs_vpc.id
  cidr_block              = "10.1.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"


  tags = {
    Name = "dev-public"
  }

}

resource "aws_internet_gateway" "Abs_internet_gw" {
  vpc_id = aws_vpc.Abs_vpc.id

  tags = {
    Name = "dev-gw"
  }
}


resource "aws_route_table" "Abs_public_rt" {
  vpc_id = aws_vpc.Abs_vpc.id

  tags = {
    Name = "dev_public_rt"
  }
}

resource "aws_route" "r" {
  route_table_id         = aws_route_table.Abs_public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.Abs_internet_gw.id

}


resource "aws_route_table_association" "Abs_public_assoc" {
  subnet_id      = aws_subnet.Abs_public_subnet.id
  route_table_id = aws_route_table.Abs_public_rt.id
}

resource "aws_security_group" "Abs_sg" {
  name        = "dev_sg"
  description = "dev security group"
  vpc_id      = aws_vpc.Abs_vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

resource "aws_key_pair" "Abs_auth" {
  key_name   = "Abs-key"
  public_key = file("~/.ssh/Abskey.pub")

}

resource "aws_instance" "dev_node" {
  instance_type          = "t2.micro"
  ami                    = data.aws_ami.server_ami.id
  key_name               = aws_key_pair.Abs_auth.key_name
  vpc_security_group_ids = [aws_security_group.Abs_sg.id]
  subnet_id              = aws_subnet.Abs_public_subnet.id
  user_data              = file("userdata.tpl")


  root_block_device {
    volume_size = 10
  }

  tags = {
    Name = "dev-node"
  }

  provisioner "local-exec" {
    command = templatefile("${var.host_ops}-ssh-config.tpl", {
      hostname     = self.public_ip,
      user         = "ubuntu",
      identityfile = "~/.ssh/Abskey"

    })
    interpreter = var.host_ops == "windows" ? ["powershell", "-Command"] : ["bash", "-c"]
  }


}