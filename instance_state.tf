locals {
  instance_state_lambda_runtime = "python3.6"
  instance_state_zip_name = "instance_state.zip"
  instance_state_project_zip = "${path.cwd}/instance_state.zip"
  instance_state_lambda_bucket = "BUCKET_NAME"
  instance_state_lambda_name = "instance_state-${var.region}-${terraform.workspace}"
  instance_state_lambda_handler = "instance_state.handler"
  instance_state_lambda_log_name = "instance_state-lambda-logging-${var.region}-${terraform.workspace}"
  instance_state_lambda_role_name = "instance_state-lambda-function-lambda-role-${var.region}-${terraform.workspace}"
}

resource "aws_s3_bucket" "instance_state_bucket" {
  bucket = local.instance_state_lambda_bucket
  acl    = "private"

  tags = {
    Name        = "bucket for instate state lambda"
  }
}

resource "aws_s3_bucket_object" "instance_state-lambda_object" {
  bucket = local.instance_state_lambda_bucket
  key    = local.instance_state_zip_name
  source = local.instance_state_zip_name
  etag = filemd5(local.instance_state_project_zip)
  depends_on    = [aws_s3_bucket.instance_state_bucket]
}

# LAMBDA FUNCTION

resource "aws_lambda_function" "instance_state-lambda-function" {
  function_name = local.instance_state_lambda_name
  s3_bucket = local.instance_state_lambda_bucket
  s3_key    = local.instance_state_zip_name
  handler = local.instance_state_lambda_handler
  runtime = local.instance_state_lambda_runtime
  memory_size = 256
  timeout     = 30
  role = aws_iam_role.instance_state-lambda_exec.arn
  source_code_hash = filebase64sha256(local.instance_state_project_zip)
  environment {
    variables = { 
      ACCESS_ID = var.access_key
      ACCESS_KEY = var.secret_key
      REGION = var.region
      SLACK_HOOK = var.slack_hook
    }   
  }
  depends_on    = [aws_iam_role_policy_attachment.instance_state-lambda_logs, aws_cloudwatch_log_group.instance_state-lambda-function-log-group, aws_s3_bucket_object.instance_state-lambda_object]
}

# IAM role which dictates what other AWS services the Lambda function
# may access.
resource "aws_iam_role" "instance_state-lambda_exec" {
  name = local.instance_state_lambda_role_name
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {   
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },  
      "Effect": "Allow",
      "Sid": ""
    }   
  ]
}
EOF
}

# CLOUDWATCH LOG GROUP

resource "aws_cloudwatch_log_group" "instance_state-lambda-function-log-group" {
  name              = "/aws/lambda/${local.instance_state_lambda_name}"
  retention_in_days = 14
}

resource "aws_iam_policy" "instance_state-lambda_logging" {
  name = local.instance_state_lambda_log_name
  path = "/"
  description = "IAM policy for logging from a lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "instance_state-lambda_logs" {
  role = aws_iam_role.instance_state-lambda_exec.name
  policy_arn = aws_iam_policy.instance_state-lambda_logging.arn
}

