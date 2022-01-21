#!/usr/bin/env bash

if [[ -f vault_pass ]]; then
  cat vault_pass
  exit
fi

PASS=$(secret-tool lookup "${ACCOUNT_NAME:-ansible_vault}" "${LABEL:-pass}")
if [[ $? == 0 ]]; then
  echo "$PASS"
  exit
fi

if [[ -n "$BW_SESSION" ]]; then
  bw get password 91925107-1449-49c1-992d-ae1f00b34532
  exit
fi
