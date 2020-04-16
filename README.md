# AWS Instance Change Notifications on Slack   
   
This repo contains terraform code AND lambda code. You will need to edit a few files and create a lambda deployment package before you apply.   
_NOTE: you will need these resources in every region that you want notifications for._

## terraform.tfvars   
   
Copy `terraform.tfvars.default` to a new file named `terraform.tfvars` then edit the new file and enter your AWS Access ID, KEY, and Slack webhook.   
_This file is ignored in .gitignore_   
   
## backend.tf   
   
Edit `backend.tf` and enter in a bucket name where your state file will be stored. Also edit the filename for the state file, and if your bucket isn't in `us-east-1` update the region to reflect that.   
```
terraform {
  backend "s3" {
    bucket     = "BUCKET_NAME"
    key        = "STATE_FILE_NAME.tfstate"
    region     = "us-east-1"
    encrypt    = true
  }
}
```   
   
## variables.tf   
   
If you are not in region us-east-1, edit `variables.tf` and update the region accordingly.  
   
## instance\_state.tf   
   
Edit `instance_state.tf` and update the name of the bucket you will create to store the lambda deployment package. Can be any unique bucket name.   
   
## Deploy all infrastructure   
   
`terraform init`   
`terraform apply`   
   

