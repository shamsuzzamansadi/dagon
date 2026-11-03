param($Exe, $Data, $Out)
. "$PSScriptRoot\common.ps1"
New-Item -ItemType Directory -Force -Path $Out | Out-Null
function Shot($h, $name) { [E2E]::Shot($h, "$Out\$name.png") }
function Wait($ms) { Start-Sleep -Milliseconds $ms }
function Save() { $f = "$Data\Storage\save.dat"; if (Test-Path $f) { (Get-Content -Raw $f) -replace "`n", ' ' } else { 'no save.dat' } }
"xinput slots: " + [E2E]::XInputSlots()
"storage before: " + ((Get-ChildItem "$Data\Storage" -ErrorAction SilentlyContinue | ForEach-Object Name) -join ',')

# First launch: clean storage.
$p = Launch $Exe $Data "$Out\run1.log"; $h = $p.MainWindowHandle
try {
	Wait 3000
	"client area: " + [E2E]::Client($h)
	Shot $h '01-main-menu-no-save'
	Tap $h 'Down'; Tap $h 'Down'; Tap $h 'Enter'; Wait 300
	Shot $h '02-controls-from-main-menu'
	Tap $h 'Esc'; Tap $h 'Down'; Tap $h 'Enter'; Wait 300
	Shot $h '03-credits'
	Tap $h 'Esc'; Tap $h 'Up'; Tap $h 'Up'; Tap $h 'Enter'; Wait 300
	Shot $h '04-settings-from-main-menu'
	Tap $h 'Esc'; Tap $h 'Up'; Tap $h 'Enter'; Wait 1500
	Shot $h '05-introduction'
	"after New Game: " + (Save)
	Tap $h 'Enter'; Wait 1200
	Shot $h '06-prompt-at-the-boat'
	Tap $h 'E'; Wait 500
	Shot $h '07-caption-at-the-boat'
	Hold $h 'D' 420; Wait 400
	Shot $h '08-prompt-at-the-fish'
	Tap $h 'E'; Wait 500
	Shot $h '09-caption-at-the-fish'
	Tap $h 'Esc'; Wait 300
	Shot $h '10-pause-menu'
	Tap $h 'Down'; Tap $h 'Enter'; Wait 1200
	Shot $h '11-after-restart-prompt-at-the-boat'
	Tap $h 'E'; Wait 500
	Shot $h '12-after-restart-caption-at-the-boat'
	# Rebind Interact to J.
	Tap $h 'Esc'; Wait 200; Tap $h 'Down'; Tap $h 'Down'; Tap $h 'Enter'; Wait 300
	foreach ($i in 1..5) { Tap $h 'Down' }
	Tap $h 'Enter'; Wait 200
	Tap $h 'J'; Wait 300
	Shot $h '13-interact-rebound-to-J'
	Tap $h 'Esc'; Wait 200; Tap $h 'Esc'
	# The earlier caption has to be gone, or these prove nothing.
	Wait 6000
	Shot $h '14-prompt-names-J-no-caption'
	Tap $h 'E'; Wait 500
	Shot $h '15-old-key-E-does-nothing'
	Tap $h 'J'; Wait 500
	Shot $h '16-J-examines-the-boat'
	Hold $h 'D' 420; Wait 400
	Tap $h 'J'; Wait 500
	Shot $h '17-J-examines-the-fish'
	# Controls from the pause menu shows the new key.
	Tap $h 'Esc'; Wait 200; foreach ($i in 1..3) { Tap $h 'Down' }; Tap $h 'Enter'; Wait 300
	Shot $h '18-controls-from-pause-menu'
	Tap $h 'Esc'; Wait 200; Tap $h 'Esc'; Wait 300
	# Walk and hop along the level to the checkpoint past the trench.
	$d = $Keys['D']
	$reached = $false
	foreach ($i in 1..60) {
		[E2E]::Key($h, $d[0], $d[1], $true, $d[2])
		Tap $h 'Space' 60
		Wait 340
		if ((Save) -match 'beat=abyss') { $reached = $true; break }
	}
	[E2E]::Key($h, $d[0], $d[1], $false, $d[2]); Wait 100
	"reached the checkpoint: $reached after $i hops"
	Shot $h '19-checkpoint-saved-notice'
	"after the checkpoint: " + (Save)
	Wait 500
	# Quit to Main Menu.
	Tap $h 'Esc'; Wait 200; foreach ($i in 1..4) { Tap $h 'Down' }; Tap $h 'Enter'; Wait 300
	Shot $h '20-quit-to-main-menu-confirmation'
	Tap $h 'Right'; Tap $h 'Enter'; Wait 1200
	Shot $h '21-main-menu-with-a-save'
	# Quit to Desktop from the main menu, where nothing can be lost, exits at once. Continue is focused, so four down to Quit.
	foreach ($i in 1..4) { Tap $h 'Down' }; Tap $h 'Enter'
	$exited = $p.WaitForExit(6000)
	"quit to desktop: exited=$exited exit code=" + $(if ($exited) { $p.ExitCode } else { 'still running' })
} finally { Finish $p }
"storage after first run: " + ((Get-ChildItem "$Data\Storage" | ForEach-Object Name) -join ',')

# Relaunch: Continue and the rebound key must both have survived.
$p = Launch $Exe $Data "$Out\run2.log"; $h = $p.MainWindowHandle
try {
	Wait 3000
	Shot $h '23-relaunched-continue-focused'
	Tap $h 'Enter'; Wait 1500
	Shot $h '24-continued-at-the-checkpoint'
	Tap $h 'Esc'; Wait 200; foreach ($i in 1..3) { Tap $h 'Down' }; Tap $h 'Enter'; Wait 300
	Shot $h '25-controls-show-J-after-relaunch'
	Tap $h 'Esc'; Wait 200; Tap $h 'Esc'; Wait 300
	Tap $h 'Esc'; Wait 200; Tap $h 'Down'; Tap $h 'Enter'; Wait 1200
	Shot $h '26-restart-returns-to-the-checkpoint'
	"still running after Continue and restart: " + (-not $p.HasExited)
	"save after Continue: " + (Save)
} finally { Finish $p }
