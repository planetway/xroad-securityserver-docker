# This is an EC2 instance to mount and check the content of EFS.
# install amazon-efs-utils and mount efs to check the content
# https://docs.aws.amazon.com/efs/latest/ug/installing-amazon-efs-utils.html#installing-other-distro
# sudo mount -t efs -o tls fs-b48a3eef:/ /mnt
resource "aws_instance" "test" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  key_name = aws_key_pair.id_rsa.key_name
  vpc_security_group_ids = [
    module.internal_sg.security_group_id
  ]
  subnet_id = tolist(data.aws_subnet_ids.private.ids)[0]
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

output "ec2_instance_private_ip" {
  description = "private IP of the EC2 instance"
  value = aws_instance.test.private_ip
}
