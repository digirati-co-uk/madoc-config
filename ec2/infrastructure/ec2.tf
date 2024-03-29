# IAM
data "aws_iam_policy_document" "assume_role_policy_ec2" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "madoc" {
  name               = "${var.prefix}-${terraform.workspace}-madoc"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy_ec2.json
}

data "aws_iam_policy_document" "madoc_abilities" {
  statement {
    actions = [
      "ssm:DescribeParameters",
      "ssm:GetParameter*",
      "ssm:List*"
    ]

    resources = [
      "arn:aws:ssm:${var.region}:${local.account_id}:parameter/madoc/${var.prefix}/${terraform.workspace}*",
    ]
  }
}

resource "aws_iam_policy" "madoc_abilities" {
  name        = "${var.prefix}-${terraform.workspace}-madoc-abilities"
  description = "Policy for madoc EC2 user-data (read parameterStore)"
  policy      = data.aws_iam_policy_document.madoc_abilities.json
}

resource "aws_iam_role_policy_attachment" "basic_abilities" {
  role       = aws_iam_role.madoc.name
  policy_arn = aws_iam_policy.madoc_abilities.arn
}

resource "aws_iam_instance_profile" "madoc" {
  name = "${var.prefix}-${terraform.workspace}-madoc-instance"
  role = aws_iam_role.madoc.name
}

# keypair
data "template_file" "public_key" {
  template = file("./files/key.pub")
}

resource "aws_key_pair" "auth" {
  key_name   = "${var.prefix}-${terraform.workspace}"
  public_key = data.template_file.public_key.rendered
}

# EC2 Instance
resource "aws_instance" "madoc" {
  ami           = local.ami
  instance_type = var.instance_type

  vpc_security_group_ids = [
    aws_security_group.web.id,
    aws_security_group.ssh.id
  ]
  subnet_id = aws_subnet.public.id
  key_name  = aws_key_pair.auth.key_name

  root_block_device {
    volume_size = var.root_size
    volume_type = "gp2"
  }

  user_data = templatefile("./files/bootstrap_ec2.tmpl", { prefix = var.prefix, workspace = terraform.workspace, region = var.region })

  iam_instance_profile = aws_iam_instance_profile.madoc.name

  # docker-compose file
  provisioner "file" {
    source      = var.docker_compose_file
    destination = "/tmp/docker-compose.yml"
  }

  # systemd unit for madoc via docker-compose
  provisioner "file" {
    source      = "./files/madoc.service"
    destination = "/tmp/madoc.service"
  }

  # systemd units and scripts for backup
  provisioner "file" {
    source      = "./files/backup"
    destination = "/tmp"
  }

  # systemd units and scripts for handling shutdown
  provisioner "file" {
    source      = "./files/shutdown"
    destination = "/tmp"
  }

  # base .env file
  provisioner "file" {
    source      = "./files/.env"
    destination = "/tmp/.env"
  }

  connection {
    private_key = file(var.key_pair_private_key_path)
    user        = "ubuntu"
    host        = self.public_ip
  }

  tags = merge(
    local.common_tags,
    tomap({ "Name" = "${var.prefix}-${terraform.workspace}-madoc" })
  )
}

resource "aws_eip" "madoc" {
  instance = aws_instance.madoc.id
  vpc      = true

  tags = merge(
    local.common_tags,
    tomap({ "Name" = "${var.prefix}-${terraform.workspace}-madoc" })
  )
}

# EBS Instances
resource "aws_ebs_volume" "madoc_data" {
  availability_zone = var.availability_zone
  size              = var.ebs_size
  type              = "gp2"

  tags = merge(
    local.common_tags,
    tomap({ "Name" = "${var.prefix}-${terraform.workspace}-madoc-data" })
  )
}

resource "aws_ebs_volume" "madoc_backup" {
  availability_zone = var.availability_zone
  size              = var.ebs_backup_size
  type              = "standard"

  tags = merge(
    local.common_tags,
    tomap({ "Snapshot" = "true" }),
    tomap({ "Name" = "${var.prefix}-${terraform.workspace}-madoc-backup" })
  )
}

resource "aws_volume_attachment" "madoc_data_att" {
  device_name  = "/dev/sdf"
  volume_id    = aws_ebs_volume.madoc_data.id
  instance_id  = aws_instance.madoc.id
  force_detach = true
}

resource "aws_volume_attachment" "madoc_backup_att" {
  device_name  = "/dev/sdg"
  volume_id    = aws_ebs_volume.madoc_backup.id
  instance_id  = aws_instance.madoc.id
  force_detach = true
}
