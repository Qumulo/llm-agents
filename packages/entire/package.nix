{
  lib,
  buildGoModule,
  fetchFromGitHub,
  flake,
  go_1_26,
  unpinGoModVersionHook,
  versionCheckHook,
  versionCheckHomeHook,
}:

(buildGoModule.override { go = go_1_26; }) rec {
  pname = "entire";
  version = "0.6.0";

  src = fetchFromGitHub {
    owner = "entireio";
    repo = "cli";
    rev = "v${version}";
    hash = "sha256-U4nNkWafQXn6SWPxt8y/R2ifb27uzkUXOulbuvHojvo=";
  };

  nativeBuildInputs = [ unpinGoModVersionHook ];

  vendorHash = "sha256-R5cnPz0geDu8m26uZ9p/71f8XC+4A2HVuo3gPSsgXpA=";

  subPackages = [ "./cmd/entire" ];

  ldflags = [
    "-s"
    "-w"
    "-X=github.com/entireio/cli/cmd/entire/cli/versioninfo.Version=${version}"
  ];

  doCheck = false;

  doInstallCheck = true;
  nativeInstallCheckInputs = [
    versionCheckHook
    versionCheckHomeHook
  ];
  versionCheckProgramArg = [ "version" ];

  passthru.category = "Utilities";

  meta = with lib; {
    description = "CLI tool that captures AI agent sessions and links them to code changes";
    homepage = "https://github.com/entireio/cli";
    changelog = "https://github.com/entireio/cli/releases/tag/v${version}";
    license = licenses.mit;
    sourceProvenance = with sourceTypes; [ fromSource ];
    maintainers = with flake.lib.maintainers; [ yutakobayashidev ];
    mainProgram = "entire";
    platforms = platforms.linux ++ platforms.darwin;
  };
}
