---------------- MODULE ProvenanceBypass ----------------
EXTENDS Provenance

BypassNext ==
  \lor Next
  \lor \E e \in Events, p \in Payloads : BypassEvent(e, p)

BypassSpec ==
  \land Init
  \land [][BypassNext]_vars
============================================================
