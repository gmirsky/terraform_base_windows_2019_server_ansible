resource "aws_iam_role" "ec2-launch_terraform_managed_role" {
  name               = "${var.instance_prefix}-ec2-launch_terraform_managed_role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
  tags = merge(
    var.common_tags,
    var.project_tags,
  )
}