{
  lib,
  python3,
  fetchFromGitHub,
}:

let
  python = python3.override {
    self = python;
    packageOverrides = _final: prev: {
      # fastmcp test suite hangs on x86_64-linux with current nixpkgs pin
      # (some async tests block past the 3h builder timeout). Skip checks
      # since we only need it as a runtime dependency.
      fastmcp = prev.fastmcp.overridePythonAttrs { doCheck = false; };

      # The pinned nixpkgs builds lupa with `LUPA_NO_BUNDLE` against system
      # luajit, which only yields a single `lupa.lua` backend module.
      # fakeredis (pulled in via fastmcp -> pydocket) hard-codes
      # `lupa.lua51`, so `code-review-graph serve` blows up at startup
      # (numtide/llm-agents.nix#4497). Upstream restored the versioned
      # backends in NixOS/nixpkgs#514692 / #514916; drop this override once
      # our nixpkgs pin includes those commits
      # (tracking: numtide/llm-agents.nix#4509).
      lupa = prev.lupa.overridePythonAttrs (old: {
        src = old.src.override {
          fetchSubmodules = true;
          hash = "sha256-XLBUQ1TrzWWST9RJdMTnpsceldDNzidnL82bixLhSRA=";
        };
        env = { };
        nativeBuildInputs = [ ];
        buildInputs = [ ];
        pythonImportsCheck = (old.pythonImportsCheck or [ ]) ++ [ "lupa.lua51" ];
      });
    };
  };

in
python.pkgs.buildPythonApplication rec {
  pname = "code-review-graph";
  version = "2.3.2";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "tirth8205";
    repo = "code-review-graph";
    rev = "v${version}";
    hash = "sha256-2U+NfPOb2A/gmqzRUQ/80C5EhOHPM4YpGilZmVSTY/g=";
  };

  build-system = with python.pkgs; [
    hatchling
  ];

  # Upstream pins tree-sitter-language-pack <1 and watchdog <6, but nixpkgs
  # has advanced to 1.x and 6.x. The runtime deps check is overly strict.
  pypaBuildFlags = [ "--skip-dependency-check" ];

  dependencies = with python.pkgs; [
    mcp
    fastmcp
    tree-sitter
    tree-sitter-language-pack
    networkx
    watchdog
  ];

  # Relax version constraints — nixpkgs versions are newer but compatible.
  pythonRelaxDeps = [
    "tree-sitter-language-pack"
    "watchdog"
  ];

  pythonImportsCheck = [
    "code_review_graph"
    # Regression test for numtide/llm-agents.nix#4497: the `serve` command
    # pulls in fakeredis' Lua scripting support, which requires lupa to ship
    # the version-suffixed `lupa.lua51` backend module.
    "fakeredis.commands_mixins.scripting_mixin"
  ];

  passthru.category = "Code Review";

  meta = with lib; {
    description = "Local knowledge graph for AI coding agents — builds persistent map of your codebase for token-efficient code reviews";
    homepage = "https://github.com/tirth8205/code-review-graph";
    changelog = "https://github.com/tirth8205/code-review-graph/releases/tag/v${version}";
    license = licenses.mit;
    sourceProvenance = with sourceTypes; [ fromSource ];
    maintainers = with maintainers; [ aldoborrero ];
    # x86_64-darwin excluded: no upstream CI / not validated.
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
      "aarch64-darwin"
    ];
    mainProgram = "code-review-graph";
  };
}
