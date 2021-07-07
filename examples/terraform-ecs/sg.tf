module "internal_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "allow-internal"
  description = "Allow internal traffic"
  vpc_id      = data.aws_vpc.this.id

  ingress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 65535
      protocol    = "tcp"
      description = "internal traffic"
      cidr_blocks = data.aws_vpc.this.cidr_block
    }
  ]
  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 65535
      protocol    = "tcp"
      description = "outbound open tcp traffic"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 0
      to_port     = 65535
      protocol    = "udp"
      description = "outbound open udp traffic"
      cidr_blocks = "0.0.0.0/0"
    }
  ]
}

module "efs_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "efs-nfs"
  description = "NFS"
  vpc_id      = data.aws_vpc.this.id

  computed_ingress_with_source_security_group_id = [
    {
      from_port   = 2049
      to_port     = 2049
      protocol    = "tcp"
      description = "NFS"
      source_security_group_id = module.internal_sg.security_group_id
    }
  ]
  number_of_computed_ingress_with_source_security_group_id = 1
}
