#!/usr/bin/env bash

secret-tool lookup "${ACCOUNT_NAME:-ansible_become_pass}" "${LABEL:-pass}"
