resource "aws_instance" "public_instance" {
    ami = var.ami_name
    instance_type = "t2.micro"
    subnet_id = aws_subnet.public_subnet.id
    vpc_security_group_ids = [aws_security_group.sg.id]
    availability_zone = "ap-south-1a"
    key_name = aws_key_pair.public_key.key_name
    tags = {
      "Name" = "Frontend-Dev"
    }
}

 resource "aws_key_pair" "public_key" {
   key_name   = "terraform-ssh-key"
   public_key = file("~/.ssh/id_rsa_tf.pub")
 }

resource "aws_security_group" "sg" {
  name = "public_sg_dev"
  vpc_id = aws_vpc.vpc_name.id

  ingress {
    from_port = 22
    to_port = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

ingress {
    from_port = 8080
    to_port = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 8081
    to_port = 8081
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

resource "aws_eip" "lb" {
  instance = aws_instance.public_instance.id
  domain   = "vpc"
}
