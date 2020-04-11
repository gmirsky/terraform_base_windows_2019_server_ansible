resource "aws_iam_role_policy" "ec2-launch_terraform_managed_policy" {
  name   = "${var.instance_prefix}-ec2-launch_terraform_managed_policy"
  role   = aws_iam_role.ec2-launch_terraform_managed_role.id
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetBucketLocation",
                "s3:ListAllMyBuckets"
            ],
            "Resource": "arn:aws:s3:::*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::ec2-launch"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:Get*",
                "s3:List*"
            ],
            "Resource": [
                "arn:aws:s3:::ec2-launch/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:CreateTags",
                "ec2:DescribeTags",
                "ec2:Describe*"
            ],
            "Resource": [
                "*"
            ]
        }
    ]
}
EOF
}
