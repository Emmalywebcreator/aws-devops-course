#!/usr/bin/env bash
# subnet-calc.sh — a tiny CIDR calculator for checking your own subnet maths.
#
#   ./subnet-calc.sh 10.0.1.0/24                 facts about one block
#   ./subnet-calc.sh --split 10.0.0.0/16 24 5    the first 5 /24 blocks inside 10.0.0.0/16
#
# Plain bash integer arithmetic; works on Linux, WSL and macOS (bash 3.2+). No Python needed.
set -euo pipefail

die() { echo "subnet-calc: $*" >&2; exit 2; }

to_int() { # to_int a.b.c.d -> integer
  local a b c d; IFS=. read -r a b c d <<<"$1"
  for o in "$a" "$b" "$c" "$d"; do
    [[ "$o" =~ ^[0-9]+$ ]] && [ "$o" -le 255 ] || die "not an IPv4 address: $1"
  done
  echo $(( (a << 24) + (b << 16) + (c << 8) + d ))
}
to_dotted() { # to_dotted integer -> a.b.c.d
  echo "$(( ($1 >> 24) & 255 )).$(( ($1 >> 16) & 255 )).$(( ($1 >> 8) & 255 )).$(( $1 & 255 ))"
}
mask_of() { # mask_of prefix -> 32-bit mask integer
  if [ "$1" -eq 0 ]; then echo 0; else echo $(( (0xFFFFFFFF << (32 - $1)) & 0xFFFFFFFF )); fi
}
parse_cidr() { # sets ADDR and PREFIX
  [[ "$1" =~ ^([0-9.]+)/([0-9]+)$ ]] || die "expected a.b.c.d/prefix, got: $1"
  ADDR="${BASH_REMATCH[1]}"; PREFIX="${BASH_REMATCH[2]}"
  [ "$PREFIX" -le 32 ] || die "prefix must be 0-32, got: $PREFIX"
}

if [ "${1:-}" = "--split" ]; then
  [ $# -eq 4 ] || die "usage: $0 --split a.b.c.d/p new-prefix how-many"
  parse_cidr "$2"; NEW="$3"; HOWMANY="$4"
  [ "$NEW" -gt "$PREFIX" ] && [ "$NEW" -le 32 ] || die "new prefix must be bigger than $PREFIX and at most 32"
  NET=$(( $(to_int "$ADDR") & $(mask_of "$PREFIX") ))
  TOTAL=$(( 1 << (NEW - PREFIX) )); STEP=$(( 1 << (32 - NEW) ))
  echo "$2 splits into $TOTAL blocks of /$NEW (each $STEP addresses). First $HOWMANY:"
  i=0
  while [ "$i" -lt "$TOTAL" ] && [ "$i" -lt "$HOWMANY" ]; do
    echo "  $(to_dotted $(( NET + i * STEP )))/$NEW"; i=$(( i + 1 ))
  done
  exit 0
fi

[ $# -eq 1 ] || die "usage: $0 a.b.c.d/prefix   |   $0 --split a.b.c.d/p new-prefix how-many"
parse_cidr "$1"
IP=$(to_int "$ADDR"); MASK=$(mask_of "$PREFIX")
NET=$(( IP & MASK )); LAST=$(( NET | (~MASK & 0xFFFFFFFF) )); COUNT=$(( 1 << (32 - PREFIX) ))
[ "$IP" -eq "$NET" ] || echo "note: $ADDR has host bits set; the block it belongs to starts at $(to_dotted "$NET")" >&2
echo "Block           $(to_dotted "$NET")/$PREFIX"
echo "First address   $(to_dotted "$NET")"
echo "Last address    $(to_dotted "$LAST")"
echo "Addresses       $COUNT"
if [ "$COUNT" -gt 5 ]; then
  echo "Usable in an AWS subnet   $(( COUNT - 5 ))   (AWS reserves 5 addresses in every subnet)"
fi
