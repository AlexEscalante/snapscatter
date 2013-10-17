@announce-stdout
Feature: snapscatter
  In order to create and distribute snapshots
  As a CLI
  I can execute several different commands

  Scenario: show available commands and options
    When I run `snapscatter`
    Then the output should contain "targets"
    And the output should contain "list"
    And the output should contain "go"

  Scenario: show all volumes available for snapshot
    When I run `snapscatter targets`
    Then the output should match /vol-[0-9a-f]+/

  Scenario: list all current snapshots
    When I run `snapscatter list`
    Then the output should match /snap-[0-9a-f]+/
