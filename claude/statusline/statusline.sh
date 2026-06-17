#!/usr/bin/env bash
# Claude Code statusline  --  Linux / macOS (bash, funguje aj v zsh ked sa spusti cez bash)
# Reads the "Status" hook JSON from stdin and prints one colored line.
# Funkcionalita je zhodna s Windows verziou statusline.ps1.
# Zavislost: jq (JSON parser).  Block glyphs su priamo UTF-8 literaly v zdroji.

# ---- ANSI helpers -------------------------------------------------------
ESC=$'\033'
col() { # $1 = color code, $2 = text
  printf '%s[%sm%s%s[0m' "$ESC" "$1" "$2" "$ESC"
}

# 256-color palette
GREEN='38;5;40'
ORANGE='38;5;208'
RED='38;5;196'
CYAN='38;5;44'
MAGENTA='38;5;170'
DIM='38;5;245'
WHITE='38;5;252'
YELLOW='38;5;220'

# round half to even (zhoda s PowerShell [math]::Round - bankarske zaokruhlovanie)
AWK_BR='function br(v,  r,d){ r=int(v); d=v-r; if(d<0.5) return r; else if(d>0.5) return r+1; else return (r%2==0)?r:r+1 }'

# thresholds: <50 green, 50-80 orange, >80 red
usage_code() { # $1 = pct (float ok) -> prints color code
  awk -v p="$1" 'BEGIN{ if(p<50) print "38;5;40"; else if(p<=80) print "38;5;208"; else print "38;5;196" }'
}

# Fmt: "0.0k" / "0.0M" style with one decimal
fmt() {
  awk -v n="$1" 'BEGIN{
    if(n=="") n=0;
    if(n>=1000000)      printf "%.1fM", n/1000000;
    else if(n>=1000)    printf "%.1fk", n/1000;
    else                printf "%d", n;
  }'
}

# SizeFmt: "?" for 0/empty, "0M" (drop trailing .0) / "0k" (no decimals)
size_fmt() {
  awk -v n="$1" 'BEGIN{
    if(n=="" || n+0==0){ print "?"; exit }
    if(n>=1000000){ v=n/1000000; if(v==int(v)) printf "%dM", v; else printf "%.1fM", v }
    else if(n>=1000){ printf "%dk", n/1000 }
    else { printf "%d", n }
  }'
}

# resets_at is a Unix timestamp in SECONDS -> compact "time left"
reset_in() { # $1 = epoch seconds
  local epoch="$1"
  [ -z "$epoch" ] && return 0
  [ "$epoch" = "null" ] && return 0
  local now d days hrs mins
  now=$(date +%s)
  d=$(awk -v e="$epoch" -v n="$now" 'BEGIN{ printf "%d", int(e)-n }')
  if [ "$d" -le 0 ]; then printf 'now'; return 0; fi
  days=$(( d / 86400 )); d=$(( d - days*86400 ))
  hrs=$(( d / 3600 ));   d=$(( d - hrs*3600 ))
  mins=$(( d / 60 ))
  if [ "$days" -gt 0 ]; then printf '%dd%dh' "$days" "$hrs"; return 0; fi
  if [ "$hrs"  -gt 0 ]; then printf '%dh%dm' "$hrs" "$mins"; return 0; fi
  printf '%dm' "$mins"
}

# ---- read stdin ---------------------------------------------------------
raw=$(cat)
[ -z "$raw" ] && exit 0

# Bez jq vieme zobrazit len fallback.
if ! command -v jq >/dev/null 2>&1; then
  printf 'Claude'
  exit 0
fi

# Vsetky polia naraz, kazde na samostatnom riadku. Posledny prvok "." je sentinel:
# command substitution orezava koncove newliny, takze sentinel ochrani pripad,
# ked je posledne realne pole (dir) prazdne. Polia citame cez 'while read', aby
# sa zachovali aj prazdne medzipolia (napr. model.id) - to by 'IFS=... read' zlucil.
field_data=$(printf '%s' "$raw" | jq -r '
  [ (.model.display_name // ""),
    (.model.id // ""),
    (.fast_mode // false | tostring),
    (.context_window.total_input_tokens // 0),
    (.context_window.context_window_size // 0),
    (.context_window.used_percentage // ""),
    (.context_window.total_output_tokens // 0),
    (.cost.total_cost_usd // ""),
    (.rate_limits.five_hour.used_percentage // ""),
    (.rate_limits.five_hour.resets_at // ""),
    (.rate_limits.seven_day.used_percentage // ""),
    (.rate_limits.seven_day.resets_at // ""),
    (.workspace.current_dir // .cwd // ""),
    "."
  ] | .[]') || { printf 'Claude'; exit 0; }

fields=()
while IFS= read -r f; do fields+=("$f"); done <<EOF
$field_data
EOF

model_dn=${fields[0]};  model_id=${fields[1]};  fast_mode=${fields[2]}
ctx_in=${fields[3]};    ctx_size=${fields[4]};  ctx_pct=${fields[5]};  ctx_out=${fields[6]}
cost=${fields[7]};      p5=${fields[8]};        r5=${fields[9]}
p7=${fields[10]};       r7=${fields[11]};       dir=${fields[12]}

parts=()

# ---- model --------------------------------------------------------------
model="$model_dn"
[ -z "$model" ] && model="$model_id"
[ -z "$model" ] && model="Claude"
model_seg=$(col "$CYAN" "$model")
[ "$fast_mode" = "true" ] && model_seg="$model_seg$(col "$DIM" ' fast')"
parts+=("$model_seg")

# ---- context window (graph + percent + tokens) --------------------------
[ -z "$ctx_in" ]   && ctx_in=0
[ -z "$ctx_size" ] && ctx_size=0
[ -z "$ctx_out" ]  && ctx_out=0
if [ -z "$ctx_pct" ]; then
  ctx_pct=$(awk -v i="$ctx_in" -v s="$ctx_size" "$AWK_BR"' BEGIN{ if(s>0) printf "%d", br(i/s*100); else print 0 }')
fi

w=10
filled=$(awk -v p="$ctx_pct" -v w="$w" "$AWK_BR"' BEGIN{ f=br(p/100*w); if(f<0)f=0; if(f>w)f=w; print f }')
empty=$(( w - filled ))
full=""; for ((x=0; x<filled; x++)); do full+="█"; done
empty_s=""; for ((x=0; x<empty; x++)); do empty_s+="░"; done

ccode=$(usage_code "$ctx_pct")
bar="$(col "$ccode" "$full")$(col "$DIM" "$empty_s")"
ctx_pct_int=$(awk -v p="$ctx_pct" 'BEGIN{ printf "%d", p }')

ctx_seg="$(col "$DIM" 'ctx ')$bar $(col "$ccode" "${ctx_pct_int}%") $(col "$DIM" "$(fmt "$ctx_in")/$(size_fmt "$ctx_size")")"
parts+=("$ctx_seg")

# ---- in / out tokens ----------------------------------------------------
io_seg="$(col "$DIM" 'in ')$(col "$WHITE" "$(fmt "$ctx_in")")$(col "$DIM" '  out ')$(col "$WHITE" "$(fmt "$ctx_out")")"
parts+=("$io_seg")

# ---- session cost -------------------------------------------------------
if [ -n "$cost" ]; then
  usd=$(awk -v c="$cost" 'BEGIN{ printf "%.2f", c }')
  parts+=("$(col "$YELLOW" "\$$usd")")
fi

# ---- usage windows 5h / 7d ---------------------------------------------
usage_seg=""
if [ -n "$p5" ]; then
  p5r=$(awk -v p="$p5" "$AWK_BR"' BEGIN{ printf "%d", br(p) }')
  usage_seg="$(col "$DIM" '5h ')$(col "$(usage_code "$p5")" "${p5r}%")"
  rr=$(reset_in "$r5"); [ -n "$rr" ] && usage_seg="$usage_seg$(col "$DIM" " $rr")"
else
  usage_seg="$(col "$DIM" '5h ')$(col "$DIM" 'n/a')"
fi
usage_seg="$usage_seg  "
if [ -n "$p7" ]; then
  p7r=$(awk -v p="$p7" "$AWK_BR"' BEGIN{ printf "%d", br(p) }')
  usage_seg="$usage_seg$(col "$DIM" '7d ')$(col "$(usage_code "$p7")" "${p7r}%")"
  rr=$(reset_in "$r7"); [ -n "$rr" ] && usage_seg="$usage_seg$(col "$DIM" " $rr")"
else
  usage_seg="$usage_seg$(col "$DIM" '7d ')$(col "$DIM" 'n/a')"
fi
parts+=("$usage_seg")

# ---- git branch (only if cwd is a git repo) -----------------------------
if [ -n "$dir" ]; then
  if git -C "$dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    branch=$(git -C "$dir" branch --show-current 2>/dev/null)
    if [ -z "$branch" ]; then
      sha=$(git -C "$dir" rev-parse --short HEAD 2>/dev/null)
      if [ -n "$sha" ]; then branch="@$sha"; else branch="no-commits"; fi
    fi
    parts+=("$(col "$MAGENTA" "git $branch")")
  fi
fi

# ---- join with separator ------------------------------------------------
sep=$(col "$DIM" '  |  ')
out=""
for i in "${!parts[@]}"; do
  if [ "$i" -eq 0 ]; then out="${parts[$i]}"; else out="$out$sep${parts[$i]}"; fi
done
printf '%s' "$out"
