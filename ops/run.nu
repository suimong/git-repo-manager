export def update-cargo-dependencies [] {
  let cargo_config = open Cargo.toml

  mut update_necessary = true
  const TIERS = ["dependencies", "dev-dependencies"]

  for tier in $TIERS {
    $cargo_config 
    | get $tier 
    | transpose name dependency
    | each {|entry|
      let version = $entry.dependency 
      | get version 
      | str trim --char "="

      let args = [
        "upgrade",
        "--incompatible",
        "--pinned",
        "--ignore-rust-version",
        "--package", $entry.name
      ]
      run-external cargo ...$args

      let cargo_config_after_upgrade = open Cargo.toml
      let new_version = $cargo_config_after_upgrade
        | get $tier
        | transpose name dependency
        | where dependency == $entry.name
    }
  }
}
