resource "aws_instance" "app-server" {
  ami = "ami-0532be01f26a3de55"
  instance_type = "t2.micro"

  tags = {
    "Name": "App-Server1"
  }
}

resource "aws_s3_bucket" "s3_bucket" {
  bucket = "mys3bucket56789234"
}

terraform {
  backend "s3" {
    bucket = "mys3bucket56789234"
    key    = "statefiles/tf"
    region = "us-east-1"
    use_lockfile = true
  }
}