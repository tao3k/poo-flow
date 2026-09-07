{ pkgs, lib, config, inputs, ... }:

{
  # https://devenv.sh/basics/
  env.GREET = "devenv";

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
  ];

  # https://devenv.sh/languages/
  # languages.rust.enable = true;

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
  '' + lib.optionalString pkgs.stdenv.isDarwin ''
    # Homebrew Gerbil/Gambit selects the host C toolchain itself.  Nix's SDK
    # and compiler selectors form a mixed Darwin toolchain when inherited by
    # gxpkg, so keep them outside the native Gerbil build boundary.  Bazel and
    # Emscripten retain their own declared toolchains.
    unset SDKROOT DEVELOPER_DIR CC CXX
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
