{lib, ...}: {
  networking.hostName = "spo-node-hetzner";

  system.stateVersion = "24.11";

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCzCmDCtlGscpesHuoiruVWD2IjYEFtaIl9Y2JZGiOAyf3V17KPx0MikcknfmxSHi399SxppiaXQHxo/1wjGxXkXNTTv6h1fBuqwhJE6C8+ZSV+gal81vEnXX+/9w2FQqtVgnG2/mO7oJ0e3FY+6kFpOsGEhYexoGt/UxIpAZoqIN+CWNhJIASUkneaZWtgwiL8Afb59kJQ2E7WbBu+PjYZ/s5lhPobhlkz6s8rkhItvYdiSHT0DPDKvp1oEbxsxd4E4cjJFbahyS8b089NJd9gF5gs0b74H/2lUUymnl63cV37Mp4iXB4rtE69MbjqsGEBKTPumLualmc8pOGBHqWIdhAqGdZQeBajcb6VK0E3hcU0wBB+GJgm7KUzlAHGdC3azY0KlHMrLaZN0pBrgCVR6zBNWtZz2B2qMBZ8Cw+K4vut8GuspdXZscID10U578GxQvJAB9CdxNUtrzSmKX2UtZPB1udWjjIAlejzba4MG73uXgQEdv0NcuHNwaLuCWxTUT5QQF18IwlJ23Mg8aPK8ojUW5A+kGHAu9wtgZVcX1nS5cmYKSgLzcP1LA1l9fTJ1vqBSuy38GTdUzfzz7AbnkRfGPj2ALDgyx17Rc5ommjc1k0gFoeIqiLaxEs5FzDcRyo7YvZXPsGeIqNCYwQWw3+U+yUEJby8bxGb2d/6YQ=="
  ];

  spo-anywhere = {
    node = {
      enable = true;
      block-producer-key-path = "/var/lib/spo";
    };
    install-script = {
      enable = true;
      target = "root@188.245.227.87";
    };
  };
  
  services.cardano-node = {
    environment = "preview";
    hostAddr = "127.0.0.1";
    # kesKey = lib.mkForce ./tmp/kes.skey;
    # vrfKey = lib.mkForce ./tmp/vrf.skey;
    # operationalCertificate = lib.mkForce ./tmp/opcert.cert;
    topology = builtins.toFile "topology.json" ''
      {
	"localRoots": [
	  {
	    "accessPoints": [
	      {
		"address": "preview-node.world.dev.cardano.org",
		"port": 3001
	      }
	    ],
	    "advertise": false,
	    "valency": 1
	  }
	],
	"publicRoots":[],
	"useLedgerAfterSlot": 322000
      }
    '';
  };


  # cardano-node run --topology \${TOPOLOGY} --shelley-kes-key \${KES} --shelley-vrf-key \${VRF} --shelley-operational-certificate \${CERT}
}
