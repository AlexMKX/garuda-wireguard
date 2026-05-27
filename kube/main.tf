locals {
  ospf_values = var.ospf == null ? null : {
    router_id          = var.ospf.router_id
    interfaces         = var.ospf.interfaces
    passive_interfaces = var.ospf.passive_interfaces
    default_originate  = var.ospf.default_originate
    redistribute       = var.ospf.redistribute
    transit_provider   = try(var.ospf.transit_provider, false)
  }
  _frr_lib = "${path.module}/../../frr-sidecar/charts/frr-sidecar/templates"
  # Track frr-sidecar library chart template changes so helm_release
  # upgrades when library templates change (#51). Passed as a helm value
  # so tofu detects drift.
  runtime_patch_checksum = sha256(join("", [
    filesha256("${local._frr_lib}/_container.tpl"),
    filesha256("${local._frr_lib}/_frrconf.tpl"),
    filesha256("${local._frr_lib}/_initContainer.tpl"),
    filesha256("${local._frr_lib}/_volume.tpl"),
  ]))
}

resource "helm_release" "wireguard" {
  name             = var.name
  namespace        = var.namespace
  create_namespace = false
  chart            = "${path.module}/charts/wireguard"

  # Resolve the in-tree frr-sidecar library chart (declared via
  # `dependencies:` with `file://` repository) on every apply. Helm
  # packages it into charts/frr-sidecar-0.1.0.tgz (gitignored).
  dependency_update = true

  values = [
    yamlencode({
      namespace            = var.namespace
      name                 = var.name
      config               = var.config
      peer                 = var.peer
      allowed_nets         = var.allowed_nets
      table                = var.table
      persistent_keepalive = var.persistent_keepalive
      nic_attach           = var.nic_attach
      images = {
        wireguard = var.wireguard_image
        frr       = var.frr_image
      }
      ospf = local.ospf_values
      transit = {
        interfaces = var.transit.interfaces
      }
      runtimePatchChecksum = local.runtime_patch_checksum
    })
  ]
}
