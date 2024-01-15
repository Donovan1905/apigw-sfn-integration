data "template_file" "express_state_machine_template" {
  template = file("${path.module}/express_state_machine_template.tftpl")
  vars = {
    instance_id = aws_instance.example.id
  }
}

resource "aws_sfn_state_machine" "express_sfn_state_machine" {
  name     = "${var.project_name}-express"
  role_arn = aws_iam_role.iam_for_sfn.arn
  type     = "EXPRESS"

  definition = data.template_file.express_state_machine_template.rendered
}

data "template_file" "standard_state_machine_template" {
  template = file("${path.module}/standard_state_machine_template.tftpl")
  vars = {
    instance_id = aws_instance.example.id
  }
}

resource "aws_sfn_state_machine" "standard_sfn_state_machine" {
  name     = "${var.project_name}-standard"
  role_arn = aws_iam_role.iam_for_sfn.arn
  type     = "STANDARD"

  definition = data.template_file.standard_state_machine_template.rendered
}
