# main.tf
resource "helm_release" "trivy_operator" {
  name      = "trivy-operator"
  namespace = var.operator_namespace
  chart     = "${path.module}/helm"

  values = [
    templatefile("${path.module}/values.yaml", {
      operator_namespace   = var.operator_namespace
      operator_replicas    = var.operator_replicas
      image_registry       = var.image_registry
      image_repository     = var.image_repository
      image_tag            = var.image_tag
      compliance_cron      = var.compliance_cron
      mobius_deploymentid  = var.mobius_deploymentid
      mobius_datacenter    = var.mobius_datacenter
      mobius_component     = var.mobius_component
    })
  ]
}
