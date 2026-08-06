#!/usr/bin/env bash
# Collapse a WebVTT transcript into speaker turns on stdout.
#
# This is the one sanctioned exception to keeping raw content exactly as captured.
# A caption file breaks a sentence across four cues at two seconds apiece, and the
# raw content zone exists for a human reading back: a wall of timestamps is not
# something anyone reads. The words themselves are never altered, only regrouped,
# and the timestamp of each turn's first cue is kept so a quote stays locatable.
#
# Handles both speaker forms VTT uses in the wild: `<v Name>text</v>` voice spans
# and plain `Name: text` lines.
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "usage: ${0##*/} <file.vtt>" >&2
  exit 2
fi

[[ -f "$1" ]] || {
  echo "not a file: $1" >&2
  exit 2
}

awk '
  function flush() {
    if (speaker != "") print "[" start "] " speaker ": " text
    speaker = ""; text = ""
  }
  /^WEBVTT/ || /^NOTE/ || /^[[:space:]]*$/ { next }
  # Cue identifiers are a bare number on their own line and carry nothing.
  /^[0-9]+$/ { next }
  / --> / { split($1, t, "."); pending = t[1]; next }
  {
    line = $0
    if (match(line, /^<v [^>]*>/)) {
      who = substr(line, 4, RLENGTH - 4)
      said = substr(line, RLENGTH + 1)
    } else if (match(line, /^[A-Z][A-Za-z.'"'"' -]*: /)) {
      who = substr(line, 1, RLENGTH - 2)
      said = substr(line, RLENGTH + 1)
    } else {
      # A continuation line of the current turn, with no speaker of its own.
      who = speaker
      said = line
    }
    sub(/<\/v>[[:space:]]*$/, "", said)

    if (who != speaker) { flush(); speaker = who; start = pending }
    text = (text == "" ? said : text " " said)
  }
  END { flush() }
' "$1"
