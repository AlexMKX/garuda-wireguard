output "peers" {
  description = "Canonical peer config map keyed by hostname."
  value = {
    for hostname, peer in var.peers : hostname => {
      hostname      = hostname
      tunnel_name   = var.name
      subnet        = var.subnet
      address       = peer.address
      listen_port   = peer.listen_port
      endpoint_host = peer.endpoint_host
      private_key   = wireguard_asymmetric_key.peer[hostname].private_key
      public_key    = wireguard_asymmetric_key.peer[hostname].public_key
      preshared_key = wireguard_preshared_key.this.key
    }
  }
  sensitive = true
}
