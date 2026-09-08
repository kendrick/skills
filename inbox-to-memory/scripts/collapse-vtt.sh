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
# and plain `Name: text` lines. Speech carrying neither form is attributed to
# @unknown, never to a name inferred from a neighbouring turn.
#
# The collapser drops the header and every NOTE, STYLE, and REGION block whole,
# because none of that is speech and all of it would otherwise land in whatever
# turn was open at the time. Cue identifiers are found by position, one line
# above the timing line, which is the only thing the spec guarantees about them.
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
  # Attribute one line of cue text to a turn. Always runs one line behind the
  # read, so a line reaches it only once the following line has proved it was
  # speech rather than a cue identifier.
  function emit(line,    who, said) {
    if (match(line, /^<v [^>]*>/)) {
      who = substr(line, 4, RLENGTH - 4)
      said = substr(line, RLENGTH + 1)
    } else if (match(line, /^[A-Z][A-Za-z.'"'"' -]*: /)) {
      who = substr(line, 1, RLENGTH - 2)
      said = substr(line, RLENGTH + 1)
    } else {
      # A continuation of the open turn. With no turn open, this is speech that
      # carries no label at all, which is what most machine-generated captions
      # look like. Inheriting the empty speaker leaves flush() with nothing to
      # print, so a speakerless file collapses to nothing while the run reports
      # success and phase 4 deletes the original. @unknown is the token this
      # skill already uses for a person nobody named, and it is never traded for
      # a name inferred from a neighbouring turn: an admitted gap beats a guess.
      who = (speaker == "" ? "@unknown" : speaker)
      said = line
    }
    sub(/<\/v>[[:space:]]*$/, "", said)
    if (who != speaker) { flush(); speaker = who; start = pending }
    text = (text == "" ? said : text " " said)
  }
  function emit_held() { if (holding) emit(held); holding = 0 }
  # A blank line terminates whatever is open: the header, a cue, or a comment
  # block. It is the only thing that closes any of them. Whatever line is held
  # is speech by now, since an identifier would be followed by a timing line.
  /^[[:space:]]*$/ { emit_held(); in_block = 0; in_cue = 0; next }
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
  / --> / {
    # A cue identifier is whatever sits on the line directly before the timing
    # line, and position is the only thing the spec guarantees about it. Matching
    # a bare integer instead covered hand-numbered transcripts and nothing else,
    # so a Teams or Zoom export keyed by <uuid>/<n>-<n> missed every branch and
    # landed in the speaker turn as text. The run still exits 0 and the output
    # still looks like turns, which is what made it expensive: the identifier
    # reached the raw zone of every turn in a 1,388-line transcript and the note
    # read as correct everywhere a reader is told to look.
    holding = 0
    # An @unknown turn ends where its cue does. With no label anywhere in the
    # file, the cue is the only unit of utterance on offer, and merging them
    # would leave one timestamp standing for a whole meeting. A labelled turn
    # still absorbs the unlabelled cues after it, since the captioner said whose
    # words those are.
    if (speaker == "@unknown") flush()
    split($1, t, "."); pending = t[1]; in_cue = 1; next
  }
  # Hold each content line for one iteration. The next line is what says whether
  # this one was speech or the identifier of the cue about to open.
  { emit_held(); held = $0; holding = 1 }
  END { emit_held(); flush() }
' "$1"
