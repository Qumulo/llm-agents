{
  lib,
  flake,
  buildNpmPackage,
  fetchFromGitHub,
  versionCheckHook,
  versionCheckHomeHook,
}:

buildNpmPackage rec {
  pname = "gnhf";
  version = "0.1.36";

  src = fetchFromGitHub {
    owner = "kunchenguid";
    repo = "gnhf";
    rev = "gnhf-v${version}";
    hash = "sha256-MRj1ST8lSmN37Uep/l9c2kDS6KHnT2/sVKrJs+X7Za8=";
  };

  npmDepsHash = "sha256-vNjwBnZAZzNyldlME8dlvz/h5bMH7a65r2+70cu9/fg=";

  doInstallCheck = true;
  nativeInstallCheckInputs = [
    versionCheckHook
    versionCheckHomeHook
  ];

  passthru.category = "AI Coding Agents";

  meta = with lib; {
    description = "Ralph/autoresearch-style orchestrator that keeps coding agents running while you sleep";
    homepage = "https://github.com/kunchenguid/gnhf";
    changelog = "https://github.com/kunchenguid/gnhf/releases/tag/gnhf-v${version}";
    license = licenses.mit;
    sourceProvenance = with sourceTypes; [ fromSource ];
    maintainers = with flake.lib.maintainers; [ pikdum ];
    mainProgram = "gnhf";
    platforms = platforms.all;
  };
}
