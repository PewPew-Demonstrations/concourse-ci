provider "aws" {
  region = "${var.region}"
}

resource "aws_iam_role_policy" "provisioning-read" {
    name = "Provisioning-Read-${module.stack.environment_id}"
    role = "${module.stack.ecs_worker_role_name}"
    policy = "${file("./policies/provisioning-read.policy.json")}"
}

resource "aws_iam_role_policy" "provisioning-create" {
    name = "Provisioning-Create-${module.stack.environment_id}"
    role = "${module.stack.ecs_worker_role_name}"
    policy = "${file("./policies/provisioning-create.policy.json")}"
}

resource "aws_iam_role_policy" "provisioning-delete" {
    name = "Provisioning-Delete-${module.stack.environment_id}"
    role = "${module.stack.ecs_worker_role_name}"
    policy = "${file("./policies/provisioning-delete.policy.json")}"
}

resource "aws_s3_bucket" "maven_repo_logs" {
  bucket = "${var.team}-${var.role}-${var.name}-maven-repo-logs"
  acl = "log-delivery-write"

	tags {
		Name = "${var.name}-maven-repo-logs"
		Project = "${var.name}"
		Team = "${var.team}"
		Owner = "${var.owner}"
		Environment = "${var.environment}"
		EnvironmentId = "${module.stack.environment_id}"
	}
}

resource "aws_s3_bucket" "maven_repo" {
  bucket = "${var.team}-${var.role}-${var.name}-maven-repo"
  acl = "private"
	logging {
		target_bucket = "${aws_s3_bucket.maven_repo_logs.id}"
		target_prefix = "log/"
	}
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:PutObjectAcl",
        "s3:GetObject",
        "s3:ListBucket"
      ],
      "Principal": {"AWS": [
        "${module.stack.ecs_worker_role_arn}"
      ]},
      "Resource": [
        "arn:aws:s3:::${var.team}-${var.role}-${var.name}-maven-repo",
        "arn:aws:s3:::${var.team}-${var.role}-${var.name}-maven-repo/*"
      ]
    }
  ]
}
EOF
  tags {
    Name = "${var.name}"
    Project = "${var.name}"
    Team = "${var.team}"
    Owner = "${var.owner}"
    Environment = "${var.environment}"
    EnvironmentId = "${module.stack.environment_id}"
  }
}
