{
  jnsgruk-go,
  jnsgruk-go-old,
  jnsgruk-rust,
  k6test,
  modulesPath,
  system,
  ...
}:
{
  imports = [ "${modulesPath}/virtualisation/qemu-vm.nix" ];
  system.stateVersion = "24.11";
  nixpkgs.hostPlatform = system;

  virtualisation = {
    forwardPorts = [
      {
        from = "host";
        host.port = 2222;
        guest.port = 22;
      }
    ];
    cores = 4;
    memorySize = 4096;
    diskSize = 10000;
  };

  networking.hostName = "benchvm";
  networking.firewall.enable = false;
  services.openssh.enable = true;
  services.openssh.settings.PermitRootLogin = "yes";
  users.extraUsers.root.password = "password";

  systemd.services.jnsgruk-go = {
    enable = true;
    serviceConfig = {
      ExecStart = "${jnsgruk-go}/bin/jnsgruk";
      Restart = "always";
    };
  };

  systemd.services.jnsgruk-go-old = {
    enable = true;
    serviceConfig = {
      ExecStart = "${jnsgruk-go-old}/bin/jnsgruk";
      Restart = "always";
    };
  };

  systemd.services.jnsgruk-rust = {
    enable = true;
    serviceConfig = {
      ExecStart = "${jnsgruk-rust}/bin/jnsgruk";
      Restart = "always";
    };
  };

  environment.systemPackages = [ k6test ];
}
