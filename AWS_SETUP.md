# AWS Credentials Setup (Using ~/.aws/credentials file)

## 1. Create AWS Credentials File
Create/edit the file: `~/.aws/credentials`

```ini
[default]
aws_access_key_id = YOUR_ACCESS_KEY_HERE
aws_secret_access_key = YOUR_SECRET_KEY_HERE

[mars-api]
aws_access_key_id = YOUR_ACCESS_KEY_HERE
aws_secret_access_key = YOUR_SECRET_KEY_HERE
```

## 2. Create AWS Config File
Create/edit the file: `~/.aws/config`

```ini
[default]
region = us-east-1
output = json

[profile mars-api]
region = us-east-1
output = json
```

## 3. Update terraform.tfvars
```hcl
aws_profile = "default"  # or "mars-api"
```

## 4. Run Terraform
```bash
cd terraform
terraform init
terraform plan
terraform apply
```

## Where to get AWS Access Keys:
1. Go to AWS Console → IAM
2. Users → Your User → Security Credentials
3. Create Access Key → Command Line Interface (CLI)
4. Copy Access Key ID and Secret Access Key

## File Locations:
- **Linux/Mac**: `~/.aws/credentials` and `~/.aws/config`
- **Windows**: `C:\Users\USERNAME\.aws\credentials` and `C:\Users\USERNAME\.aws\config`
