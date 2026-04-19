# modules/wireguard/linux/main.tf
#
# Linux WireGuard endpoint deployment.
# Assembles a wireguard payload from the canonical tunnel config/peer
# objects and delegates to linux_apply for Ansible-based deployment.

locals {
  peer_ip = split("/", var.peer.address)[0]

  config_listen_port = try(var.config.listen_port, null)
  peer_listen_port   = try(var.peer.listen_port, null)

  peer_endpoint_host   = try(trimspace(var.peer.endpoint_host), "")
  config_endpoint_host = try(trimspace(var.config.endpoint_host), "")

  post_up  = trimspace(var.post_up)
  pre_down = trimspace(var.pre_down)

  has_peer_endpoint        = local.peer_endpoint_host != ""
  has_config_endpoint_host = local.config_endpoint_host != ""
  has_config_listen_port   = local.config_listen_port != null
  has_peer_listen_port     = local.peer_listen_port != null

  required_payload = {
    wireguard_interface_name   = var.config.tunnel_name
    wireguard_address          = var.config.address
    wireguard_table            = var.table
    wireguard_private_key      = var.config.private_key
    wireguard_peer_public_key  = var.peer.public_key
    wireguard_peer_allowed_ips = join(", ", concat(["${local.peer_ip}/32"], var.allowed_nets))
    wireguard_labels           = var.labels
  }

  payload = merge(
    local.required_payload,
    local.has_config_listen_port ? {
      wireguard_listen_port = tostring(local.config_listen_port)
    } : {},
    local.has_config_endpoint_host ? {
      wireguard_public_endpoint = local.config_endpoint_host
    } : {},
    trimspace(var.config.preshared_key) != "" ? {
      wireguard_peer_preshared_key = var.config.preshared_key
    } : {},
    local.has_peer_endpoint && local.has_peer_listen_port ? {
      wireguard_peer_endpoint = "${local.peer_endpoint_host}:${local.peer_listen_port}"
    } : {},
    var.persistent_keepalive != null ? {
      wireguard_peer_persistent_keepalive = tostring(var.persistent_keepalive)
    } : {},
    local.post_up != "" ? {
      wireguard_post_up = var.post_up
    } : {},
    local.pre_down != "" ? {
      wireguard_pre_down = var.pre_down
    } : {},
    {
      wireguard_nic_attach = jsonencode(var.nic_attach)
    },
  )
}

module "linux_apply" {
  source = "../../linux_apply"

  host_name     = var.host_name
  workload_kind = "wireguard"
  payload       = local.payload

  connection_data = var.connection_data
  extra_hostvars  = var.extra_hostvars
}
