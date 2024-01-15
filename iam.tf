data "aws_iam_policy_document" "assume_role_policy_sfn" {
  statement {
    effect = "Allow"
    principals {
      identifiers = ["states.amazonaws.com"]
      type        = "Service"
    }
    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "role_policy_sfn" {
  statement {
    effect  = "Allow"
    actions = [
      "ec2:*"
    ]
    resources = [
      "*",
    ]
  }

  statement {
    sid    = "LoggingPolicy"
    effect = "Allow"
    actions = [
      "logs:*"
    ]
    resources = [
      "*"
    ]
  }
}

resource "aws_iam_role" "iam_for_sfn" {
  name = "stepFunctionExecutionIAM"

  inline_policy {
    name   = "PolicyForSfn"
    policy = data.aws_iam_policy_document.role_policy_sfn.json
  }

  assume_role_policy = data.aws_iam_policy_document.assume_role_policy_sfn.json
}


data "aws_iam_policy_document" "assume_role_policy_apigw" {
  statement {
    sid    = ""
    effect = "Allow"
    principals {
      identifiers = ["apigateway.amazonaws.com"]
      type        = "Service"
    }
    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "policy_start_sfn" {
  statement {
    sid    = "ApiGwPolicy"
    effect = "Allow"
    actions = [
      "states:StartSyncExecution",
      "states:StartExecution"
    ]
    resources = [
      "*"
    ]
  }

}

resource "aws_iam_role" "iam_for_apigw_start_sfn" {
  name               = "${var.project_name}-apigw-exec-sfn"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy_apigw.json
}

resource "aws_iam_role_policy" "policy_start_sfn" {
  policy = data.aws_iam_policy_document.policy_start_sfn.json
  role   = aws_iam_role.iam_for_apigw_start_sfn.id
}