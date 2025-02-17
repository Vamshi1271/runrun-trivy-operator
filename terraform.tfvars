operator_namespace                      = "trivy-system"
operator_replicas                       = 2
image_registry                          = "mirror.gcr.io"
image_repository                        = "aquasec/trivy-operator"
compliance_cron                         = "0 */6 * * *"
mobius_deploymentid                     = "testing"
mobius_datacenter                       = "sify"
mobius_component                        = "trivy"
