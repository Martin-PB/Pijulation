---------------- MODULE ProvenancePayloadTamper ----------------
EXTENDS Provenance

TamperAcceptedPayload(e, p) ==
  /\ e \in accepted
  /\ p \in Payloads
  /\ p # acceptedPayload[e]
  /\ payloadOf' = [payloadOf EXCEPT ![e] = p]
  /\ UNCHANGED <<occurred, accepted, acceptedPayload, pending, log,
                  priorLog, captureUp, storageUp, crashesLeft,
                  bypassed, gaps>>

TamperNext ==
  \/ Next
  \/ \E e \in accepted, p \in Payloads :
       TamperAcceptedPayload(e, p)

TamperSpec ==
  /\ Init
  /\ [][TamperNext]_vars
============================================================
