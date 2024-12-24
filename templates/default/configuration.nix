{lib, ...}: {
  networking.hostName = "spo-node-hetzner";

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
