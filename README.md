# TechCorp Terraform Assessment

This repository contains a Terraform configuration that provisions a VPC, public and private subnets across two AZs, NAT Gateways, an Application Load Balancer, EC2 instances (bastion, two web servers, database server), security groups, and outputs.

## Prerequisites

- Terraform v1.0+
- AWS account with permissions to create VPCs, EC2 instances, Elastic IPs, ELB, Security Groups, and IAM resources.
- AWS CLI configured or environment variables `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` (and optional `AWS_SESSION_TOKEN`) set.
- (Optional) An existing EC2 key pair in the region if you want to use SSH keys. Otherwise password auth is enabled in user-data for demo purposes (not recommended for production).

## File structure

terraform-assessment/├── main.tf├── variables.tf├── outputs.tf├── terraform.tfvars.example├── user_data/│ ├── web_server_setup.sh│ └── db_server_setup.sh└── README.md
## Quick deployment steps

1. Copy `terraform.tfvars.example` to `terraform.tfvars` and edit values (set `my_ip` to your public IP with /32). If you plan to use an SSH key, set `key_name`.

2. Initialize Terraform:

```bash
terraform init
1. Review plan:
terraform plan -out plan.out
1. Apply:
terraform apply "plan.out"
1. After apply completes, note the outputs: VPC ID, ALB DNS name, and bastion public IP.
How to access resources
* SSH to bastion:
ssh ec2-user@<bastion_public_ip> -i /path/to/key.pem
If you didn't provide a key pair, login with user techadmin and password ChangeMe123! (change immediately).
* From bastion, SSH to private web/db servers using the private IPs (or their private DNS names). Example:
ssh techadmin@10.0.3.10
* Web access: Use the ALB DNS name (output alb_dns_name). ALB will forward traffic to the web instances.
* Connect to Postgres from bastion or a web server:
psql -h <db_private_ip> -U postgres -W
# password: ChangeMe123!
Cleanup
Run the following to destroy all resources created by Terraform:
terraform destroy
Notes & Security Considerations
* The provided user-data enables password authentication and sets example passwords for demonstration only. In production, use SSH keys, manage secrets with AWS Secrets Manager or SSM Parameter Store, and follow hardening best practices.
	•	The Postgres installation in user-data is simplistic and not production-ready. For production, use RDS or a hardened DB node with backups and monitoring.
---

## Evidence checklist (what you will capture after deploy)

- `evidence/terraform-plan.png` — screenshot of `terraform plan` output
- `evidence/terraform-apply.png` — screenshot of successful `terraform apply`
- `evidence/aws-console-resources.png` — AWS Console view showing VPC, subnets, instances, ALB
- `evidence/alb-serving-pages.png` — browser screenshot showing ALB serving the web page from both instances (show instance IDs or other distinguishing text)
- `evidence/ssh-bastion.png` — terminal screenshot showing SSH to bastion
- `evidence/ssh-web-db.png` — terminal screenshot showing SSH from bastion to web and DB servers
- `evidence/connect-postgres.png` — terminal screenshot showing connecting to Postgres and running a simple `SELECT version();`
