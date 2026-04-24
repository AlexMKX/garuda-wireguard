output "peers" {
  description = "Canonical peer config map keyed by caller-chosen peer key (e.g. core/edge)."
  value = {
    for peer_key, peer in var.peers : peer_key => {
      tunnel_name   = var.name
      subnet        = var.subnet
      address       = peer.address
      listen_port   = peer.listen_port
      endpoint_host = peer.endpoint_host
      private_key   = wireguard_asymmetric_key.peer[peer_key].private_key
      public_key    = wireguard_asymmetric_key.peer[peer_key].public_key
      preshared_key = wireguard_preshared_key.this.key
    }
  }
  sensitive = true
}
