# Validates the tunnel-centric RouterOS module contract.

mock_provider "routeros" {}

variables {
  hostname = "routeros-test"
  config = {
    tunnel_name   = "wg_tik"
    address       = "10.9.20.2/24"
    private_key   = "aGVsbG8gd29ybGQ="
    public_key    = "aGVsbG8gd29ybGQ="
    preshared_key = "aGVsbG8gd29ybGQ="
    listen_port   = 13231
  }
  peer = {
    tunnel_name   = "wg_tik"
    address       = "10.9.20.1/24"
    private_key   = "aGVsbG8gd29ybGQ="
    public_key    = "aGVsbG8gd29ybGQ="
    preshared_key = "aGVsbG8gd29ybGQ="
    listen_port   = 55825
    endpoint_host = "vpn.example.com"
  }
  subnet         = "10.9.20.0/24"
  allowed_nets   = ["0.0.0.0/0", "224.0.0.0/4"]
  interface_list = "LAN"
  router_id      = "10.9.20.2"
  ospf_area      = "0.0.0.0"
}

run "contract_routeros_tunnel_stack" {
  command = plan

  assert {
    condition     = routeros_routing_ospf_instance.this.name == "garuda-wg_tik"
    error_message = "RouterOS module must create a per-tunnel OSPF instance"
  }

  assert {
    condition     = contains(tolist(routeros_routing_ospf_instance.this.redistribute), "connected")
    error_message = "RouterOS OSPF instance must redistribute connected routes"
  }

  assert {
    condition     = routeros_routing_table.wg_bypass.name == "wg-bypass-wg_tik"
    error_message = "RouterOS module must create a per-tunnel bypass routing table"
  }

  assert {
    condition     = routeros_system_scheduler.wg_endpoint_sync.interval == "1m"
    error_message = "RouterOS module must schedule endpoint sync every minute"
  }
}

run "contract_requires_peer_endpoint_host" {
  command = plan

  variables {
    peer = {
      tunnel_name   = "wg_tik"
      address       = "10.9.20.1/24"
      private_key   = "aGVsbG8gd29ybGQ="
      public_key    = "aGVsbG8gd29ybGQ="
      preshared_key = "aGVsbG8gd29ybGQ="
      listen_port   = 55825
    }
  }

  expect_failures = [var.peer]
}
