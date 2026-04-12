{
  description = "yardstick, packaged with uv2nix";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    pyproject-nix = {
      url = "github:nix-community/pyproject.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    nixpkgs,
    pyproject-nix,
    ...
  }: let
    inherit (nixpkgs) lib;
    systems = lib.systems.flakeExposed;
    forAllSystems = fn:
      lib.genAttrs systems (system: let
        pkgs = nixpkgs.legacyPackages.${system};
      in
        fn pkgs);

    pythonVersion = "python312";

    getPython = pkgs:
      pkgs.${pythonVersion}.override {
        packageOverrides = self: super: {
          # ANSIBLE requirement in pyproject.toml really strict, need to
          # override w/ specific version
          ansible = super.ansible.overrideAttrs (old: {
            version = "8.7.0";
            src = pkgs.fetchurl {
              url = "https://files.pythonhosted.org/packages/90/25/55e09468efe564f3b48c47a7e082bd84d4f0d064af60ac8458eba4667994/ansible-8.7.0.tar.gz";
              hash = "sha256-OlylFS5FR9WQ5AtULXaxjbvis22k7dAKE6fFGjdP9zc=";
            };
          });
        };
      };

    project = pyproject-nix.lib.project.loadPyproject {
      projectRoot = ./.;
    };

    buildProject = {
      pkgs,
      extra ? {},
    }: let
      python = getPython pkgs;
    in
      python.pkgs.buildPythonPackage
      ((project.renderers.buildPythonPackage {
          python = python;
          pythonPackages = python.pkgs;
        })
        // extra);
  in {
    packages = forAllSystems (pkgs: {
      default = buildProject {inherit pkgs;};
    });

    devShells = forAllSystems (pkgs: {
      default = pkgs.mkShell {
        packages = [
          (buildProject {inherit pkgs;})
          pkgs.python3Packages.pytest
        ];
      };
    });
  };
}
