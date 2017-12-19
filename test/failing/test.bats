#!/usr/bin/env bats

@test "failing test" {
  run ./ansible-test-role.sh "$BATS_TEST_DIRNAME/role"
  [ $status -eq 2 ]
}