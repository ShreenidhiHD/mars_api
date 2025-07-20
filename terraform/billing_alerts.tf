# Billing Alerts and Auto-Shutdown
resource "aws_cloudwatch_metric_alarm" "billing_alert" {
  alarm_name          = "mars-api-billing-alert"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "EstimatedCharges"
  namespace           = "AWS/Billing"
  period              = "86400"  
  statistic           = "Maximum"
  threshold           = var.billing_threshold
  alarm_description   = "This metric monitors AWS billing charges"
  alarm_actions       = [aws_sns_topic.billing_alerts.arn]

  dimensions = {
    Currency = "USD"
  }

  tags = {
    Name = "Mars API Billing Alert"
  }
}

# SNS Topic for Billing Alerts
resource "aws_sns_topic" "billing_alerts" {
  name = "mars-api-billing-alerts"

  tags = {
    Name = "Mars API Billing Alerts"
  }
}

resource "aws_sns_topic_subscription" "billing_email" {
  topic_arn = aws_sns_topic.billing_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# Lambda function to stop instances when billing threshold is reached
resource "aws_lambda_function" "stop_instances" {
  filename         = "stop_instances.zip"
  function_name    = "mars-api-stop-instances"
  role            = aws_iam_role.lambda_role.arn
  handler         = "lambda_function.lambda_handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime         = "python3.9"

  environment {
    variables = {
      INSTANCE_ID = aws_instance.mars_api.id
    }
  }

  tags = {
    Name = "Mars API Instance Stopper"
  }
}

# Lambda IAM Role
resource "aws_iam_role" "lambda_role" {
  name = "mars-api-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_policy" {
  name = "mars-api-lambda-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:StopInstances",
          "ec2:DescribeInstances",
          "rds:StopDBInstance",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

# Create Lambda deployment package
data "archive_file" "lambda_zip" {
  type        = "zip"
  output_path = "stop_instances.zip"
  source {
    content = <<EOF
import boto3
import os

def lambda_handler(event, context):
    ec2 = boto3.client('ec2')
    rds = boto3.client('rds')
    
    instance_id = os.environ['INSTANCE_ID']
    
    # Stop EC2 instance
    ec2.stop_instances(InstanceIds=[instance_id])
    
    # Stop RDS instance
    try:
        rds.stop_db_instance(DBInstanceIdentifier='mars-api-db')
    except Exception as e:
        print(f"RDS stop failed: {e}")
    
    return {
        'statusCode': 200,
        'body': 'Instances stopped due to billing alert'
    }
EOF
    filename = "lambda_function.py"
  }
}

# SNS Topic Subscription to trigger Lambda
resource "aws_sns_topic_subscription" "lambda_trigger" {
  topic_arn = aws_sns_topic.billing_alerts.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.stop_instances.arn
}

resource "aws_lambda_permission" "allow_sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.stop_instances.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.billing_alerts.arn
}
