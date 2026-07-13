#!/usr/bin/env bash

test_require_args() {
  local expected_args="$1"
  shift

  [[ $# -eq "${expected_args}" ]] || {
    printf 'usage: %s expects %s argument(s)\n' "$0" "${expected_args}" >&2
    exit 2
  }
}

test_setup() {
  test_require_args "$@"
  test_root="$(mktemp -d)"
  trap 'rm -rf "${test_root}"' EXIT
}
