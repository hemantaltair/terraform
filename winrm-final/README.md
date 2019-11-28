# Usage
```
terraform plan -out=out/a365-prod-bastion-out.plan -var-file=../values/bastion/a365-prod-bastion.tfvars -var-file=../values/common.tfvars 
```
# Apply
```
terraform apply "out/a365-prod-bastion-out.plan"
```
