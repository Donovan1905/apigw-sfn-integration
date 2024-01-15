resource "aws_api_gateway_rest_api" "apigw" {
  name = "${var.project_name}-apigw"
}

resource "aws_api_gateway_resource" "express_ec2" {
  parent_id   = aws_api_gateway_rest_api.apigw.root_resource_id
  path_part   = "express-instance"
  rest_api_id = aws_api_gateway_rest_api.apigw.id
}

resource "aws_api_gateway_method" "express_post" {
  authorization = "NONE"
  http_method   = "POST"
  resource_id   = aws_api_gateway_resource.express_ec2.id
  rest_api_id   = aws_api_gateway_rest_api.apigw.id
}

resource "aws_api_gateway_resource" "standard_ec2" {
  parent_id   = aws_api_gateway_rest_api.apigw.root_resource_id
  path_part   = "standard-instance"
  rest_api_id = aws_api_gateway_rest_api.apigw.id
}

resource "aws_api_gateway_method" "standard_post" {
  authorization = "NONE"
  http_method   = "POST"
  resource_id   = aws_api_gateway_resource.standard_ec2.id
  rest_api_id   = aws_api_gateway_rest_api.apigw.id
}

resource "aws_api_gateway_deployment" "example" {
  rest_api_id = aws_api_gateway_rest_api.apigw.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.express_ec2.id,
      aws_api_gateway_method.express_post.id,
      aws_api_gateway_integration.express_integration.id,
      aws_api_gateway_resource.standard_ec2.id,
      aws_api_gateway_method.standard_post.id,
      aws_api_gateway_integration.standard_integration.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_integration" "express_integration" {
  rest_api_id             = aws_api_gateway_rest_api.apigw.id
  resource_id             = aws_api_gateway_resource.express_ec2.id
  http_method             = aws_api_gateway_method.express_post.http_method
  integration_http_method = "POST"
  type                    = "AWS"
  uri = (
    "arn:aws:apigateway:${var.region}:states:action/StartSyncExecution"
  )
  credentials = aws_iam_role.iam_for_apigw_start_sfn.arn

  request_templates = {
    "application/json" = <<EOF
#set($input = $input.json('$'))
{
   "input": "$util.escapeJavaScript($input).replaceAll("\\'", "'")",
 "stateMachineArn": "${aws_sfn_state_machine.express_sfn_state_machine.arn}"
}
EOF
  }
}

resource "aws_api_gateway_integration" "standard_integration" {
  rest_api_id             = aws_api_gateway_rest_api.apigw.id
  resource_id             = aws_api_gateway_resource.standard_ec2.id
  http_method             = aws_api_gateway_method.standard_post.http_method
  integration_http_method = "POST"
  type                    = "AWS"
  uri = (
    "arn:aws:apigateway:${var.region}:states:action/StartExecution"
  )
  credentials = aws_iam_role.iam_for_apigw_start_sfn.arn

  request_templates = {
    "application/json" = <<EOF
#set($input = $input.json('$'))
{
   "input": "$util.escapeJavaScript($input).replaceAll("\\'", "'")",
 "stateMachineArn": "${aws_sfn_state_machine.standard_sfn_state_machine.arn}"
}
EOF
  }
}

resource "aws_api_gateway_method_response" "express_response_200" {
  rest_api_id = aws_api_gateway_rest_api.apigw.id
  resource_id = aws_api_gateway_resource.express_ec2.id
  http_method = aws_api_gateway_method.express_post.http_method
  status_code = "200"
}

resource "aws_api_gateway_integration_response" "express_response_200" {
  rest_api_id = aws_api_gateway_rest_api.apigw.id
  resource_id = aws_api_gateway_resource.express_ec2.id
  http_method = aws_api_gateway_method.express_post.http_method
  status_code = aws_api_gateway_method_response.express_response_200.status_code

  response_templates = {
    "application/json" = <<EOF
#set ($parsedPayload = $util.parseJson($input.json('$.output')))
$parsedPayload
EOF
  }
}

resource "aws_api_gateway_method_response" "standard_response_200" {
  rest_api_id = aws_api_gateway_rest_api.apigw.id
  resource_id = aws_api_gateway_resource.standard_ec2.id
  http_method = aws_api_gateway_method.standard_post.http_method
  status_code = "200"
}

resource "aws_api_gateway_integration_response" "standard_response_200" {
  rest_api_id = aws_api_gateway_rest_api.apigw.id
  resource_id = aws_api_gateway_resource.standard_ec2.id
  http_method = aws_api_gateway_method.standard_post.http_method
  status_code = aws_api_gateway_method_response.standard_response_200.status_code

  response_templates = {
    "application/json" = <<EOF
#set ($parsedPayload = $util.parseJson($input.json('$')))
$parsedPayload
EOF
  }
}
