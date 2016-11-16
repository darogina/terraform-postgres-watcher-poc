project = "postgres" 
environment      = "demo"
region            = "us-east-1"

azs               = ["us-east-1a","us-east-1b","us-east-1d","us-east-1e"] # AZs are region specific

/* VPC */
vpc_cidr = "10.140.0.0/16"
private_subnets   = ["10.140.1.0/24","10.140.2.0/24","10.140.3.0/24","10.140.4.0/24"] # Creating one private subnet per AZ
public_subnets    = ["10.140.101.0/24","10.140.102.0/24","10.140.103.0/24","10.140.104.0/24"] # Creating one public subnet per AZ
vpc_enable_dns_hostnames = "true"
vpc_enable_dns_support = "true"

/* Instances */
ssh_public_key_path = "../../../../setup/postgres-demo.pub"

# Git Watcher
watcher_ami_id = "ami-b63769a1"
watcher_instance_type = "t2.micro"
watcher_tenancy = "default"
watcher_ebs_optimized = "false"
watcher_disable_api_termination = "true"
watcher_enable_detailed_monitoring = "false"
watcher_associate_public_ip = "false"
watcher_desired_instance_count = "1"
watcher_min_instance_count = "1"
watcher_max_instance_count = "1"
watcher_root_block_device_volume_type = "gp2"
watcher_root_block_device_volume_size = "10"
watcher_root_block_device_delete_on_termination = "true"
