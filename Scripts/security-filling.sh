#!/usr/bin/env bash
# oniux-ip-3x.sh
# Runs oniux curl -4 https://icanhazip.com three times immediately, then exits.

CMD=('oniux' 'curl' '-4' 'https://icanhazip.com')
COUNT=3

for ((i=1; i<=COUNT; i++)); do
  echo "[$(date --iso-8601=seconds)] Run #$i"
  "${CMD[@]}"
done

echo "[$(date --iso-8601=seconds)] All $COUNT runs completed."
