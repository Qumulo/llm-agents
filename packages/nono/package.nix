{
  lib,
  stdenv,
  rustPlatform,
  fetchFromGitHub,
  dbus,
  pkg-config,
  autoPatchelfHook,
  versionCheckHook,
  ...
}:

rustPlatform.buildRustPackage rec {
  pname = "nono";
  version = "0.47.1";

  src = fetchFromGitHub {
    owner = "always-further";
    repo = "nono";
    rev = "v${version}";
    hash = "sha256-5b/JhofT4jilciQf3r6zs9PVl14Ga0U4urfFGnCrDvI=";
  };

  cargoHash = "sha256-3pLFtIz1z8tWsnL6bKq9gzpXP3MTf4G3Ispv9Is1UQE=";

  # keyring uses sync-secret-service (dbus) on Linux, apple-native on Darwin
  buildInputs = lib.optionals stdenv.hostPlatform.isLinux [ dbus ];
  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isLinux [
    pkg-config
    autoPatchelfHook
  ];

  doCheck = false;

  doInstallCheck = true;
  nativeInstallCheckInputs = [
    versionCheckHook
  ];

  passthru.category = "Utilities";

  meta = with lib; {
    description = "Kernel-enforced agent sandbox. Capability-based isolation with secure key management, atomic rollback, cryptographic immutable audit chain of provenance. Run your agents in a zero-trust environment.";
    homepage = "https://nono.sh/";
    changelog = "https://github.com/always-further/nono/releases/tag/v${version}";
    license = licenses.asl20;
    sourceProvenance = with sourceTypes; [ fromSource ];
    maintainers = with maintainers; [ pogobanane ];
    mainProgram = "nono";
    platforms = platforms.unix;
  };
}
