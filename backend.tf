terraform {
  backend "s3" {
    bucket = "backend-tfstate-iti"
    key    = "teraform.tfstate"
    region = "us-east-1"
  }
}
