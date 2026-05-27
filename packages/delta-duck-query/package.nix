{ pkgs, uvloom, ... }:
let
  project = uvloom.lib.project.load { root = ./.; };
  scope = project.forPython {
    inherit pkgs;
    interpreter = pkgs.python3;
  };
in
scope.app { package = "delta-duck-query"; }
