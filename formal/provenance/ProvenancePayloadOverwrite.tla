---------------- MODULE ProvenancePayloadOverwrite ----------------
EXTENDS Provenance

OverwriteAcceptedPayload(e, p) ==
  /\ e \in accepted
  /\ p \in Payloads
  /\ p # payloadOf[e]
  /\ acceptedPayload' = [acceptedPayload EXCEPT ![e] = p]
  /\ UNCHANGED <<occurred, accepted, payloadOf, pending, log,
                  priorLog, captureUp, storageUp, crashesLeft,
                  bypassed, gaps>>

OverwriteNext ==
  \/ Next
  \/ \E e \in accepted, p \in Payloads :
       OverwriteAcceptedPayload(e, p)

OverwriteSpec ==
  /\ Init
  /\ [][OverwriteNext]_vars
============================================================
