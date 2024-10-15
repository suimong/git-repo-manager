export def main [] {
  "The task runner."
}

const static_target = "x86_64-unknown-linux-musl"
const args_static = [
  "--target" $static_target
  "--features=static-build"
]

def get-git-tracked-python-files [] {
  ^git ls-files | lines | filter {str ends-with ".py"}
}

export def check [] {
  fmt-check
  lint
  test
  ^cargo check
}

export def clean [] {
  ^cargo clean
  ^git clean -f -d -X
}

export def fmt [] {
  ^cargo fmt
  get-git-tracked-python-files | do {
    let input = $in
    ^isort ...$input
    ^black ...$input
  }
}

export def fmt-check [] {
  ^cargo fmt --check
  ^git ls-files 
    | lines
    | ^black --check ...(get-git-tracked-python-files)
}

export def lint [] {
  ^cargo clippy --no-deps -- -Dwarnings
  ^ruff check --ignore E501 (get-git-tracked-python-files)
}

export def lint-fix [] {
  ^cargo clippy --no-deps --fix
}

export def build-release [
  --static # Build a statically linked binary.
] {
  let args_base = [
    "build", "--release"
  ]

  let args = match $static {
    false => $args_base
    true => ($args_base ++ $args_static)
  }

  run-external cargo ...$args
}

export def pushall [] {
  for $r in (^git remote | lines) {
    for $b in ["develop" "master"] {
      ^git push $r $b
    }
  }
}

export def release [
  --patch 
] {
  # TODO: convert from release.sh
}

export def test-binary [] {
  let envs = {
    GITHUB_API_BASEURL: "http://rest:5000/github"
    GITLAB_API_BASEURL: "http://rest:5000/gitlab"
  }
  with-env $envs {
    ^cargo build --profile e2e-tests --target $static_target --features=static-build
  }
}

export def install [
  --static
] {
  let args_base = [
    "install"
    "--path" "."
  ]
  let args = match $static {
    true => {$args_base ++ $args_static}
    false => $args_base
  }

  run-external cargo ...$args
}

export def build [
  --static
] {
  let args_base = ["build"]
  let args = match $static {
    true => {$args_base ++ $args_static}
    false => $args_base
  }
  run-external cargo ...$args
}

export def test [] {
  test-unit
  test-integration
  test-e2e
}

export def test-unit [
  tests: string = ""
] {
  ^cargo test --lib --bins -- --show-output $tests
}

export def test-integration [] {
  ^cargo test --test "*"
}

export def test-e2e [] {
  test-binary
  
  cd ./e2e_tests
  docker compose rm --stop -f
  docker compose build
  let vol_host = [
    $env.PROJECT_ROOT
    "target/x86_64-unknown-linux-musl/e2e-tests/grm"
  ] | path join
  let vol_ctr = "/grm"
  let compose_args = [
    "--rm"
    "-v", $"($vol_host):($vol_ctr)"
    "pytest"
    "GRM_BINARY=/grm ALTERNATE_DOMAIN=alternate-rest python3 -m pytest --exitfirst -p no:cacheprovider --color=yes "$@""
  ]
  run-external docker compose run ...$compose_args
}

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

