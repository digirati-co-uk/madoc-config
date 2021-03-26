locals {
    zone_id = data.aws_route53_zone.EXAMPLE_NAME_madoc_io.zone_id
}

provider "aws" {
  alias = "west"
  version = "~> 2.46"
  region  = "eu-west-1"
}

# domain verification
resource "aws_ses_domain_identity" "EXAMPLE_NAME_madoc_io" {
  provider = aws.west
  domain = var.madoc_domain
}

resource "aws_route53_record" "ses_verification" {
  zone_id = local.zone_id
  name    = "_amazonses.${aws_ses_domain_identity.EXAMPLE_NAME_madoc_io.id}"
  type    = "TXT"
  ttl     = "600"
  records = [aws_ses_domain_identity.EXAMPLE_NAME_madoc_io.verification_token]
}

resource "aws_ses_domain_identity_verification" "EXAMPLE_NAME_madoc_io_verification" {
  domain = aws_ses_domain_identity.EXAMPLE_NAME_madoc_io.id
  provider = aws.west

  depends_on = [aws_route53_record.ses_verification]
}

# DKIM verification
resource "aws_ses_domain_dkim" "main" {
  domain = aws_ses_domain_identity.EXAMPLE_NAME_madoc_io.domain
  provider = aws.west
}

resource "aws_route53_record" "dkim" {
  count   = 3
  zone_id = local.zone_id
  name = format(
    "%s._domainkey.%s",
    element(aws_ses_domain_dkim.main.dkim_tokens, count.index),
    var.madoc_domain,
  )
  type    = "CNAME"
  ttl     = "600"
  records = ["${element(aws_ses_domain_dkim.main.dkim_tokens, count.index)}.dkim.amazonses.com"]
}

# From
resource "aws_ses_domain_mail_from" "noreply" {
  domain           = aws_ses_domain_identity.EXAMPLE_NAME_madoc_io.domain
  mail_from_domain = "mail.${var.madoc_domain}"
  provider = aws.west
}

# SPF validaton record
resource "aws_route53_record" "spf_mail_from" {
  zone_id = local.zone_id
  name    = aws_ses_domain_mail_from.noreply.mail_from_domain
  type    = "TXT"
  ttl     = "600"
  records = ["v=spf1 include:amazonses.com -all"]
}

resource "aws_route53_record" "spf_domain" {
  zone_id = local.zone_id
  name    = var.madoc_domain
  type    = "TXT"
  ttl     = "600"
  records = ["v=spf1 include:amazonses.com -all"]
}

# MX Record
resource "aws_route53_record" "mx_send_mail_from" {
  zone_id = local.zone_id
  name    = aws_ses_domain_mail_from.noreply.mail_from_domain
  type    = "MX"
  ttl     = "600"
  records = ["10 feedback-smtp.eu-west-1.amazonses.com"]
}

# IAM
resource "aws_iam_user" "omeka" {
  name = "${var.prefix}-omeka"
}

resource "aws_iam_access_key" "omeka" {
  user = aws_iam_user.omeka.name
}

resource "aws_iam_group" "omeka" {
  name = "${var.prefix}-omeka"
}

resource "aws_iam_group_membership" "omeka" {
  name = "${var.prefix}-omeka"

  users = [
    aws_iam_user.omeka.name,
  ]

  group = aws_iam_group.omeka.name
}

resource "aws_iam_group_policy" "omeka" {
  name  = "${var.prefix}-omeka"
  group = aws_iam_group.omeka.name

  policy = <<EOF
{
    "Statement": [
        {
            "Action": [
                "ses:*"
            ],
            "Effect": "Allow",
            "Resource": [
                "arn:aws:ses:eu-west-1:${local.account_id}:identity/${var.madoc_domain}"
            ]
        }
    ]
}
EOF
}

# Create SecureStrings, picked by user_data for docker-compose env_vars
resource "aws_ssm_parameter" "smtp_password" {
  name  = "/madoc/${var.prefix}/${terraform.workspace}/OMEKA_SMTP_UNAME"
  type  = "SecureString"
  value = aws_iam_access_key.omeka.id

  tags = {
      "terraform" = true,
      "system" = "madoc"
  }
}

resource "aws_ssm_parameter" "smtp_username" {
  name  = "/madoc/${var.prefix}/${terraform.workspace}/OMEKA_SMTP_PWORD"
  type  = "SecureString"
  value = aws_iam_access_key.omeka.ses_smtp_password

  tags = {
      "terraform" = true,
      "system" = "madoc"
  }
}
