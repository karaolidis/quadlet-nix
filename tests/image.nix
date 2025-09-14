{
  testConfig = { pkgs, config, ... }: {
    virtualisation.quadlet = let
      inherit (config.virtualisation.quadlet) images;
    in {
      autoEscape = true;

      images.hello = {
        imageConfig = {
          image = "docker-archive:${pkgs.dockerTools.examples.bash}";
          tag =
            let
              name = pkgs.dockerTools.examples.bash.passthru.buildArgs.name;
              tag = pkgs.dockerTools.examples.bash.passthru.imageTag;
            in
            "localhost/${name}:${tag}";
        };
      };

      containers.hello = {
        containerConfig = {
          image = images.hello.ref;
          volumes = [ "/tmp:/output" ];
          entrypoint = "bash";
          exec = [
            "-c"
            "echo \"Success\" > /output/result.txt"
          ];
        };
        serviceConfig = {
          RemainAfterExit = true;
        };
      };
    };
  };

  testScript = ''
    machine.wait_for_unit("default.target")
    machine.wait_for_unit("default.target", user=user)
    machine.wait_for_unit("hello.service", user=user, timeout=30)

    assert machine.succeed("cat /tmp/result.txt").strip() == 'Success'
  '';
}
