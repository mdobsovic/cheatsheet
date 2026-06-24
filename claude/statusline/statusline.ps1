# Claude Code statusline  --  Windows / PowerShell 5.1+ (works in any terminal: Windows Terminal, conhost, VS Code, Git Bash via powershell)
# Reads the "Status" hook JSON from stdin and prints one colored line.
# NOTE: no non-ASCII literals in this source on purpose (PS 5.1 reads BOM-less .ps1 as ANSI).
#       Block glyphs for the graph are produced at runtime via [char] codepoints; output is forced to UTF-8.

$ErrorActionPreference = 'SilentlyContinue'
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}

# ---- ANSI helpers -------------------------------------------------------
$E = [char]27
function Col([string]$code, [string]$text) { return ("{0}[{1}m{2}{0}[0m" -f $E, $code, $text) }

# 256-color palette
$GREEN   = '38;5;40'
$ORANGE  = '38;5;208'
$RED     = '38;5;196'
$CYAN    = '38;5;44'
$MAGENTA = '38;5;170'
$DIM     = '38;5;245'
$WHITE   = '38;5;252'
$YELLOW  = '38;5;220'

# resets_at from the Status JSON is a Unix timestamp in SECONDS -> compact "time left"
function ResetIn($epochSec) {
  if ($null -eq $epochSec) { return $null }
  try {
    $now = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
    $d = [long][double]$epochSec - $now
  } catch { return $null }
  if ($d -le 0) { return 'now' }
  $days = [math]::Floor($d / 86400); $d -= $days * 86400
  $hrs  = [math]::Floor($d / 3600);  $d -= $hrs * 3600
  $mins = [math]::Floor($d / 60)
  if ($days -gt 0) { return ('{0}d{1}h' -f $days, $hrs) }
  if ($hrs  -gt 0) { return ('{0}h{1}m' -f $hrs, $mins) }
  return ('{0}m' -f $mins)
}

# thresholds requested by the user: <50 green, 50-80 orange, >80 red
function UsageCode([double]$pct) {
  if ($pct -lt 50)      { return $GREEN }
  elseif ($pct -le 80)  { return $ORANGE }
  else                  { return $RED }
}

$IC = [Globalization.CultureInfo]::InvariantCulture
function Fmt($n) {
  if ($null -eq $n) { return '0' }
  $n = [double]$n
  if ($n -ge 1000000) { return (($n / 1000000).ToString('0.0', $IC) + 'M') }
  if ($n -ge 1000)    { return (($n / 1000).ToString('0.0', $IC) + 'k') }
  return ([int]$n).ToString($IC)
}
function SizeFmt($n) {
  if ($null -eq $n -or $n -eq 0) { return '?' }
  $n = [double]$n
  if ($n -ge 1000000) { return (($n / 1000000).ToString('0.#', $IC) + 'M') }
  if ($n -ge 1000)    { return (($n / 1000).ToString('0', $IC) + 'k') }
  return ([int]$n).ToString($IC)
}

try {
  $raw = [Console]::In.ReadToEnd()
  if (-not $raw) { exit 0 }
  $j = $raw | ConvertFrom-Json

  $parts = New-Object System.Collections.ArrayList

  # ---- model ----------------------------------------------------------
  $model = $j.model.display_name
  if (-not $model) { $model = $j.model.id }
  if (-not $model) { $model = 'Claude' }
  $modelSeg = Col $CYAN $model
  if ($j.fast_mode) { $modelSeg += (Col $DIM ' fast') }
  [void]$parts.Add($modelSeg)

  # ---- context window (graph + percent + tokens) ----------------------
  $cw = $j.context_window
  $ctxIn   = 0
  $ctxSize = 0
  $ctxPct  = $null
  if ($cw) {
    if ($null -ne $cw.total_input_tokens)  { $ctxIn   = [double]$cw.total_input_tokens }
    if ($null -ne $cw.context_window_size) { $ctxSize = [double]$cw.context_window_size }
    if ($null -ne $cw.used_percentage)     { $ctxPct  = [double]$cw.used_percentage }
  }
  if ($null -eq $ctxPct) {
    if ($ctxSize -gt 0) { $ctxPct = [math]::Round($ctxIn / $ctxSize * 100) } else { $ctxPct = 0 }
  }

  $w = 10
  $filled = [int][math]::Round($ctxPct / 100 * $w)
  if ($filled -lt 0) { $filled = 0 }
  if ($filled -gt $w) { $filled = $w }
  $full  = ([string][char]0x2588) * $filled
  $empty = ([string][char]0x2591) * ($w - $filled)
  $ccode = UsageCode $ctxPct
  $bar   = (Col $ccode $full) + (Col $DIM $empty)

  $ctxSeg = (Col $DIM 'ctx ') + $bar + ' ' + (Col $ccode ('{0}%' -f [int]$ctxPct)) +
            ' ' + (Col $DIM ('{0}/{1}' -f (Fmt $ctxIn), (SizeFmt $ctxSize)))
  [void]$parts.Add($ctxSeg)

  # ---- in / out tokens ------------------------------------------------
  $tin  = if ($cw) { $cw.total_input_tokens }  else { 0 }
  $tout = if ($cw) { $cw.total_output_tokens } else { 0 }
  $ioSeg = (Col $DIM 'in ') + (Col $WHITE (Fmt $tin)) + (Col $DIM '  out (last) ') + (Col $WHITE (Fmt $tout))
  [void]$parts.Add($ioSeg)

  # ---- session cost ---------------------------------------------------
  if ($j.cost -and $null -ne $j.cost.total_cost_usd) {
    $usd = [double]$j.cost.total_cost_usd
    [void]$parts.Add( (Col $YELLOW ('$' + $usd.ToString('0.00', $IC))) )
  }

  # ---- usage windows 5h / 7d -----------------------------------------
  $rl = $j.rate_limits
  $usageSeg = ''
  if ($rl -and $rl.five_hour -and $null -ne $rl.five_hour.used_percentage) {
    $p5 = [double]$rl.five_hour.used_percentage
    $usageSeg += (Col $DIM '5h ') + (Col (UsageCode $p5) ('{0}%' -f [int][math]::Round($p5)))
    $r5 = ResetIn $rl.five_hour.resets_at
    if ($r5) { $usageSeg += (Col $DIM (' ' + $r5)) }
  } else {
    $usageSeg += (Col $DIM '5h ') + (Col $DIM 'n/a')
  }
  $usageSeg += '  '
  if ($rl -and $rl.seven_day -and $null -ne $rl.seven_day.used_percentage) {
    $p7 = [double]$rl.seven_day.used_percentage
    $usageSeg += (Col $DIM '7d ') + (Col (UsageCode $p7) ('{0}%' -f [int][math]::Round($p7)))
    $r7 = ResetIn $rl.seven_day.resets_at
    if ($r7) { $usageSeg += (Col $DIM (' ' + $r7)) }
  } else {
    $usageSeg += (Col $DIM '7d ') + (Col $DIM 'n/a')
  }
  [void]$parts.Add($usageSeg)

  # ---- git branch (only if cwd is a git repo) -------------------------
  $dir = $null
  if ($j.workspace -and $j.workspace.current_dir) { $dir = $j.workspace.current_dir }
  elseif ($j.cwd) { $dir = $j.cwd }
  if ($dir) {
    try {
      $inside = & git -C "$dir" rev-parse --is-inside-work-tree 2>$null
      if ($LASTEXITCODE -eq 0 -and $inside -eq 'true') {
        $branch = (& git -C "$dir" branch --show-current 2>$null)
        if ($branch) { $branch = $branch.Trim() }
        if (-not $branch) {
          $sha = (& git -C "$dir" rev-parse --short HEAD 2>$null)
          if ($sha) { $branch = '@' + $sha.Trim() } else { $branch = 'no-commits' }
        }
        $gitIcon = ([string][char]0x2387)
        [void]$parts.Add( (Col $MAGENTA ($gitIcon + ' ' + $branch)) )
      }
    } catch {}
  }

  $sep = Col $DIM '  |  '
  [Console]::Out.Write(($parts -join $sep))
} catch {
  [Console]::Out.Write('Claude')
}
