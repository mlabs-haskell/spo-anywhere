_lib:
with _lib; rec {
  # [{address : str, port : int}] -> topology file derivation
  # mimicks topology.json format
  # Topology where every peer has single access point. TODO: allow to overwrite
  mkBlockProducerTopology = relayAddrs:
    toFile "topology.json" (
      toJSON
      {
        localRoots =
          map (
            addr: {
              accessPoints = [addr];
              advertise = false;
              valency = 1;
            }
          )
          relayAddrs;
        publicRoots = [
          {
            accessPoints = [
            ];
            advertise = false;
          }
        ];
        useLedgerAfterSlot = -1;
      }
    );
}
