resource "aws_instance" "server-1" {
  instance_type        = var.instance_type
  iam_instance_profile = aws_iam_instance_profile.ec2-launch_terraform_managed_profile.name
  ami                  = module.aws-ami-search.ami_id
  tags = merge(
    var.common_tags,
    var.project_tags,
    tomap({ "Name" = "${var.instance_prefix}1" })
  )
  root_block_device {
    volume_type           = "gp2"
    volume_size           = 40
    delete_on_termination = true
    encrypted             = true
  }
  ebs_block_device {
    device_name           = "/dev/xvdb"
    volume_type           = "gp2"
    volume_size           = 100
    delete_on_termination = true
    encrypted             = true
  }
  availability_zone           = var.aws_availability_zone
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = var.vpc_security_group_ids
  associate_public_ip_address = "false"
  key_name                    = var.key_name
  #user_data = "${file("../../tmp/aws/userdata.sh")}"
  user_data                   = <<EOF
<powershell>
Start-Job -name "copys3" -ScriptBlock { Copy-S3Object -Region us-east-1 -BucketName ec2-launch  -Key terraform/bootstrap/scripts/setup_new_ec2_at_launch.ps1 -LocalFolder c:\Windows\temp -force }
Wait-Job -name "copys3"

C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -ExecutionPolicy Bypass -File 'C:\Windows\Temp\terraform\bootstrap\scripts\setup_new_ec2_at_launch.ps1'
</powershell>
EOF
}
