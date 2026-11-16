param([ValidateSet('windows','linux','macos')][string[]]$Platforms = @('windows','linux','macos'))
$ErrorActionPreference = 'Stop'
$workspace = Split-Path $PSScriptRoot -Parent
$release = Invoke-RestMethod 'https://api.github.com/repos/3ddelano/epic-online-services-godot/releases/tags/2.3.1'
$staging = Join-Path $workspace '.godot/eos-install'
New-Item -ItemType Directory -Force $staging | Out-Null
foreach ($platform in $Platforms) {
    $asset = $release.assets | Where-Object name -eq "epic-online-services-godot-$platform-56238973e2cd7ac9ac99ca14f88934465f0a8997.zip"
    if (-not $asset) { throw "Pinned $platform package not found" }
    $zip = Join-Path $staging "$platform.zip"
    Invoke-WebRequest $asset.browser_download_url -OutFile $zip
    if ($asset.digest -like 'sha256:*') {
        $expected = $asset.digest.Substring(7)
        if ((Get-FileHash $zip -Algorithm SHA256).Hash.ToLower() -ne $expected) { throw 'Package checksum mismatch' }
    }
    $expanded = Join-Path $staging $platform
    Expand-Archive -LiteralPath $zip -DestinationPath $expanded -Force
    $source = Join-Path $expanded "epic-online-services-godot/addons/epic-online-services-godot/bin/$platform"
    $target = Join-Path $workspace 'addons/epic-online-services-godot/bin'
    New-Item -ItemType Directory -Force $target | Out-Null
    Copy-Item -LiteralPath $source -Destination $target -Recurse -Force
}
Write-Output 'EOSG 2.3.1 native dependencies installed. Reopen Godot to import them.'
