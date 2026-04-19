# modules/wireguard/tunnel/main.tf
#
# Canonical WireGuard tunnel data: key generation and normalized peer output.
# This module owns no deployment logic and no routing/OSPF/FRR concerns.

resource "wireguard_asymmetric_key" "peer" {
  for_each = var.peers
}

resource "wireguard_preshared_key" "this" {}
