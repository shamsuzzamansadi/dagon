$ErrorActionPreference = 'Stop'
Add-Type -TypeDefinition (Get-Content -Raw "$PSScriptRoot\E2E.cs") -ReferencedAssemblies System.Drawing
[E2E]::SetProcessDPIAware() | Out-Null
$Keys = @{ E=@(0x45,0x12,$false); D=@(0x44,0x20,$false); A=@(0x41,0x1E,$false); J=@(0x4A,0x24,$false); Space=@(0x20,0x39,$false); Esc=@(0x1B,0x01,$false); Enter=@(0x0D,0x1C,$false);
           Up=@(0x26,0x48,$true); Down=@(0x28,0x50,$true); Left=@(0x25,0x4B,$true); Right=@(0x27,0x4D,$true) }
function Tap($h, $k, $ms = 90) { $d = $Keys[$k]; [E2E]::Key($h, $d[0], $d[1], $true, $d[2]); Start-Sleep -Milliseconds $ms; [E2E]::Key($h, $d[0], $d[1], $false, $d[2]); Start-Sleep -Milliseconds 140 }
function Hold($h, $k, $ms) { Tap $h $k $ms }
function Launch($exe, $data, $log) {
	New-Item -ItemType Directory -Force -Path "$data\AppData", "$data\Storage" | Out-Null
	$psi = New-Object System.Diagnostics.ProcessStartInfo
	$psi.FileName = $exe; $psi.WorkingDirectory = Split-Path $exe; $psi.UseShellExecute = $false
	$psi.Arguments = "--verbose --log-file `"$log`""
	$psi.EnvironmentVariables['APPDATA'] = "$data\AppData"
	$psi.EnvironmentVariables['DAGON_STORAGE_DIR'] = "$data\Storage".Replace('\','/')
	$p = [System.Diagnostics.Process]::Start($psi)
	for ($i = 0; $i -lt 100 -and $p.MainWindowHandle -eq 0; $i++) { Start-Sleep -Milliseconds 100; $p.Refresh() }
	if ($p.MainWindowHandle -eq 0) { throw 'no window' }
	return $p
}
function Finish($p) { if (-not $p.HasExited) { $p.Kill(); $p.WaitForExit(5000) | Out-Null } }
