{
  lib,
  stdenv,
  buildGoLatestModule,
  fetchFromGitHub,
  stdenvNoCC,
  dejavu_fonts,
  ffmpeg,
  fontconfig,
  git,
  mesa,
  vulkan-loader,
  nix-update-script,
  nixosTests,
  nodejs,
  pnpm_11,
  fetchPnpmDeps,
  pnpmConfigHook,
  typescript,
  versionCheckHook,
}:

let
  pname = "upbrr";
  version = "0.3.1";
  src = fetchFromGitHub {
    owner = "autobrr";
    repo = "upbrr";
    tag = "v${version}";
    hash = "sha256-EmMXkFPV339U1qIwxmtRbhqLbA23lc8WV3RqsEF6Puk=";
  };

  upbrr-webui = stdenvNoCC.mkDerivation {
    pname = "${pname}-webui";
    inherit src version;

    nativeBuildInputs = [
      nodejs
      pnpmConfigHook
      pnpm_11
      typescript
    ];

    sourceRoot = "${src.name}/webui";

    pnpmDeps = fetchPnpmDeps {
      inherit (upbrr-webui)
        pname
        version
        src
        sourceRoot
        ;
      pnpm = pnpm_11;
      fetcherVersion = 4;
      hash = "sha256-eMpoFe+TfD1MVQM4JrXrfgc4MNjkeDT3GAVXJ8sbp/A=";
    };

    postBuild = ''
      pnpm run build
  '';

    installPhase = ''
      cp -r dist $out
    '';
  };
in
buildGoLatestModule (finalAttrs: {
  inherit
    pname
    version
    src
    ;

  vendorHash = "sha256-fbqCCmSPfjtwyUituQ/wXvsm6Xs6QyJjvKOlpuPkr3w=";

  nativeBuildInputs = [ dejavu_fonts fontconfig ffmpeg mesa vulkan-loader git  ];
  preBuild = ''
    cp -r ${finalAttrs.passthru.upbrr-webui}/* internal/webserver/assets/
  '';

# CGO_ENABLED = 1;

  ldflags = [
    "-X main.version=${finalAttrs.version}"
    # "-X main.commit=${src.tag}"
  ];

  # Let's just smoke test it
  doCheck = false;

  # nativeInstallCheckInputs = [
    # versionCheckHook
  # ];
  # versionCheckProgram = "${placeholder "out"}/bin/upbrrctl";
  # versionCheckProgramArg = "version";

  passthru = {
    inherit upbrr-webui;
    updateScript = nix-update-script {
      extraArgs = [
        "--subpackage"
        "upbrr-webui"
      ];
    };
    # tests.testService = nixosTests.upbrr;
  };

  meta = {
    description = "Modern, easy to use download automation for torrents and usenet";
    license = lib.licenses.gpl2Plus;
    homepage = "https://upbrr.com/";
    changelog = "https://upbrr.com/release-notes/v${finalAttrs.version}";
    maintainers = with lib.maintainers; [ av-gal ];
    mainProgram = "upbrr";
    platforms = with lib.platforms; darwin ++ freebsd ++ linux;
  };
})
