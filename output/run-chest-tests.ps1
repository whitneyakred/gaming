$ErrorActionPreference = 'Stop'
$exe='C:\Users\peter\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe'
$hostRun=Start-Process -FilePath $exe -ArgumentList '--headless --path . --script res://tests/chest_multiplayer.gd -- --settings-test --chest-host' -WindowStyle Hidden -PassThru -RedirectStandardOutput output/chest-host.log -RedirectStandardError output/chest-host-errors.log
$guestRun=Start-Process -FilePath $exe -ArgumentList '--headless --path . --script res://tests/chest_multiplayer.gd -- --settings-test' -WindowStyle Hidden -PassThru -RedirectStandardOutput output/chest-guest.log -RedirectStandardError output/chest-guest-errors.log
$hostRun.WaitForExit(50000) | Out-Null
$guestRun.WaitForExit(2000) | Out-Null
Get-Content output/chest-host.log,output/chest-guest.log,output/chest-host-errors.log,output/chest-guest-errors.log -Tail 25
