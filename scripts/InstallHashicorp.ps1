
write-host "Downloading Consul"
Import-Module BitsTransfer
Start-BitsTransfer -Source https://releases.hashicorp.com/consul/1.4.4+ent/consul_1.4.4+ent_windows_amd64.zip -Destination C:\Users\nicolas\Downloads\consul_1.4.4+ent_windows_amd64.zip

write-host "Unzipping Consul"
Expand-Archive C:\Users\nicolas\Downloads\consul_1.4.4+ent_windows_amd64.zip -DestinationPath C:\Hashicorp\Consul\

write-host "Create Consul Service"
sc.exe create "Hashicorp Consul" binPath= "C:\Hashicorp\Consul\consul.exe agent -config-file=C:\Hashicorp\Consul\config.json" start= auto

write-host "Start Consul Service"
sc.exe start "Hashicorp Consul" 

write-host "Downloading Nomad"
Start-BitsTransfer -Source https://releases.hashicorp.com/nomad/0.9.0/nomad_0.9.0_windows_amd64.zip -Destination C:\Users\nicolas\Downloads\nomad_0.9.0_windows_amd64.zip

write-host "Unzipping Nomad"
Expand-Archive C:\Users\nicolas\Downloads\nomad_0.9.0_windows_amd64.zip -DestinationPath C:\Hashicorp\Nomad\

write-host "Create Nomad Service"
sc.exe create "Hashicorp Nomad" binPath= "C:\Hashicorp\Nomad\nomad.exe agent -config-file=C:\Hashicorp\Nomad\config.json" start= auto

write-host "Start Nomad Service"
sc.exe start "Hashicorp Nomad" 
