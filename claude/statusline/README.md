# Statusline pre Claude Code (PowerShell)

Tento priečinok obsahuje hotový **statusline** (stavový riadok) pre Claude Code na Windowse. Statusline je riadok, ktorý sa zobrazuje pod promptom v konzole a v prehľadnej forme ukazuje, čo sa práve deje v session.

## Ako statusline vyzerá

```
Opus 4.8 (1M context)  |  ctx ░░░░░░░░░░ 3% 34.3k/1M  |  in 34.3k  out 407  |  $0.31  |  5h 14% 3h10m  7d 34% 1d15h  |  git master
```

Čo jednotlivé časti znamenajú:

| Časť | Význam |
| --- | --- |
| `Opus 4.8 (1M context)` | aktuálne použitý **model** |
| `ctx ░░░░░░░░░░ 3% 34.3k/1M` | **obsadenosť kontextového okna** – grafický indikátor, percentá a absolútna hodnota (použité / veľkosť okna) |
| `in 34.3k  out 407` | počet **vstupných (in)** a **výstupných (out)** tokenov |
| `$0.31` | **cena** aktuálnej session |
| `5h 14% 3h10m  7d 34% 1d15h` | **využitie limitov** za 5 hodín a za 7 dní + koľko času zostáva do resetu |
| `git master` | ak je aktuálny priečinok **git projekt**, zobrazí sa názov vetvy (branch) |

Farba grafu a percent sa mení podľa obsadenosti: do 50 % zelená, 50–80 % oranžová, nad 80 % červená.

## Inštalácia

### 1. Skript `statusline.ps1`

Skript je napísaný v **PowerShelli**. Skopírujte súbor `statusline.ps1` z tohto priečinka do:

```
C:/Users/POUZIVATELSKE_MENO/.claude/statusline.ps1
```

(`POUZIVATELSKE_MENO` nahraďte vaším používateľským menom vo Windowse.)

### 2. Nastavenie v `settings.json`

Zo súboru `settings.json` v tomto priečinku stačí prebrať **iba časť `statusLine`** a vložiť ju do vášho vlastného `settings.json` (`C:/Users/POUZIVATELSKE_MENO/.claude/settings.json`):

```json
"statusLine": {
  "type": "command",
  "command": "powershell -NoProfile -ExecutionPolicy Bypass -File C:/Users/POUZIVATELSKE_MENO/.claude/statusline.ps1"
}
```

V ceste opäť nezabudnite nahradiť `POUZIVATELSKE_MENO` za svoje používateľské meno. Ak už nejaký `settings.json` máte, pridajte do neho len kľúč `statusLine`, ostatné nastavenia ponechajte.

Po reštarte Claude Code sa statusline zobrazí automaticky.

## Linux / macOS (Bash verzia)

Pre Linux a macOS je v tomto priečinku pripravený ekvivalentný skript **`statusline.sh`** s **úplne rovnakou funkcionalitou** ako `statusline.ps1` (rovnaký formát, rovnaké farby aj zaokrúhľovanie grafu).

### 1. Závislosť: `jq`

Bash verzia používa na čítanie JSON nástroj **`jq`**. Nainštalujte ho, ak ho ešte nemáte:

```bash
# Debian / Ubuntu
sudo apt install jq
# Fedora
sudo dnf install jq
# macOS (Homebrew)
brew install jq
```

(Ak `jq` chýba, statusline sa nezrúti – zobrazí len text `Claude`.)

### 2. Skript `statusline.sh`

Skopírujte súbor `statusline.sh` do `~/.claude/statusline.sh` a nastavte mu právo na spustenie:

```bash
cp statusline.sh ~/.claude/statusline.sh
chmod +x ~/.claude/statusline.sh
```

### 3. Nastavenie v `settings.json`

Do svojho `~/.claude/settings.json` pridajte kľúč `statusLine`:

```json
"statusLine": {
  "type": "command",
  "command": "bash ~/.claude/statusline.sh"
}
```

Po reštarte Claude Code sa statusline zobrazí automaticky.

## Video s presným postupom

Celý postup – ako takýto statusline vyrobiť (skript v tomto priečinku je v podstate **výsledkom tohto videa**) a ako ho nahodiť do konzoly – je krok za krokom natočený vo videu **„Statusline v Claude Code“** v našej službe **VideoClass**:

👉 https://www.itlearning.sk/videokurzy/

---

*IT LEARNING SLOVAKIA*
