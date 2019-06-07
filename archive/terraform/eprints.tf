# eprints



resource "null_resource" "build" {
  
  provisioner "local-exec" "build" {
    command = "docker tag archive_archives ${module.azure_kubernetes.azure_container_registry_name}.azurecr.io/eprints/${var.name}"
    }
  
  provisioner "local-exec" "build" {
    command = "az acr login --name ${module.azure_kubernetes.azure_container_registry_name}"
    }
  
  provisioner "local-exec" "build" {
    command = "docker push ${module.azure_kubernetes.azure_container_registry_name}.azurecr.io/eprints/${var.name}"
    }
}

module "kubernetes_eprints" {
  source = "git::https://github.com/anarchist-raccoons/terraform_kubernetes_deployment.git?ref=master"

  host = "${module.azure_kubernetes.host}"
  username = "${module.azure_kubernetes.username}"
  password = "${module.azure_kubernetes.password}"
  client_certificate = "${module.azure_kubernetes.client_certificate}"
  client_key = "${module.azure_kubernetes.client_key}"
  cluster_ca_certificate = "${module.azure_kubernetes.cluster_ca_certificate}"
  docker_image = "${module.azure_kubernetes.azure_container_registry_name}.azurecr.io/eprints/${var.name}"
  app_name = "eprints"
  primary_mount_path = "/opt/eprints3/archives/${var.name}/documents/disk0"
  # secondary_mount_path = "/opt/eprints3/archives/${var.name}/cfg/lang"
  secondary_mount_path = "/data"
  pvc_claim_name = "${module.kubernetes_pvc_eprints.pvc_claim_name}"
  port = 80
  image_pull_secrets = "${module.kubernetes_secret_docker.kubernetes_secret_name}"
  env_from = "${module.kubernetes_secret_env.kubernetes_secret_name}"
  load_balancer_source_ranges = "${var.developer_access}"
  load_balancer_ip = "${module.terraform_azure_public_ip_eprints.public_ip}"
  command = ["/bin/bash","-ce", "/bin/docker-entrypoint.sh"]
  # Creates a dependency on mariadb
  resource_version = ["${module.kubernetes_mariadb.service_resource_version}","${module.kubernetes_mariadb.deployment_resource_version}"]
}

# A Record

module "terraform_azure_dns_arecord_hyrax" {
  source = "git::https://github.com/anarchist-raccoons/terraform_azure_dns_arecord.git?ref=master"
  
  # Required - add to terraform.tvars
  subscription_id = "${var.subscription_id}"
  tenant_id = "${var.tenant_id}"
  client_id = "${var.client_id}"
  client_secret = "${var.client_secret}"
  owner = "${var.owner}"
  name = "${var.name}"
  
  zone_name = "${var.zone_name}"
  zone_resource_group = "${var.zone_resource_group}"
  record = "${module.terraform_azure_public_ip_eprints.public_ip}"
  
  # Labels
  environment = "${var.environment}"
  namespace-org = "${var.namespace-org}"
  org = "${var.org}"
  service = "${var.service}"
  product = "${var.product}"
  team = "${var.team}"
}

# Public IP
module "terraform_azure_public_ip_eprints" {
  source = "git::https://github.com/anarchist-raccoons/terraform_azure_public_ip.git?ref=master"
  
  # Required - add to terraform.tvars
  subscription_id = "${var.subscription_id}"
  tenant_id = "${var.tenant_id}"
  client_id = "${var.client_id}"
  client_secret = "${var.client_secret}"
  owner = "${var.owner}"
  name = "${var.name}"
  
  location = "${var.location}"
  resource_group = "${module.azure_kubernetes.azure_cluster_node_resource_group}"
  service_name = "eprints"
  
  # Labels
  environment = "${var.environment}"
  namespace-org = "${var.namespace-org}"
  org = "${var.org}"
  service = "${var.service}"
  product = "${var.product}"
  team = "${var.team}"
}

module "kubernetes_pvc_eprints" {
  source = "git::https://github.com/anarchist-raccoons/terraform_kubernetes_pvc.git?ref=master"

  host = "${module.azure_kubernetes.host}"
  username = "${module.azure_kubernetes.username}"
  password = "${module.azure_kubernetes.password}"
  client_certificate = "${module.azure_kubernetes.client_certificate}"
  client_key = "${module.azure_kubernetes.client_key}"
  cluster_ca_certificate = "${module.azure_kubernetes.cluster_ca_certificate}"
  
  volume = "eprints"

}