{
  name ? "ankisyncd",
  tag ? null,
  system ? builtins.currentSystem,
  pkgs ? import ./nixpkgs.nix { inherit system; }
}:
let
  # All contents of the image need to be compiled for linux. This is needed
  # in case the image is built on other system (which is possible as long
  # as there is a remote builder which can build the linux part).
  pkgsLinux = import pkgs.path {
    system = "x86_64-linux";
    inherit (pkgs) overlays config;
  };

  makeImageOptions = pkgs:
    let
      ankisyncd = import ./ankisyncd.nix { inherit pkgs; };
      with-env-from-dir = import ./with-env-from-dir { inherit pkgs; };

      startup-script = pkgs.writers.writeBash "startup-script" ''
        set -ueo pipefail
        exec ${with-env-from-dir} /secrets "${ankisyncd}/bin/ankisyncd"
      ''
      ;
    in
      {
        inherit name;

        contents = with pkgs; [
          cacert
          busybox
        ];

        config = {
          Cmd = [ "${startup-script}" ];
          Env = [
            "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
          ];
        };

        layeringPipeline = [
          # Separate python and it's exclusive deps. Facilitates sharing between
          # images of applications built on the same version of python.
          ["split_paths" [pkgs.python3]]
          [
            # Apply pipeline below to the "rest" result of the previous split.
            "over"
            "rest"
            [
              "pipe"
              [
                ["split_paths" [ankisyncd]]
                [
                  "over"
                  # "main" contains ankisyncd application and it's dependencies.
                  "main"
                  [
                    "pipe"
                    [
                      # Separate ankisyncd from it's deps (so that it sits in
                      # it's own layer).
                      ["subcomponent_in" [ankisyncd]]
                      [
                        # "rest" contains deps of ankisyncd, which we split
                        # according to reverse popularity, which results direct
                        # dependencies (more likely to change) to be put in
                        # their own layer.
                        "over"
                        "rest"
                        [
                          "pipe"
                          [
                            ["popularity_contest"]
                            ["reverse"]
                            ["limit_layers" 110]
                          ]
                        ]
                      ]
                    ]
                  ]
                ]
                # "rest" contains all packages which are not is not in the
                #  dependency graph of ankisyncd.
                [
                  "over"
                  "rest"
                  [
                    "pipe"
                    [
                      # Put with-env-from-dir and it's dependants
                      # (startup-script) in a septate layer.
                      ["subcomponent_in" [with-env-from-dir]]
                      # Same for cacert
                      ["over" "rest" ["subcomponent_in" [pkgs.cacert]]]
                    ]
                  ]
                ]
              ]
            ]
          ]
        ];
      }
  ;

in pkgs.dockerTools.streamLayeredImage (makeImageOptions pkgsLinux)
