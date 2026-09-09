{ pkgs, lib, config, inputs, ... }:

{
  # https://devenv.sh/basics/
  env.GREET = "devenv";

  # Homebrew Gerbil/Gambit must compile against the host system SDK. Nix tools
  # such as Bazel, Rust, and Emscripten retain their own explicit toolchains.
  apple.sdk = null;

  # https://devenv.sh/packages/
  packages = [
    pkgs.typst
    pkgs.git
    pkgs.actionlint
    pkgs.bazelisk
    pkgs.emscripten
    pkgs.lld
    pkgs.binaryen
    pkgs.bazel-buildtools
    pkgs.nodejs_24
    # The lockfile and lean-toolchain remain the source pins. These tools make
    # `just build-cedar-runtime-host OUT` available through the generated
    # devenv profile entrypoint.
    pkgs.elan
    pkgs.just
  ];

  languages.rust = {
    enable = true;
    channel = "stable";
    # Ensure rust can link python library
    components = [
      "rustc"
      "cargo"
      "clippy"
      "rustfmt"
    ];
  };

  # https://devenv.sh/processes/
  # processes.dev.exec = "${lib.getExe pkgs.watchexec} -n -- ls -la";

  # https://devenv.sh/services/
  # services.postgres.enable = true;

  # https://devenv.sh/scripts/
  scripts.hello.exec = ''
    echo hello from $GREET
  '';

  # https://devenv.sh/basics/
  enterShell = ''
    hello         # Run scripts directly
    git --version # Use packages
  '';

  # https://devenv.sh/tasks/
  # tasks = {
  #   "myproj:setup".exec = "mytool build";
  #   "devenv:enterShell".after = [ "myproj:setup" ];
  # };

  # https://devenv.sh/tests/
  enterTest = ''
    echo "Running tests"
    git --version | grep --color=auto "${pkgs.git.version}"
  '';

  # https://devenv.sh/git-hooks/
  # git-hooks.hooks.shellcheck.enable = true;

  # See full reference at https://devenv.sh/reference/options/
}
