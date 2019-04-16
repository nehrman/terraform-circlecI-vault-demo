
Import-Module BitsTransfer
Start-BitsTransfer -Source https://releases.hashicorp.com/consul/1.4.4+ent/consul_1.4.4+ent_windows_amd64.zip -Destination C:\Users\guyser\Downloads\consul_1.4.4+ent_windows_amd64.zip

Expand-Archive C:\Users\$env:username\Downloads\consul_1.4.4+ent_windows_amd64.zip -DestinationPath C:\Hashicorp\Consul\

sc.exe create "Consul" binPath= "C:\Hashicorp\Consul\consul.exe agent -dev" start= auto

sc.exe start "Consul" 

Start-BitsTransfer -Source https://releases.hashicorp.com/nomad/0.9.0/nomad_0.9.0_windows_amd64.zip -Destination C:\Users\guyser\Downloads\nomad_0.9.0_windows_amd64.zip
Expand-Archive C:\Users\$env:username\Downloads\nomad_0.9.0_windows_amd64.zip -DestinationPath C:\Hashicorp\Nomad\

sc.exe create "Nomad" binPath= "C:\Hashicorp\Nomad\nomad.exe agent -dev" start= auto

sc.exe start "Nomad" 

