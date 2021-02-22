data "aws_region" "current" {}

data "aws_iam_role" "cloudwatch-events-rule-invocation-role" {
  name = "xilution-cloudwatch-events-rule-invocation-role"
}

data "aws_lambda_function" "metrics-reporter-lambda" {
  function_name = "xilution-client-metrics-reporter-lambda"
}

# Network (VPN, Subnets, Etc.)

resource "aws_vpc" "xilution_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name                     = "xilution-gazelle-${substr(var.gazelle_pipeline_id, 0, 8)}-vpc"
    xilution_organization_id = var.organization_id
    originator               = "xilution.com"
  }
}

resource "aws_subnet" "xilution_public_subnet_1" {
  cidr_block              = "10.0.0.0/24"
  vpc_id                  = aws_vpc.xilution_vpc.id
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name                     = "xilution-gazelle-${substr(var.gazelle_pipeline_id, 0, 8)}-public-subnet-1"
    xilution_organization_id = var.organization_id
    originator               = "xilution.com"
  }
}

resource "aws_subnet" "xilution_public_subnet_2" {
  cidr_block              = "10.0.2.0/24"
  vpc_id                  = aws_vpc.xilution_vpc.id
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
  tags = {
    Name                     = "xilution-gazelle-${substr(var.gazelle_pipeline_id, 0, 8)}-public-subnet-2"
    xilution_organization_id = var.organization_id
    originator               = "xilution.com"
  }
}

resource "aws_internet_gateway" "xilution_internet_gateway" {
  vpc_id = aws_vpc.xilution_vpc.id
  tags = {
    xilution_organization_id = var.organization_id
    originator               = "xilution.com"
  }
}

resource "aws_eip" "xilution_elastic_ip" {
  tags = {
    xilution_organization_id = var.organization_id
    originator               = "xilution.com"
  }
}

resource "aws_route_table" "xilution_public_route_table" {
  vpc_id = aws_vpc.xilution_vpc.id
  tags = {
    xilution_organization_id = var.organization_id
    originator               = "xilution.com"
  }
}

resource "aws_route" "xilution_public_route" {
  route_table_id         = aws_route_table.xilution_public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.xilution_internet_gateway.id
}

resource "aws_route_table_association" "xilution_public_route_table_association_1" {
  route_table_id = aws_route_table.xilution_public_route_table.id
  subnet_id      = aws_subnet.xilution_public_subnet_1.id
}

resource "aws_route_table_association" "xilution_public_route_table_association_2" {
  route_table_id = aws_route_table.xilution_public_route_table.id
  subnet_id      = aws_subnet.xilution_public_subnet_2.id
}

# Metrics

resource "aws_lambda_permission" "allow-gazelle-cloudwatch-every-ten-minute-event-rule" {
  action        = "lambda:InvokeFunction"
  function_name = data.aws_lambda_function.metrics-reporter-lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.gazelle-cloudwatch-every-ten-minute-event-rule.arn
}

resource "aws_cloudwatch_event_rule" "gazelle-cloudwatch-every-ten-minute-event-rule" {
  name                = "xilution-gazelle-${substr(var.gazelle_pipeline_id, 0, 8)}-cloudwatch-event-rule"
  schedule_expression = "rate(10 minutes)"
  role_arn            = data.aws_iam_role.cloudwatch-events-rule-invocation-role.arn
  tags = {
    xilution_organization_id = var.organization_id
    originator               = "xilution.com"
  }
}

resource "aws_cloudwatch_event_target" "gazelle-cloudwatch-event-target" {
  rule  = aws_cloudwatch_event_rule.gazelle-cloudwatch-every-ten-minute-event-rule.name
  arn   = data.aws_lambda_function.metrics-reporter-lambda.arn
  input = <<-DOC
  {
    "Environment": "prod",
    "OrganizationId": "${var.organization_id}",
    "ProductId": "${var.product_id}",
    "Duration": 600000,
    "MetricDataQueries": [
      {
        "Id": "client_metrics_reporter_lambda_duration",
        "MetricStat": {
          "Metric": {
            "Namespace": "AWS/Lambda",
            "MetricName": "Duration",
            "Dimensions": [
              {
                "Name": "FunctionName",
                "Value": "xilution-client-metrics-reporter-lambda"
              }
            ]
          },
          "Period": 60,
          "Stat": "Average",
          "Unit": "Milliseconds"
        }
      }
    ],
    "MetricNameMaps": [
      {
        "Id": "client_metrics_reporter_lambda_duration",
        "MetricName": "client-metrics-reporter-lambda-duration"
      }
    ]
  }
  DOC
}

# Dashboards

resource "aws_cloudwatch_dashboard" "gazelle-cloudwatch-dashboard" {
  dashboard_name = "xilution-gazelle-${substr(var.gazelle_pipeline_id, 0, 8)}-dashboard"

  dashboard_body = <<-EOF
  {
    "widgets": [
      {
        "type": "metric",
        "x": 0,
        "y": 0,
        "width": 12,
        "height": 6,
        "properties": {
          "metrics": [
            [
              "AWS/EC2",
              "CPUUtilization",
              "InstanceId",
              "i-012345"
            ]
          ],
          "period": 300,
          "stat": "Average",
          "region": "us-east-1",
          "title": "EC2 Instance CPU"
        }
      },
      {
        "type": "text",
        "x": 0,
        "y": 7,
        "width": 3,
        "height": 3,
        "properties": {
          "markdown": "Hello world"
        }
      }
    ]
  }
  EOF
}
