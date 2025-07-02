provider "aws" {
  region = "us-east-1"
}

variable "private_key" {
  description = "SSH private key content"
  type        = string
}

resource "aws_key_pair" "deployer" {
  key_name   = "my-key"
  public_key = file("${path.module}/id_rsa.pub")
}

resource "aws_instance" "web" {
  ami           = "ami-0c02fb55956c7d316" # Amazon Linux 2 AMI
  instance_type = "t2.micro"
  key_name      = aws_key_pair.deployer.key_name

  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",
      "sudo amazon-linux-extras install docker -y",
      "sudo service docker start",
      "sudo usermod -a -G docker ec2-user",
      "docker run -d -p 80:80 imranbashir34011/static-website:latest"
    ]

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = var.private_key
      host        = self.public_ip
    }
  }

  tags = {
    Name = "MyDockerWebServer"
  }
}

output "public_ip" {
  value = aws_instance.web.public_ip
}

