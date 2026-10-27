-------------------- MODULE Provenance --------------------
EXTENDS Naturals, FiniteSets, Sequences

CONSTANTS Events, Payloads, NoPayload, MaxCrashes

ASSUME Events # {}
ASSUME Payloads # {}
ASSUME NoPayload \notin Payloads
ASSUME MaxCrashes \in Nat

VARIABLES occurred, accepted, payloadOf, acceptedPayload, pending, log, priorLog,
          captureUp, storageUp, crashesLeft, bypassed, gaps

vars ==
  <<occurred, accepted, payloadOf, acceptedPayload, pending, log, priorLog,
    captureUp, storageUp, crashesLeft, bypassed, gaps>>

LogSet(s) ==
  {s[i] : i \in 1..Len(s)}

IsUnique(s) ==
  \A i, j \in 1..Len(s) :
    i # j => s[i] # s[j]

IsPrefix(s, t) ==
  /\ Len(s) <= Len(t)
  /\ \A i \in 1..Len(s) : s[i] = t[i]

Init ==
  /\ occurred = {}
  /\ accepted = {}
  /\ payloadOf = [e \in Events |-> NoPayload]
  /\ acceptedPayload = [e \in Events |-> NoPayload]
  /\ pending = {}
  /\ log = << >>
  /\ priorLog = << >>
  /\ captureUp = TRUE
  /\ storageUp = TRUE
  /\ crashesLeft = MaxCrashes
  /\ bypassed = {}
  /\ gaps = {}

\* Controlled work is permitted only while the capture gate is up.
\* Acceptance and durable-spool insertion are one abstract step.
CaptureEvent(e, p) ==
  /\ e \in Events
  /\ p \in Payloads
  /\ e \notin occurred
  /\ captureUp
  /\ occurred' = occurred \cup {e}
  /\ accepted' = accepted \cup {e}
  /\ payloadOf' = [payloadOf EXCEPT ![e] = p]
  /\ acceptedPayload' = [acceptedPayload EXCEPT ![e] = p]
  /\ pending' = pending \cup {e}
  /\ UNCHANGED <<log, priorLog, captureUp, storageUp, crashesLeft,
                    bypassed, gaps>>

Persist(e) ==
  /\ e \in pending
  /\ storageUp
  /\ e \notin LogSet(log)
  /\ priorLog' = log
  /\ log' = Append(log, e)
  /\ pending' = pending \ {e}
  /\ UNCHANGED <<occurred, accepted, payloadOf, acceptedPayload,
                    captureUp, storageUp, crashesLeft,
                    bypassed, gaps>>

PersistAny ==
  \E e \in Events : Persist(e)

CrashStorage ==
  /\ storageUp
  /\ crashesLeft > 0
  /\ storageUp' = FALSE
  /\ crashesLeft' = crashesLeft - 1
  /\ UNCHANGED <<occurred, accepted, payloadOf, acceptedPayload, pending, log, priorLog,
                    captureUp, bypassed, gaps>>

RecoverStorage ==
  /\ ~storageUp
  /\ storageUp' = TRUE
  /\ UNCHANGED <<occurred, accepted, payloadOf, acceptedPayload, pending, log, priorLog,
                    captureUp, crashesLeft, bypassed, gaps>>

StopCapture ==
  /\ captureUp
  /\ captureUp' = FALSE
  /\ UNCHANGED <<occurred, accepted, payloadOf, acceptedPayload, pending, log, priorLog,
                    storageUp, crashesLeft, bypassed, gaps>>

StartCapture ==
  /\ ~captureUp
  /\ captureUp' = TRUE
  /\ UNCHANGED <<occurred, accepted, payloadOf, acceptedPayload, pending, log, priorLog,
                    storageUp, crashesLeft, bypassed, gaps>>

\* Negative-test action: an execution path outside the capture gate.
\* It is excluded from Next; adding it should violate NoUnreportedBypass.
BypassEvent(e, p) ==
  /\ e \in Events
  /\ p \in Payloads
  /\ e \notin occurred
  /\ occurred' = occurred \cup {e}
  /\ payloadOf' = [payloadOf EXCEPT ![e] = p]
  /\ bypassed' = bypassed \cup {e}
  /\ UNCHANGED <<accepted, acceptedPayload, pending, log, priorLog, captureUp, storageUp,
                    crashesLeft, gaps>>

ReportGap(e) ==
  /\ e \in bypassed
  /\ e \notin gaps
  /\ gaps' = gaps \cup {e}
  /\ UNCHANGED <<occurred, accepted, payloadOf, acceptedPayload, pending, log, priorLog,
                    captureUp, storageUp, crashesLeft, bypassed>>

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
  /\ priorLog \in Seq(Events)
  /\ IsPrefix(priorLog, log)
  /\ payloadOf \in [Events -> Payloads \cup {NoPayload}]
  /\ acceptedPayload \in [Events -> Payloads \cup {NoPayload}]
  /\ \A e \in accepted : acceptedPayload[e] \in Payloads
  /\ bypassed \subseteq occurred
  /\ gaps \subseteq bypassed
  /\ crashesLeft \in Nat
  /\ captureUp \in BOOLEAN
  /\ storageUp \in BOOLEAN

NoDuplicateLogIds ==
  IsUnique(log)

AcceptedContentRetained ==
  \A e \in accepted :
    /\ acceptedPayload[e] = payloadOf[e]
    /\ acceptedPayload[e] \in Payloads

NoUnreportedBypass ==
  bypassed \subseteq gaps

AcceptedPartition ==
  /\ accepted = pending \cup LogSet(log)
  /\ pending \cap LogSet(log) = {}

Safety ==
  /\ TypeOK
  /\ NoDuplicateLogIds
  /\ AcceptedContentRetained
  /\ NoUnreportedBypass
  /\ AcceptedPartition

EventuallyPersisted ==
  \A e \in Events : (e \in accepted) ~> (e \in LogSet(log))

Spec ==
  /\ Init
  /\ [][Next]_vars
  /\ \A e \in Events : WF_vars(Persist(e))
  /\ WF_vars(RecoverStorage)
============================================================
