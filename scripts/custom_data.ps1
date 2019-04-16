<powershell>
net user ${var.admin_username} '${var.admin_password}' /add /y
net localgroup administrators ${var.admin_username} /add

winrm quickconfig -q
winrm set winrm/config/winrs '@{MaxMemoryPerShellMB="300"}'
winrm set winrm/config '@{MaxTimeoutms="1800000"}'
winrm set winrm/config/service '@{AllowUnencrypted="true"}'
winrm set winrm/config/service/auth '@{Basic="true"}'

set-netfirewallprofile -Profile Domain, Public,Private -Enabled false

net stop winrm
sc.exe config winrm start=auto
net start winrm

</powershell>
