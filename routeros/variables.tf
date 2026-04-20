# modules/wireguard/routeros/variables.tf
#
# RouterOS WireGuard endpoint deployment module.
# Accepts canonical tunnel data from modules/wireguard/tunnel and
# RouterOS-specific deployment arguments.

variable "hostname" {
  description = "RouterOS inventory hostname (used in resource comments)."
  type        = string
}

variable "config" {
  description = "Canonical tunnel config object for the RouterOS endpoint (from wireguard/tunnel output)."
  type = object({
    hostname      = string
    tunnel_name   = string
    address       = string
    private_key   = string
    public_key    = string
    preshared_key = string
    listen_port   = number
    endpoint_host = optional(string)
  })
}

variable "peer" {
  description = "Canonical tunnel config object for the remote endpoint (from wireguard/tunnel output)."
  type = object({
    hostname      = string
    tunnel_name   = string
    address       = string
    private_key   = string
    public_key    = string
    preshared_key = string
    listen_port   = number
    endpoint_host = optional(string)
  })
}

variable "subnet" {
  description = "CIDR subnet of the WireGuard tunnel (e.g. 10.9.20.0/24)."
  type        = string
}

variable "allowed_nets" {
  description = "Additional AllowedIPs routed through the tunnel beyond the peer /32."
  type        = list(string)
}

variable "interface_list" {
  description = "RouterOS interface list to add the WireGuard tunnel interface to."
  type        = string
  default     = "LAN"
}

# --- OSPF control plane ---
# OSPF on RouterOS is provisioned alongside the tunnel by this module
# (inlined from the former modules/routing call). This keeps tunnel-level
# adjacency state close to the tunnel it belongs to.

variable "router_id" {
  description = "OSPF router ID configured on the RouterOS instance."
  type        = string
}

variable "ospf_area" {
  description = "OSPF area identifier (e.g. \"0.0.0.0\" for the backbone)."
  type        = string
}

variable "border_cost" {
  description = "OSPF interface cost applied to the WireGuard tunnel interface template."
  type        = number
}

variable "mesh_lan_interfaces" {
  description = "RouterOS L3 interfaces owning node-local LAN prefixes that should be advertised as passive internal OSPF interfaces."
  type        = list(string)
  default     = []
}

variable "ospf_hello_interval" {
  description = "OSPF hello interval in seconds applied to the tunnel interface template."
  type        = number
  default     = 5
}

variable "ospf_dead_interval" {
  description = "OSPF dead interval in seconds applied to the tunnel interface template."
  type        = number
  default     = 15
}
