resource "aws_instance" "app-server" {
  ami = "ami-0532be01f26a3de55"
  instance_type = "t2.micro"

  tags = {
    "Name": "App-Server"
  }
}

