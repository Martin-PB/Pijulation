-------------------- MODULE Provenance --------------------
EXTENDS Naturals, FiniteSets, Sequences

CONSTANTS Events, Payloads, NoPayload

ASSUME Events # {}
ASSUME Payloads # {}
ASSUME NoPayload \notin Payloads

VARIABLES occurred, accepted, payloadOf, pending, log,
          captureUp, storageUp, bypassed, gaps

vars ==
  <<occurred, accepted, payloadOf, pending, log,
    captureUp, storageUp, bypassed, gaps>>

LogSet(s) ==
  {s[i] : i \in 1..Len(s)}

IsUnique(s) ==
  \A i, j \in 1..Len(s) :
    i # j => s[i] # s[j]

IsPrefix(s, t) ==
  / Len(s) <= Len(t)
  /\ \A i \in 1..Len(s) : s[i] = t[i]

Init ==
  /\ occurred = {}
  /\ accepted = {}
  /\ payloadOf = [e \in Events |-> NoPayload]
  /\ pending = {}
  /\ log = << >>
  /\ captureUp = TRUE
  /\ storageUp = TRUE
  /\ bypassed = {}
  /\ gaps = {}

\* Controlled work is permitted only while the capture gate is up.
\* Capture acceptance and durable-spool insertion are one abstract step.
CaptureEvent(e, p) ==
  /\ e \in Events
  /\ p \in Payloads
  /\ e \notin occurred
  /\ captureUp
  /\ occurred' = occurred \cup {e}
  /\ accepted' = accepted \cup {e}
  /\ payloadOf' = [payloadOf EXCEPT ![e] = p]
  /\ pending' = pending \cup {e}
  /\ UNCHANGED <<log, captureUp, storageUp, bypassed, gaps>>

Persist(e) ==
  /\ e \in pending
  /\ storageUp
  /\ e \notin LogSet(log)
  /\ log' = Append(log, e)
  /\ pending' = pending \ {e}
  /\ UNCHANGED <<occurred, accepted, payloadOf,
                 captureUp, storageUp, bypassed, gaps>>

PersistAny ==
  \E e \in Events : Persist(e)

CrashStorage ==
  /\ storageUp
  /\ storageUp' = FALSE
  /\ UNCHANGED <<occurred, accepted, payloadOf, pending, log,
                 captureUp, bypassed, gaps>>

RecoverStorage ==
  /\ ~storageUp
  /\ storageUp' = TRUE
  /\ UNCHANGED <<occurred, accepted, payloadOf, pending, log,
                 captureUp, bypassed, gaps>>

StopCapture ==
  /\ captureUp
  /\ captureUp' = FALSE
  /\ UNCHANGED <<occurred, accepted, payloadOf, pending, log,
                 storageUp, bypassed, gaps>>

StartCapture ==
  /\ ~captureUp
  /\ captureUp' = TRUE
  /\ UNCHANGED <<occurred, accepted, payloadOf, pending, log,
                 storageUp, bypassed, gaps>>

\* Negative-test action: models an execution path outside the capture gate.
\* It is deliberately excluded from Next. Enabling it must invalidate
\* CoverageWithinControlledBoundary / NoUnreportedBypass.
BypassEvent(e, p) ==
  /\ e \in Events
  /\ p \in Payloads
  /\ e \notin occurred
  /\ occurred' = occurred \cup {e}
  /\ payloadOf' = [payloadOf EXCEPT ![e] = p]
  /\ bypassed' = bypassed \cup {e}
  /\ UNCHANGED <<accepted, pending, log, captureUp, storageUp, gaps>>

ReportGap(e) ==
  /\ e \in bypassed
  /\ e \notin gaps
  /\ gaps' = gaps \cup {e}
  /\ UNCHANGED <<occurred, accepted, payloadOf, pending, log,
                 captureUp, storageUp, bypassed>>

Next ==
  \/ \E e \in Events, p \in Payloads : CaptureEvent(e, p)
  \/ PersistAny
  \/ CrashStorage
  \/ RecoverStorage
  \/ StopCapture
  \/ StartCapture
  \/ \E e \in Events : ReportGap(e)

TypeOK ==
  /\ occurred \subseteq Events
  /\ accepted \subseteq occurred
  /\ pending \subseteq accepted
  /\ LogSet(log) \subseteq accepted
  /\ payloadOf \in [Events -> Payloads \cup {NoPayload}]
  /\ \A e \in accepted : payloadOf[e] \in Payloads
  /\ bypassed \subseteq occurred
  /\ gaps \subseteq bypassed
  /\ captureUp \in BOOLEAN
  /\ storageUp \in BOOLEAN

NoDuplicateLogIds ==
  IsUnique(log)

AcceptedContentRetained ==
  \A e \in LogSet(log) : payloadOf[e] \in Payloads

NoUnreportedBypass ==
  bypassed \subseteq gaps

NoSilentPendingLoss ==
  pending \cap LogSet(log) = {}

Safety ==
  /\ TypeOK
  /\ NoDuplicateLogIds
  /\ AcceptedContentRetained
  /\ NoUnreportedBypass
  /\ NoSilentPendingLoss

\* Action property: every transition preserves the old log as a prefix.
AppendOnlyStep ==
  IsPrefix(log, log')

\* Progress property under eventual storage recovery/stability and fairness.
EventuallyPersisted ==
  \A e \in Events : (e \in accepted) ~> (e \in LogSet(log))

Spec ==
  /\ Init
  /\ [][Next]_vars
  /\ []AppendOnlyStep
  /\ WF_vars(PersistAny)
  /\ WF_vars(RecoverStorage)
============================================================
