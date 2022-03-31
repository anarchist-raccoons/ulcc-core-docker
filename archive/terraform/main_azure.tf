# Cluster
module "azure_kubernetes" {
  source = "git::https://github.com/anarchist-raccoons/terraform_azure_kubernetes.git?ref=main"

  # Required - add to terraform.tvars
  subscription_id = "${var.subscription_id}"
  tenant_id = "${var.tenant_id}"
  client_id = "${var.client_id}"
  client_secret = "${var.client_secret}"
  owner = "${var.owner}"
  name = "${var.name}"
  ssh_key = "${var.ssh_key}"

  # Optional (default in place in variables.tf)
  #  add to terraform.tvars to override
  admin_user = "${var.admin_user}"
  location = "${var.location}"
  account_tier = "${var.account_tier}"
  vm_size = "${var.vm_size}"
  agent_count = "${var.agent_count}"
  disk_size_gb = "${var.disk_size_gb}"             
  account_replication_type = "${var.account_replication_type}" 

  # Labels
  environment = "${var.environment}"
  namespace-org = "${var.namespace-org}"
  org = "${var.org}"
  service = "${var.service}"
  product = "${var.product}"
  team = "${var.team}"
}

module "kubernetes_secret_docker" {
  source = "git::https://github.com/anarchist-raccoons/terraform_kubernetes_secret_docker.git?ref=main"

  host = "${module.azure_kubernetes.host}"
  username = "${module.azure_kubernetes.username}"
  password = "${module.azure_kubernetes.password}"
  client_certificate = "${module.azure_kubernetes.client_certificate}"
  client_key = "${module.azure_kubernetes.client_key}"
  cluster_ca_certificate = "${module.azure_kubernetes.cluster_ca_certificate}"

  kubernetes_secret = "image-pull-secrets"

  docker_username = "${module.azure_kubernetes.azure_container_registry_admin_username}"
  docker_password = "${module.azure_kubernetes.azure_container_registry_admin_password}"
  
}

module "kubernetes_secret_env" {
    source = "git::https://github.com/anarchist-raccoons/terraform_kubernetes_secret_env.git?ref=main"

  host = "${module.azure_kubernetes.host}"
  username = "${module.azure_kubernetes.username}"
  password = "${module.azure_kubernetes.password}"
  client_certificate = "${module.azure_kubernetes.client_certificate}"
  client_key = "${module.azure_kubernetes.client_key}"
  cluster_ca_certificate = "${module.azure_kubernetes.cluster_ca_certificate}"

  secrets = "${data.local_file.env_secrets.content}"
}

data "local_file" "env_secrets" {
    filename = "../.env"
}

module "kubernetes_storage" {
    source = "git::https://github.com/anarchist-raccoons/terraform_kubernetes_storage.git?ref=main"

  host = "${module.azure_kubernetes.host}"
  username = "${module.azure_kubernetes.username}"
  password = "${module.azure_kubernetes.password}"
  client_certificate = "${module.azure_kubernetes.client_certificate}"
  client_key = "${module.azure_kubernetes.client_key}"
  cluster_ca_certificate = "${module.azure_kubernetes.cluster_ca_certificate}"
}
