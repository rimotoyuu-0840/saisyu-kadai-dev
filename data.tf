# =====================================
# AWS Managed Prefix Lists
# =====================================

locals {
  # Tokyo region S3 prefix list
  s3_prefix_list_id = "pl-61a54008"
}

data "aws_ami" "app" {
  most_recent = true
  owners      = ["self", "amazon"]

  filter {
    name   = "name"
    values = ["tastylog-*-ami"]
  }
  #   filter {
  #     name   = "name"
  #     values = ["al2023-ami-2023.9.*-kernel-6.1-x86_64"]
  #   }
  #   filter {
  #     name   = "root-device-type"
  #     values = ["ebs"]
  #   }
  #   filter {
  #     name   = "virtualization-type"
  #     values = ["hvm"]
  #   }
}