#!/usr/bin/env bats

@test "cli params: too few arguments" {
  run ./ansible-test-role.sh
  [ "$status" -eq 1 ]
}

@test "cli params: show help -h" {
  run ./ansible-test-role.sh -h
  [ "$status" -eq 0 ]
}

@test "cli params: show help -?" {
  run ./ansible-test-role.sh -h
  [ "$status" -eq 0 ]
}

@test "cli params: show help --help" {
  run ./ansible-test-role.sh --help
  [ "$status" -eq 0 ]
}

@test "cli params: unknown parameter" {
  run ./ansible-test-role.sh --unknown
  [ "$status" -eq 1 ]
}

@test "cli params: nonexistent role" {
  run ./ansible-test-role.sh any-role-that-doesnt-exist
  [ "$status" -eq 2 ]
}