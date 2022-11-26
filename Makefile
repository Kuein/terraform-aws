dev:
	terraform apply -var-file terraform.dev.tfvars -auto-approve

prod:
	terraform apply -var-file terraform.prod.tfvars -auto-approve

stage:
	terraform apply -var-file terraform.stage.tfvars -auto-approve



