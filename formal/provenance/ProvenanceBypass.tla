---------------- MODULE ProvenanceBypass ----------------
EXTENDS Provenance

BypassNext ==
  \/ Next
  \/ \E e \in Events, p \in Payloads : BypassEvent(e, p)

BypassSpec ==
  /\ Init
  /\ [][BypassNext]_vars
============================================================
