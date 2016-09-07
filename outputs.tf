output "ci_user_arn" { value = "${module.stack.ci_user_arn}" }
output "github_app_id" { value = "${var.github_app_id}" }
output "github_app_secret" { value = "${var.github_app_secret}" }
output "kms_key_id" { value = "${module.stack.kms_key_id}" }
output "maven_repo_bucket" { value = "${aws_s3_bucket.maven_repo.id}" }
