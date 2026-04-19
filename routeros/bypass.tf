# modules/wireguard/routeros/bypass.tf
#
# Per-tunnel RouterOS WireGuard endpoint bypass.
# Creates a dedicated routing table, endpoint address-list entry,
# endpoint sync script, and scheduler for this tunnel.

resource "routeros_routing_table" "wg_bypass" {
  name    = "wg-bypass-${var.config.tunnel_name}"
  fib     = true
  comment = "WG endpoint bypass for ${var.config.tunnel_name}"
}

resource "routeros_ip_firewall_addr_list" "endpoint" {
  list    = "wg-endpoints-${var.config.tunnel_name}"
  address = var.peer.endpoint_host
  comment = var.config.tunnel_name
}

resource "routeros_system_script" "wg_endpoint_sync" {
  name   = "wg-endpoint-sync-${var.config.tunnel_name}"
  policy = ["read", "write", "test"]
  source = templatefile("${path.module}/templates/wg_endpoint_sync.rsc.tftpl", {
    tunnel_name = var.config.tunnel_name
    list_name   = "wg-endpoints-${var.config.tunnel_name}"
    table_name  = routeros_routing_table.wg_bypass.name
  })
  comment = "Managed by wireguard/routeros for ${var.config.tunnel_name}"
}

resource "routeros_system_scheduler" "wg_endpoint_sync" {
  name     = "wg-endpoint-sync-${var.config.tunnel_name}"
  interval = "1m"
  on_event = "/system script run ${routeros_system_script.wg_endpoint_sync.name}"
  policy   = ["read", "write", "test"]
  comment  = "Managed by wireguard/routeros for ${var.config.tunnel_name}"
}
