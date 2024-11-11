# Loads env variables from files in given dirs (on file per env var),
# using file name as env var name and it's content as the value.
{
  pkgs ? import ./../nixpkgs.nix {}
}:
let
  basename = "${pkgs.coreutils}/bin/basename";
  cat = "${pkgs.coreutils}/bin/cat";
  env = "${pkgs.coreutils}/bin/env";
  grep = "${pkgs.gnugrep}/bin/grep";
in
pkgs.writeShellApplication {
  name = "with-env-from-dir";
  text = ''
    set -ueo pipefail

    env_dir=$1
    shift

    for env_var_file_path in "$env_dir"/*; do
      env_var_name=$(${basename} "$env_var_file_path")

      # Only export if variable is not already defined.
      if ! ${env} | ${grep} -q "^''${env_var_name}="
      then
        env_var_value=$(${cat} "$env_var_file_path")
        export "$env_var_name"="$env_var_value"
      fi
    done

    exec "''${@}"
  '';
}
