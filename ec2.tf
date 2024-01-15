data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "description"
    values = ["Amazon Linux 2023 *"]
  }
}

resource "aws_instance" "example" {
  ami           = data.aws_ami.amazon_linux_2023.id
  instance_type = "t3.nano"

  tags = {
    Name = "HelloWorld"
  }
}