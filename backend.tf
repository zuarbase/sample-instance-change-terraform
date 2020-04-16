terraform {
  backend "s3" {
    bucket     = "BUCKET_NAME"
    key        = "STATE_FILE_NAME.tfstate"
    region     = "us-east-1"
    encrypt    = true
  }
}
