param($Exe, $Data, $Out)
# Does the old key examine after rebinding? Frames each second, then E alone, with no J press at all.
. "$PSScriptRoot\common.ps1"
New-Item -ItemType Directory -Force -Path $Out | Out-Null
function Shot($h, $name) { [E2E]::Shot($h, "$Out\$name.png") }
function Wait($ms) { Start-Sleep -Milliseconds $ms }
$sw = [System.Diagnostics.Stopwatch]::StartNew()
function Mark($what) { "{0,7} ms  {1}" -f $sw.ElapsedMilliseconds, $what }
$p = Launch $Exe $Data "$Out\run.log"; $h = $p.MainWindowHandle
try {
	Wait 3000
	Tap $h 'Enter'; Wait 1500; Tap $h 'Enter'; Wait 1200
	Tap $h 'E'; Wait 500
	Mark 'examined with E, before rebinding'
	Tap $h 'Esc'; Wait 300; Tap $h 'Down'; Tap $h 'Down'; Tap $h 'Enter'; Wait 300
	foreach ($i in 1..5) { Tap $h 'Down' }
	Tap $h 'Enter'; Wait 200; Tap $h 'J'; Wait 300
	Shot $h 'a0-rebound'
	Mark 'rebound to J'
	Tap $h 'Esc'; Wait 200; Tap $h 'Esc'
	Mark 'resumed'
	foreach ($i in 1..8) { Wait 1000; Shot $h "b$i-after-resume"; Mark "frame b$i" }
	Mark 'pressing old key E'
	Tap $h 'E'
	Mark 'E released'
	foreach ($i in 1..4) { Wait 150; Shot $h "c$i-after-E"; Mark "frame c$i" }
	Wait 5500
	Shot $h 'd1-before-second-E'
	Mark 'pressing old key E again'
	Tap $h 'E'; Wait 500
	Shot $h 'd2-after-second-E'
	Mark 'frame d2'
	Wait 5500
	Mark 'pressing new key J'
	Tap $h 'J'; Wait 500
	Shot $h 'e1-after-J'
	Mark 'frame e1'
} finally { Finish $p }
