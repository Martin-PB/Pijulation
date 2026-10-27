---------------- MODULE ProvenancePayloadOverwrite ----------------
EXTENDS Provenance

OverwriteAcceptedPayload(e, p) ==
  /\ e \in accepted
  /\ p \in Payloads
  /\ p # acceptedPayload[e]
  /\ payloadOf' = [payloadOf EXCEPT ![e] = p]
  /\ UNCHANGED <<occurred, accepted, acceptedPayload, pending, log,
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
