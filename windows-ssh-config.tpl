Add-Content -Path "~\.ssh\config" -Value @'
Host ${hostname}
    HostName ${hostname}
    User ${user}
    IdentityFile ${identityfile}
'@

