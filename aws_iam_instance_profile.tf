resource "aws_iam_instance_profile" "ec2-launch_terraform_managed_profile" {
  name = "${var.instance_prefix}-ec2-launch_terraform_managed_profile"
  role = aws_iam_role.ec2-launch_terraform_managed_role.name
}