Feature: snapscatter
  In order to create and distribute snapshots
  As a CLI
  I can execute several different commands

  Scenario: show available commands and options
    When I run `snapscatter`
    Then the output should contain "targets"