param($Exe, $Data, $Out)
. "$PSScriptRoot\common.ps1"
New-Item -ItemType Directory -Force -Path $Out | Out-Null
$before = [E2E]::ForegroundLayout()
$p = Launch $Exe $Data "$Out\game.log"
$h = $p.MainWindowHandle
try {
	Start-Sleep -Seconds 3
	"client area: " + [E2E]::Client($h)
	[E2E]::Shot($h, "$Out\01-spawn-beside-the-boat.png")
	Tap $h 'E'; Start-Sleep -Milliseconds 400
	[E2E]::Shot($h, "$Out\02-pressed-E-at-the-boat.png")
	Hold $h 'D' 420; Start-Sleep -Milliseconds 300
	[E2E]::Shot($h, "$Out\03-walked-to-the-fish.png")
	Tap $h 'E'; Start-Sleep -Milliseconds 400
	[E2E]::Shot($h, "$Out\04-pressed-E-at-the-fish.png")
	Tap $h 'Esc'; Start-Sleep -Milliseconds 300
	[E2E]::Shot($h, "$Out\05-paused.png")
	Tap $h 'Esc'; Start-Sleep -Milliseconds 200
	foreach ($l in @(@('english',0x04090409L), @('german',0x04070407L), @('bangla',[long]0xFFFFFFFFF0C00845L))) {
		[E2E]::Layout($h, $l[1]); Start-Sleep -Milliseconds 300
		Tap $h 'E'; Start-Sleep -Milliseconds 400
		[E2E]::Shot($h, "$Out\06-$($l[0])-pressed-E.png")
		Tap $h 'Esc'; Tap $h 'Down'; Tap $h 'Down'; Tap $h 'Enter'; Start-Sleep -Milliseconds 300
		[E2E]::Shot($h, "$Out\07-$($l[0])-settings.png")
		Tap $h 'Esc'; Tap $h 'Esc'; Start-Sleep -Milliseconds 200
	}
	"still running: " + (-not $p.HasExited)
} finally { Finish $p }
"user layout before and after: $before " + [E2E]::ForegroundLayout()
