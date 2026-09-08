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
# and plain `Name: text` lines. The collapser drops the header and every NOTE,
# STYLE, and REGION block whole, because none of that is speech and all of it
# would otherwise land in whatever turn was open at the time.
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "usage: ${0##*/} <file.vtt>" >&2
  exit 2
fi

[[ -f "$1" ]] || {
  echo "not a file: $1" >&2
  exit 2
}

# The awk program is single-quoted, so a bare apostrophe anywhere below,
# including inside a comment, ends the quote and the script stops parsing.
# Write around it, or escape it the way the speaker pattern does.
awk '
  function flush() {
    # The trailing blank line is what makes a turn a markdown paragraph. With a
    # single newline, every renderer runs the whole transcript together as one.
    if (speaker != "") print "[" start "] " speaker ": " text "\n"
    speaker = ""; text = ""
  }
  # A blank line terminates whatever is open: the header, a cue, or a comment
  # block. It is the only thing that closes any of them.
  /^[[:space:]]*$/ { in_block = 0; in_cue = 0; next }
  # A block runs from its keyword to that blank line, and none of it is speech.
  # A line inside a block carries no `<v Name>` or `Name: ` prefix, so the
  # speaker branch below reads it as a continuation of the open turn. Skip the
  # keyword line alone and a comment an editor left about what legal pulled
  # from the recording comes back out attributed to a person, by name and
  # timestamp, in the zone the skill calls the source of truth.
  in_block { next }
  # A keyword opens a block only outside a cue. Inside one, a caption line
  # beginning with the word NOTE is something a person said. WEBVTT joins the
  # list because the header has the same grammar, and its `Kind: captions` line
  # otherwise matches the `Name: ` speaker form exactly.
  !in_cue && /^(WEBVTT|NOTE|STYLE|REGION)([ \t]|$)/ { in_block = 1; next }
  # Cue identifiers are a bare number on their own line and carry nothing.
  /^[0-9]+$/ { next }
  / --> / { split($1, t, "."); pending = t[1]; in_cue = 1; next }
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
