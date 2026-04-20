# Validates wireguard/routeros module interface, including inlined OSPF.
#
# OSPF resources were moved into this module by refactor
# "inline routeros tunnel control plane" so that OSPF adjacency is
# provisioned alongside the tunnel itself rather than by a separate
# modules/routing call.

mock_provider "routeros" {}

variables {
  hostname = "test-routeros"
  config = {
    hostname      = "test-routeros"
    tunnel_name   = "wg_test"
    address       = "10.9.20.2/24"
    private_key   = "aGVsbG8gd29ybGQ="
    public_key    = "aGVsbG8gd29ybGQ="
    preshared_key = "aGVsbG8gd29ybGQ="
    listen_port   = 51820
    endpoint_host = null
  }
  peer = {
    hostname      = "test-peer"
    tunnel_name   = "wg_test"
    address       = "10.9.20.1/24"
    private_key   = "aGVsbG8gd29ybGQ="
    public_key    = "aGVsbG8gd29ybGQ="
    preshared_key = "aGVsbG8gd29ybGQ="
    listen_port   = 51820
    endpoint_host = "1.2.3.4"
  }
  subnet         = "10.9.20.0/24"
  allowed_nets   = ["0.0.0.0/0"]
  interface_list = "LAN"

  router_id           = "10.9.20.2"
  ospf_area           = "0.0.0.0"
  border_cost         = 10
  mesh_lan_interfaces = ["ether1"]
}

run "contract_ospf_instance_created" {
  command = plan

  assert {
    condition     = routeros_routing_ospf_instance.this.name == "garuda-ospf"
    error_message = "OSPF instance must be named 'garuda-ospf' for consistency with the legacy routing module contract."
  }

  assert {
    condition     = routeros_routing_ospf_instance.this.router_id == var.router_id
    error_message = "OSPF instance router_id must be driven by var.router_id."
  }
}

run "contract_ospf_area_created" {
  command = plan

  assert {
    condition     = routeros_routing_ospf_area.this.name == "garuda-backbone"
    error_message = "OSPF area must be named 'garuda-backbone' for consistency with the legacy routing module contract."
  }

  assert {
    condition     = routeros_routing_ospf_area.this.area_id == var.ospf_area
    error_message = "OSPF area area_id must be driven by var.ospf_area."
  }
}

run "contract_ospf_tunnel_template_covers_tunnel_interface" {
  command = plan

  assert {
    condition     = contains([for tpl in routeros_routing_ospf_interface_template.tunnel : tpl.comment], var.config.tunnel_name)
    error_message = "A tunnel OSPF interface template must be emitted for the wireguard tunnel interface managed by this module."
  }
}

run "contract_ospf_lan_template_per_mesh_interface" {
  command = plan

  assert {
    condition     = length(routeros_routing_ospf_interface_template.lan) == length(var.mesh_lan_interfaces)
    error_message = "A passive OSPF interface template must be emitted for each mesh_lan_interfaces entry."
  }
}
