locals {
  rule_name = "instance-state-change"
}

resource "aws_cloudwatch_event_rule" "instance-state-change" {
    description   = "instance state was changed"
    event_pattern = jsonencode(
        {
            detail-type = [
                "EC2 Instance State-change Notification",
            ]
            source      = [
                "aws.ec2",
            ]
        }
    )
    name          = local.rule_name
    depends_on = [aws_sns_topic_subscription.instance-state-sns-subscription]
}

resource "aws_cloudwatch_event_target" "instance-state-sns-target" {
    arn       = aws_sns_topic.instance-state-sns-topic.arn
    rule      = local.rule_name
    input_transformer {
        input_paths    = {
            "account"     = "$.account"
            "instance-id" = "$.detail.instance-id"
            "region"      = "$.region"
            "state"       = "$.detail.state"
            "time"        = "$.time"
        }
        input_template = "\"instance_id=<instance-id>, time=<time>, region=<region>, state=<state>\""
        #input_template = "\"At <time>, the status of your EC2 instance <instance-id> on account <account> in the AWS Region <region> has changed to <state>. \""
    }
    depends_on = [aws_cloudwatch_event_rule.instance-state-change]
}
