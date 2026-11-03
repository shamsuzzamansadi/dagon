param($Exe, $Data, $Out)
# Reads the layout the game was given, and changes nothing: no layout request is sent to any window.
. "$PSScriptRoot\common.ps1"
New-Item -ItemType Directory -Force -Path $Out | Out-Null
function Shot($h, $name) { [E2E]::Shot($h, "$Out\$name.png") }
function Wait($ms) { Start-Sleep -Milliseconds $ms }
"foreground before: " + [E2E]::ForegroundLayout()
$p = Launch $Exe $Data "$Out\layout.log"; $h = $p.MainWindowHandle
try {
	Wait 3000
	"the game's own layout: " + [E2E]::WindowLayout($h)
	Tap $h 'Enter'; Wait 1500; Tap $h 'Enter'; Wait 1200
	Shot $h 'current-layout-prompt'
	Tap $h 'E'; Wait 500
	Shot $h 'current-layout-pressed-E'
	Tap $h 'Esc'; Wait 200; Tap $h 'Down'; Tap $h 'Down'; Tap $h 'Enter'; Wait 300
	Shot $h 'current-layout-settings'
	"the game's own layout at the end: " + [E2E]::WindowLayout($h)
} finally { Finish $p }
"foreground after: " + [E2E]::ForegroundLayout()
