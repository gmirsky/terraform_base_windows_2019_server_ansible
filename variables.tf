
variable "instance_prefix" {
  type        = string
  description = "Instance Name Prefix in the format of XXXXX-"
  default     = "testbed-"
}

variable "bucket_name" {
  type        = string
  description = "S3 bucket name to substitute in the template file"
  default     = "my_s3_bucket_with_data_in_it_somewhere"
}

variable "domain" {
  type        = string
  description = "Domain to register/join the server to"
  default     = "mydomain"
}

variable "domain_administrator_id" {
  type        = string
  description = "Domain Administrator ID to join server to the domain with"
  default     = "domain_admin_id"
}

variable "domain_administrator_password" {
  type        = string
  description = "Domain Administrator password to join server to the domain with"
  default     = ""
}

variable "domain_controller_name" {
  type        = string
  description = "Domain Controller DNS Name that is resolvable"
  default     = "MY-DOMAIN-CTL.mydomain.com" 
}

variable "key_name" {
  type        = string
  description = "Name of the SSH keypair to use in AWS."
  default     = "Windows_Machine_Key_Pair"
}

variable "aws_region" {
  type        = string
  description = "AWS region to launch servers."
  default     = "us-east-1"
}

variable "aws_availability_zone" {
  type        = string
  description = "AWS availibility zone to launch in."
  default     = "us-east-1a"
}

variable "subnet_id" {
  type        = string
  description = "Subnet ID to launch the EC2 Instance"
  default     = "subnet-0000000"
}

variable "vpc_security_group_ids" {
  type        = list(string)
  description = "Security Group IDs to attach to the EC2 instance. One security group must allow traffic from TCP ports 5985/5986"
  default = [
    "sg-00000000",
    "sg-11111111", 
    "sg-22222222"  
  ]
}

variable "instance_type" {
  type        = string
  description = "Instance Type"
  default     = "t2.medium"
}

variable "common_tags" {
  type        = map
  description = "Common tags to be applied to all resources"
  default = {
    Owner             = "owners-name"
    Environment       = "Development"
    cost-center       = "00-00000"
    terraform-managed = true
  }
}

variable "project_tags" {
  type        = map
  description = "Project specific tags to be applied to all resources."
  default = {
    Project  = "project-001"
    Release  = "0.01"
    Revision = "0.01"
  }
}
