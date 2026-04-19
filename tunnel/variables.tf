variable "name" {
  description = "Stable tunnel name used as interface and workload identifier."
  type        = string
}

variable "subnet" {
  description = "CIDR subnet for the point-to-point tunnel (e.g. 10.9.19.0/24)."
  type        = string
}

variable "peers" {
  description = "Map of exactly two peers keyed by hostname. Each peer declares its tunnel address, listen port, and optional endpoint."
  type = map(object({
    address       = string
    listen_port   = number
    endpoint_host = optional(string)
  }))

  validation {
    condition     = length(var.peers) == 2
    error_message = "Exactly two peers must be provided."
  }

  validation {
    condition     = alltrue([for p in values(var.peers) : p.address != null && p.address != ""])
    error_message = "Each peer must have a non-empty address."
  }
}
