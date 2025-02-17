variable "operator_namespace" {
  description = "Namespace in which to install the trivy-operator"
  type        = string
}

variable "operator_replicas" {
  description = "Number of replicas for trivy-operator"
  type        = number
  default     = 1
}

variable "image_registry" {
  description = "Registry for the trivy-operator image"
  type        = string
}

variable "image_repository" {
  description = "Repository for the trivy-operator image"
  type        = string
}

variable "image_tag" {
  description = "Tag for the trivy-operator image"
  type        = string
  default     = "latest"
}

variable "compliance_cron" {
  description = "Cron schedule for compliance report generation"
  type        = string
  default     = "0 */6 * * *"
}

variable "mobius_deploymentid" {
  description = "monius-deploymentid"
  type        = string
}

variable "mobius_datacenter" {
  description = "mobius-datacenter"
  type        = string
}

variable "mobius_component" {
  description = "mobius-component"
  type        = string
}