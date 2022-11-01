# Copyright (c) Tetrate, Inc 2021 All Rights Reserved.
# 
# Default variables
terraform_apply_args = -compact-warnings -auto-approve
terraform_destroy_args = -compact-warnings -auto-approve 
terraform_workspace_args = -force
terraform_output_args = -json
#terraform_apply_args = 
# Functions

.PHONY: all
all: tsb_class

.PHONY: help
help : Makefile
	@sed -n 's/^##//p' $<

## init					 	 terraform init
.PHONY: init
init:

## gcp_k8s					 deploys GKE K8s cluster (CPs only)
.PHONY: gcp_k8s_class
gcp_k8s_class: init
	@/bin/sh -c '\
		cd "infra/gcp"; \
		terraform init; \
		terraform apply ${terraform_apply_args} -target module.gcp_base -var-file="../../terraform.tfvars.json"; \
		terraform apply ${terraform_apply_args} -var-file="../../terraform.tfvars.json"; \
		cd "../.."; \
		'

.PHONY: tsb_mp_class
tsb_mp:
	@echo "Refreshing k8s access tokens..."
	@make gcp_k8s_class
	@echo "Deploying TSB Management Plane..."
	@/bin/sh -c '\
	student_count=`jq -r '.student.count' terraform.tfvars.json`; \
	cluster_count=`jq -r '.student.clusters' terraform.tfvars.json`; \
	for (( index = 0; index < $$student_count; ++index )); do \
	let cluster_id=index*cluster_count; \
	cd "tsb/mp"; \
	terraform workspace new student_$$index; \
	terraform workspace select student_$$index; \
	terraform init; \
	terraform apply ${terraform_apply_args} -target=module.cert-manager -target=module.es -var-file="../../terraform.tfvars.json" -var=cluster_id=$$cluster_id -var=student_count_index=$$index; \
	terraform apply ${terraform_apply_args} -target=module.tsb_mp.kubectl_manifest.manifests_certs -var-file="../../terraform.tfvars.json" -var=cluster_id=$$cluster_id -var=student_count_index=$$index; \
	terraform apply ${terraform_apply_args} -var-file="../../terraform.tfvars.json" -var=cluster_id=$$cluster_id -var=student_count_index=$$index; \
	done; \
	terraform workspace select default; \
	cd "../.."; \
	'
## tsb_cp	                   
.PHONY: tsb_cp_class
tsb_cp:
	@echo "Refreshing k8s access tokens..."
	@echo "Onboarding clusters, i.e. TSB CP rollouts..."
	@make gcp_k8s_class
	@/bin/sh -c '\
	student_count=`jq -r '.student.count' terraform.tfvars.json`; \
	cluster_count=`jq -r '.student.clusters' terraform.tfvars.json`; \
	cluster_id=0; \
	for (( index = 0; index < $$student_count; ++index )); do \
		let cluster_id++; \
		let cluster_count="cluster_count * (1 + index)"; \
		while [ $$cluster_id -lt $$cluster_count ]; do \
		cd "tsb/cp"; \
		terraform workspace new gcp-student$$index-$$cluster_id; \
		terraform workspace select gcp-student$$index-$$cluster_id; \
		terraform init; \
		terraform apply ${terraform_apply_args} -var-file="../../terraform.tfvars.json" -var=cluster_id=$$cluster_id -var=student_count_index=$$index; \
		let cluster_id++; \
		done; \
	done; \
	terraform workspace select default; \
	cd "../.."; \
	'

.PHONY: tsb_class
tsb_class: gcp_k8s_class tsb_mp tsb_cp

## destroy					 destroy the environment
.PHONY: destroy
destroy:
	@make gcp_k8s_class
	@/bin/sh -c '\
		student_count=`jq -r '.student.count' terraform.tfvars.json`; \
		cluster_count=`jq -r '.student.clusters' terraform.tfvars.json`; \
		for (( index = 0; index < $$student_count; ++index )); do \
		let cluster_id=index*cluster_count; \
		cd "tsb/mp"; \
		terraform workspace select student_$$index; \
		terraform destroy ${terraform_apply_args} -target=module.es -target=module.tsb_mp -target=module.gcp_register_fqdn -var-file="../../terraform.tfvars.json" -var=cluster_id=$$cluster_id -var=student_count_index=$$index; \
		done; \
		terraform workspace select default; \
	'
	@/bin/sh -c '\
		cd "tsb/cp"; \
		rm -rf terraform.tfstate.d/; \
		rm -rf terraform.tfstate; \
		cd "../.."; \
		'
	@/bin/sh -c '\
		cd "infra/gcp"; \
		terraform destroy ${terraform_destroy_args} -var-file="../../terraform.tfvars.json"; \
		cd "../.."; \
		'
	@/bin/sh -c '\
		cd "tsb/mp"; \
		rm -rf terraform.tfstate.d/; \
		rm -rf terraform.tfstate; \
		cd "../.."; \
		'