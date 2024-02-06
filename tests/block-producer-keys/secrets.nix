let 
	testnode = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICG2nyqIBCAQxnvam9ObXlmSCsFIGY0Fji4tVsu+ndhY";
in {
	"kes.skey.age".publicKeys = [ testnode ];
	"vrf.skey.age".publicKeys = [ testnode ];
	"opcert.cert.age".publicKeys = [ testnode ];
}
