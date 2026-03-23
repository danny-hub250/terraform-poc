terraform {
  backend "s3" {
    bucket         = "platform-tfstate-koo"
    key            = "dev/terraform.tfstate"
    region         = "ap-northeast-2"
    dynamodb_table = "platform-tfstate-lock"
    encrypt        = true
  }
}