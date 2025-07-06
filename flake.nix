{
  description = "A terminal workspace with batteries included";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        zellij = pkgs.rustPlatform.buildRustPackage rec {
          pname = "zellij";
          name = "zellij";

          src = pkgs.fetchFromGitHub {
            owner = "zellij-org";
            repo = "zellij";
            rev = "2580564d50bf4dad126e24c5174394779eaf8de3";
            hash = "sha256-a9qEH65SYRPwtFXEchUZM2xhYDd/9CDyckP23M56xWI=";
          };

          postPatch = ''
            substituteInPlace Cargo.toml \
              --replace-fail ', "vendored_curl"' ""
          '';

          useFetchCargoVendor = true;
          cargoHash = "sha256-P4VabkEFBvj2YkkhXqH/JZp3m3WMKcr0qUMhdorEm1Q=";

          env = {
            OPENSSL_NO_VENDOR = 1;
            RUSTFLAGS = "-C opt-level=3 -C target-cpu=native";
          };
          nativeBuildInputs = with pkgs; [
            installShellFiles
            pkg-config
            (lib.getDev curl)
          ];

          buildInputs = with pkgs; [
            curl
            openssl
          ];

          nativeCheckInputs = with pkgs; [
            writableTmpDirAsHomeHook
          ];

          nativeInstallCheckInputs = with pkgs; [
            versionCheckHook
          ];

          versionCheckProgramArg = "--version";
          doInstallCheck = true;

          installCheckPhase = pkgs.lib.optionalString (pkgs.stdenv.hostPlatform.libc == "glibc") ''
            runHook preInstallCheck
            ldd "$out/bin/zellij" | grep libcurl.so
            runHook postInstallCheck
          '';

          postInstall = pkgs.lib.optionalString (pkgs.stdenv.buildPlatform.canExecute pkgs.stdenv.hostPlatform) ''
            installShellCompletion --cmd $pname \
              --bash <($out/bin/zellij setup --generate-completion bash) \
              --fish <($out/bin/zellij setup --generate-completion fish) \
              --zsh <($out/bin/zellij setup --generate-completion zsh)
          '';

          meta = with pkgs.lib; {
            description = "Terminal workspace with batteries included";
            homepage = "https://zellij.dev/";
            license = licenses.mit;
            maintainers = with maintainers; [
              ifelse023
            ];
            mainProgram = "zellij";
          };
        };
      in
      {
        packages = {
          default = zellij;
          zellij = zellij;
        };

        apps = {
          default = flake-utils.lib.mkApp {
            drv = zellij;
          };
          zellij = flake-utils.lib.mkApp {
            drv = zellij;
          };
        };

        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            rustc
            cargo
            pkg-config
            curl
            openssl
          ];
        };
      }
    );
}
