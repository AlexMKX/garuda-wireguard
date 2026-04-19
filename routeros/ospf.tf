# modules/wireguard/routeros/ospf.tf
#
# Per-tunnel RouterOS OSPF stack.
# Creates one dedicated OSPF instance and area per tunnel.
# Announces all connected prefixes into OSPF (redistribute=connected).

resource "routeros_routing_ospf_instance" "this" {
  name         = "garuda-${var.config.tunnel_name}"
  router_id    = var.router_id
  redistribute = ["connected"]
  comment      = "garuda-${var.config.tunnel_name}"
}

resource "routeros_routing_ospf_area" "this" {
  name     = "garuda-${var.config.tunnel_name}"
  instance = routeros_routing_ospf_instance.this.name
  area_id  = var.ospf_area
  comment  = "garuda-${var.config.tunnel_name}"
}

resource "routeros_routing_ospf_interface_template" "this" {
  area       = routeros_routing_ospf_area.this.name
  interfaces = toset([var.config.tunnel_name])
  type       = "ptp"
  comment    = var.config.tunnel_name
}
