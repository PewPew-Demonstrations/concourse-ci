output "ci_user_arn" { value = "${aws_iam_user.ci.arn}" }
output "github_app_id" { value = "${var.github_app_id}" }
output "github_app_secret" { value = "${var.github_app_secret}" }
