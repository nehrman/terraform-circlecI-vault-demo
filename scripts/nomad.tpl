name         = "demostack-servers-0"
data_dir     = "/mnt/nomad"
enable_debug = true

"bind_addr" = "0.0.0.0"


datacenter = "ukwest"

region = "azure"

advertise {
  http = "40.81.127.253:4646"
  rpc  = "40.81.127.253:4647"
  serf = "40.81.127.253:4648"
}
server {
  enabled          = true
  bootstrap_expect = 3
  encrypt          = "ZDFiYTgwZDkwNTgzOTJkNzdjOGU0ODUxM2RhYzI2ZDk="
}

client {
  enabled = true
   options {
    "driver.raw_exec.enable" = "1"
  }
}

tls {
  rpc  = true
  http = true

  ca_file   = "/usr/local/share/ca-certificates/01-me.crt"
  cert_file = "/etc/ssl/certs/me.crt"
  key_file  = "/etc/ssl/certs/me.key"

  verify_server_hostname = false
}

vault {
  enabled          = true
  address          = "https://active.vault.service.consul:8200"
  ca_file          = "/usr/local/share/ca-certificates/01-me.crt"
  cert_file        = "/etc/ssl/certs/me.crt"
  key_file         = "/etc/ssl/certs/me.key"
  create_from_role = "nomad-cluster"
}

autopilot {
    cleanup_dead_servers = true
    last_contact_threshold = "200ms"
    max_trailing_logs = 250
    server_stabilization_time = "10s"
    enable_redundancy_zones = false
    disable_upgrade_migration = false
    enable_custom_upgrades = false
}

