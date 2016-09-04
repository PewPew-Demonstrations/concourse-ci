provider "aws" {
  region = "${var.region}"
}

resource "aws_iam_user" "ci" {
  name = "${var.name}-ci"
}

resource "aws_kms_key" "ci" {
    description = "KMS Key used by ${var.name}"
    deletion_window_in_days = 7
    enable_key_rotation = true
}

resource "aws_kms_alias" "ci" {
    name = "alias/${var.name}-concourseci-kms"
    target_key_id = "${aws_kms_key.ci.key_id}"
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

resource "aws_iam_policy" "kms_decrypt" {
  name = "KMS-Decrypt-${module.stack.environment_id}"
  path = "${lower(format("/%s/%s/", var.team, var.name))}"
  description = "Decrypt access to KMS Key "
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "kms:Decrypt",
        "kms:DescribeKey"
      ],
      "Resource": [
        "${aws_kms_key.ci.arn}"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_policy" "kms_encrypt" {
  name = "KMS-Encrypt-${module.stack.environment_id}"
  path = "${lower(format("/%s/%s/", var.team, var.name))}"
  description = "Encrypt access to KMS Key "
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "kms:Encrypt",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:DescribeKey"
      ],
      "Resource": [
        "${aws_kms_key.ci.arn}"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_policy_attachment" "kms_decrypt" {
  name = "${var.name}-ci-kms-decrypt"
  roles = ["${compact(concat(list(module.stack.ecs_worker_role_name), var.kms_access_roles))}"]
  users = ["${aws_iam_user.ci.name}"]
  policy_arn = "${aws_iam_policy.kms_decrypt.arn}"
}

resource "aws_iam_policy_attachment" "kms_encrypt" {
  name = "${var.name}-ci-kms-encrypt"
  roles = ["${compact(concat(list(module.stack.ecs_worker_role_name), var.kms_access_roles))}"]
  users = ["${aws_iam_user.ci.name}"]
  policy_arn = "${aws_iam_policy.kms_encrypt.arn}"
}

resource "aws_s3_bucket" "assets_logs" {
  bucket = "${var.name}-assets-logs"
  acl = "log-delivery-write"

	tags {
		Name = "${var.name}-assets-logs"
		Project = "${var.name}"
		Team = "${var.team}"
		Owner = "${var.owner}"
		Environment = "${var.environment}"
		EnvironmentId = "${module.stack.environment_id}"
	}
}

resource "aws_s3_bucket" "assets" {
  bucket = "${var.name}-assets"
  versioning {
    enabled = true
  }
  acl = "private"
	logging {
		target_bucket = "${aws_s3_bucket.assets_logs.id}"
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
        "s3:ListBucket",
        "s3:GetBucketVersioning",
        "s3:GetObjectVersion",
        "s3:ListBucketVersions",
        "s3:PutObjectVersionAcl"
      ],
      "Principal": {"AWS": [
        "${module.stack.ecs_worker_role_arn}",
        "${aws_iam_user.ci.arn}"
      ]},
      "Resource": [
        "arn:aws:s3:::${var.name}-assets",
        "arn:aws:s3:::${var.name}-assets/*"
      ]
    },
    {
      "Sid": "DenyUnEncryptedObjectUploads",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::${var.name}-assets/*",
      "Condition": {
        "StringNotEquals": {
          "s3:x-amz-server-side-encryption": "aws:kms"
        }
      }
    }
  ]
}
EOF
  tags {
    Name = "${var.name}-ci"
    Project = "${var.name}"
    Team = "${var.team}"
    Owner = "${var.owner}"
    Environment = "${var.environment}"
    EnvironmentId = "${module.stack.environment_id}"
  }
}
