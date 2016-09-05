.PHONY: help terraformpre plan apply report

help:
	@echo Run \`make plan\` or \`make apply\` to proceed

terraformpre:
	rm -rf .terraform
	terraform remote config \
		-backend=s3 \
		-backend-config="bucket=suncorp-demo-ci" \
		-backend-config="key=terraform/state/terraform.tfstate" \
		-backend-config="region=ap-southeast-2" \
		-backend-config="encrypt=true" \
		-backend-config="kms_key_id=bfdfcad1-015a-41c4-b9f8-b68c95d6b06d"
	terraform get -update=true
	terraform remote pull
	@echo "export TF_VAR_github_app_id=\"$$(terraform output github_app_id 2> /dev/null)\"" > environment-variables.sh
	@echo "export TF_VAR_github_app_secret=\"$$(terraform output github_app_secret 2> /dev/null)\"" >> environment-variables.sh

plan: terraformpre
	@sh -c "source environment-variables.sh; terraform plan -var-file=./dev.tfvars"

apply: terraformpre
	@sh -c "source environment-variables.sh; terraform apply -var-file=./dev.tfvars"

destroy: terraformpre
	@sh -c "source environment-variables.sh; terraform destroy -var-file=./dev.tfvars"

report: terraformpre
	terraform output
