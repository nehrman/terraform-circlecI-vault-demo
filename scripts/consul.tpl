
{
  "datacenter": "ukwest",
  "acl_datacenter": "ukwest",
  "acl_master_token": "8f04418582519d7989fceff77d8beb23",
  "acl_token": "8f04418582519d7989fceff77d8beb23",
  "acl_default_policy": "allow",
  "advertise_addr": "10.0.30.6",
  "advertise_addr_wan": "20.40.104.60",
  "bootstrap_expect": 3,
  "bind_addr": "0.0.0.0",
  "node_name": "demostack-windows-0",
  "ddata_dir": "C:\HashiCorp\Consul\data",
  "encrypt": "MDdkYzNhODFhZTQ5OWVjY2ZkYzNkNWEwMzFkNjA2NmQ=",
  "disable_update_check": true,
  "leave_on_terminate": true,
  "raft_protocol": 3,
  "retry_join": ["provider=azure tag_name=demostack  tag_value=demostack-bb4cbc8bab1cefe531097c09481b798d tenant_id=0e3e2e88-8caf-41ca-b4da-e3b33b6c52ec client_id=3b0bf866-d5c3-4134-976b-615dd6b8d4a5 subscription_id=8708baf2-0a54-4bb4-905b-78d21ac150da secret_access_key=61682315-a5a6-4b6e-a31f-98bde6d07e9c"],

  "server": true,
  "addresses": {
    "http": "0.0.0.0",
    "https": "0.0.0.0"
  },
  "ports": {
    "http": 8500,
    "https": 8533
  },
  "verify_incoming": false,
  "verify_outgoing": false,
  "verify_server_hostname": false,
  "ui": true,
  "autopilot": {
    "cleanup_dead_servers": true,
    "last_contact_threshold": "200ms",
    "max_trailing_logs": 250,
    "server_stabilization_time": "10s",
    "redundancy_zone_tag": "",
    "disable_upgrade_migration": false,
    "upgrade_version_tag": ""
},
 "connect":{
  "enabled": true,
      "proxy": {  "allow_managed_root": true  }
      }
}
