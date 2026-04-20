# modules/wireguard/routeros/main.tf
#
# RouterOS WireGuard endpoint deployment.
# Creates the WireGuard interface, IP address, peer, firewall rules,
# MSS clamping, and interface-list membership on a RouterOS device.

resource "routeros_interface_wireguard" "this" {
  name        = var.config.tunnel_name
  listen_port = var.config.listen_port
  private_key = var.config.private_key
  comment     = var.config.tunnel_name
}

resource "routeros_ip_address" "this" {
  address   = "${split("/", var.config.address)[0]}/${split("/", var.subnet)[1]}"
  interface = routeros_interface_wireguard.this.name
  comment   = var.config.tunnel_name
}

resource "routeros_interface_wireguard_peer" "this" {
  interface            = routeros_interface_wireguard.this.name
  public_key           = var.peer.public_key
  allowed_address      = concat(["${split("/", var.peer.address)[0]}/32"], var.allowed_nets)
  endpoint_address     = var.peer.endpoint_host
  endpoint_port        = var.peer.listen_port
  preshared_key        = var.config.preshared_key
  persistent_keepalive = "25s"
  comment              = "${var.config.tunnel_name}:${var.peer.hostname}"
}

resource "routeros_ip_firewall_filter" "wireguard_input" {
  action   = "accept"
  chain    = "input"
  protocol = "udp"
  dst_port = tostring(var.config.listen_port)
  comment  = "${var.config.tunnel_name}-input"
}

resource "routeros_ip_firewall_mangle" "this" {
  chain         = "forward"
  action        = "change-mss"
  new_mss       = "clamp-to-pmtu"
  passthrough   = true
  tcp_flags     = "syn"
  protocol      = "tcp"
  out_interface = routeros_interface_wireguard.this.name
  comment       = "garuda-${var.config.tunnel_name}"
}

resource "routeros_interface_list_member" "wireguard_lan" {
  interface = routeros_interface_wireguard.this.name
  list      = var.interface_list
  comment   = var.config.tunnel_name
}

# --- OSPF control plane ---
# Inlined from the former modules/routing call so that OSPF adjacency
# lives next to the tunnel it belongs to. Names are preserved
# ("garuda-ospf" / "garuda-backbone") for backwards compatibility with
# existing RouterOS state and the reconcile_routeros.yml nuke playbook.

resource "routeros_routing_ospf_instance" "this" {
  name      = "garuda-ospf"
  router_id = var.router_id
  comment   = "garuda-ospf"
}

resource "routeros_routing_ospf_area" "this" {
  name     = "garuda-backbone"
  instance = routeros_routing_ospf_instance.this.name
  area_id  = var.ospf_area
  comment  = "garuda-backbone"
}

resource "routeros_routing_ospf_interface_template" "tunnel" {
  area           = routeros_routing_ospf_area.this.name
  interfaces     = toset([var.config.tunnel_name])
  type           = "ptp"
  cost           = var.border_cost
  hello_interval = "${var.ospf_hello_interval}s"
  dead_interval  = "${var.ospf_dead_interval}s"
  comment        = var.config.tunnel_name
}

resource "routeros_routing_ospf_interface_template" "lan" {
  for_each = toset(var.mesh_lan_interfaces)

  area       = routeros_routing_ospf_area.this.name
  interfaces = toset([each.value])
  passive    = true
  comment    = each.value
}
