locals {
  sns_name = "instance-state-change"
}

variable "account_id" {}

resource "aws_sns_topic" "instance-state-sns-topic" {
  name = local.sns_name
  display_name = local.sns_name
}

resource "aws_sns_topic_subscription" "instance-state-sns-subscription" {
  endpoint = aws_lambda_function.instance_state-lambda-function.arn
  protocol             = "lambda"
  raw_message_delivery = false
  topic_arn = aws_sns_topic.instance-state-sns-topic.arn
  confirmation_timeout_in_minutes = 1
  endpoint_auto_confirms = false
  depends_on = [aws_sns_topic.instance-state-sns-topic, aws_lambda_function.instance_state-lambda-function]
}

resource "aws_sns_topic_policy" "instance-state-lambda-policy" {
    arn = aws_sns_topic.instance-state-sns-topic.arn
    policy = "{\"Version\":\"2012-10-17\",\"Id\":\"__default_policy_ID\",\"Statement\":[{\"Sid\":\"__default_statement_ID\",\"Effect\":\"Allow\",\"Principal\":{\"AWS\":\"*\"},\"Action\":[\"SNS:GetTopicAttributes\",\"SNS:SetTopicAttributes\",\"SNS:AddPermission\",\"SNS:RemovePermission\",\"SNS:DeleteTopic\",\"SNS:Subscribe\",\"SNS:ListSubscriptionsByTopic\",\"SNS:Publish\",\"SNS:Receive\"],\"Resource\":\"${aws_sns_topic.instance-state-sns-topic.arn}\",\"Condition\":{\"StringEquals\":{\"AWS:SourceOwner\":\"${var.account_id}\"}}},{\"Sid\":\"AWSEvents_instance-state-change_Id734782958494\",\"Effect\":\"Allow\",\"Principal\":{\"Service\":\"events.amazonaws.com\"},\"Action\":\"sns:Publish\",\"Resource\":\"${aws_sns_topic.instance-state-sns-topic.arn}\"}]}"
    depends_on = [aws_sns_topic_subscription.instance-state-sns-subscription]
}

resource "aws_lambda_permission" "lambda_sns_trigger" {
    action        = "lambda:invokeFunction"
    function_name = aws_lambda_function.instance_state-lambda-function.arn
    principal     = "sns.amazonaws.com"
    source_arn    = aws_sns_topic.instance-state-sns-topic.arn
    statement_id  = "youhavemypermission-${var.region}"
}
