# mariadb
module "kubernetes_mariadb" {
  source = "git::https://github.com/anarchist-raccoons/terraform_kubernetes_deployment_simple_no_limitrange.git?ref=main"

  host = "${module.azure_kubernetes.host}"
  username = "${module.azure_kubernetes.username}"
  password = "${module.azure_kubernetes.password}"
  client_certificate = "${module.azure_kubernetes.client_certificate}"
  client_key = "${module.azure_kubernetes.client_key}"
  cluster_ca_certificate = "${module.azure_kubernetes.cluster_ca_certificate}"
  
  docker_image = "mariadb:10.4"
  app_name = "mariadb"
 
  mount_path = "/var/lib/mysql"
  pvc_claim_name = "${module.kubernetes_pvc_mariadb.pvc_claim_name}"

  # load_balancer_source_ranges = "${var.developer_access}"
  service_type = "ClusterIP"
  port = "3306"
  image_pull_secrets = "${module.kubernetes_secret_docker.kubernetes_secret_name}"
  env_from = "${module.kubernetes_secret_env.kubernetes_secret_name}"

#  container_memory_limit = "${var.container_memory_limit}"
#  container_memory_request = "${var.container_memory_request}"

#  container_cpu_limit = "${var.container_cpu_limit}"
#  container_cpu_request = "${var.container_cpu_request}"


}

module "kubernetes_pvc_mariadb" {
  source = "git::https://github.com/anarchist-raccoons/terraform_kubernetes_pvc.git?ref=main"

  host = "${module.azure_kubernetes.host}"
  username = "${module.azure_kubernetes.username}"
  password = "${module.azure_kubernetes.password}"
  client_certificate = "${module.azure_kubernetes.client_certificate}"
  client_key = "${module.azure_kubernetes.client_key}"
  cluster_ca_certificate = "${module.azure_kubernetes.cluster_ca_certificate}"
  
  mount_size = "${var.db_mount_size}"

  volume= "mariadb"
  storage_class_name = "azuredisk"

}
