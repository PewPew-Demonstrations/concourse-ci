output "ci_user_arn" { value = "${aws_iam_user.ci.arn}" }
output "github_app_id" { value = "${var.github_app_id}" }
output "github_app_secret" { value = "${var.github_app_secret}" }
output "kms_key_id" { value = "${aws_kms_key.ci.id}" }
output "maven_repo_bucket" { value = "${aws_s3_bucket.maven_repo.id}" }
