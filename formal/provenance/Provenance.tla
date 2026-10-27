-------------------- MODULE Provenance --------------------
EXTENDS Naturals, FiniteSets, Sequences

CONSTANTS Events, Payloads, NoPayload, MaxCrashes

ASSUME Events # {}
ASSUME Payloads # {}
ASSUME NoPayload \notin Payloads
ASSUME MaxCrashes \in Nat

VARIABLES occurred, accepted, payloadOf, pending, log, priorLog,
          captureUp, storageUp, crashesLeft, bypassed, gaps

vars ==
  <<occurred, accepted, payloadOf, pending, log, priorLog,
    captureUp, storageUp, crashesLeft, bypassed, gaps>>

LogSet(s) ==
  {s[i] : i \in 1..Len(s)}

IsUnique(s) ==
  \A i, j \in 1..Len(s) :
    i # j => s[i] # s[j]

IsPrefix(s, t) ==
  \land Len(s) <= Len(t)
  \land \A i \in 1..Len(s) : s[i] = t[i]

Init ==
  \land occurred = {}
  \land accepted = {}
  \land payloadOf = [e \in Events |-> NoPayload]
  \land pending = {}
  \land log = << >>
  \land priorLog = << >>
  \land captureUp = TRUE
  \land storageUp = TRUE
  \land crashesLeft = MaxCrashes
  \land bypassed = {}
  \land gaps = {}

\* Controlled work is permitted only while the capture gate is up.
\* Acceptance and durable-spool insertion are one abstract step.
CaptureEvent(e, p) ==
  \land e \in Events
  \land p \in Payloads
  \land e \notin occurred
  \land captureUp
  \land occurred' = occurred \cup {e}
  \land accepted' = accepted \cup {e}
  \land payloadOf' = [payloadOf EXCEPT ![e] = p]
  \land pending' = pending \cup {e}
  \land UNCHANGED <<log, priorLog, captureUp, storageUp, crashesLeft,
                    bypassed, gaps>>

Persist(e) ==
  \land e \in pending
  \land storageUp
  \land e \notin LogSet(log)
  \land priorLog' = log
  \land log' = Append(log, e)
  \land pending' = pending \ {e}
  \land UNCHANGED <<occurred, accepted, payloadOf,
                    captureUp, storageUp, crashesLeft,
                    bypassed, gaps>>

PersistAny ==
  \E e \in Events : Persist(e)

CrashStorage ==
  \land storageUp
  \land crashesLeft > 0
  \land storageUp' = FALSE
  \land crashesLeft' = crashesLeft - 1
  \land UNCHANGED <<occurred, accepted, payloadOf, pending, log, priorLog,
                    captureUp, bypassed, gaps>>

RecoverStorage ==
  \land ~storageUp
  \land storageUp' = TRUE
  \land UNCHANGED <<occurred, accepted, payloadOf, pending, log, priorLog,
                    captureUp, crashesLeft, bypassed, gaps>>

StopCapture ==
  \land captureUp
  \land captureUp' = FALSE
  \land UNCHANGED <<occurred, accepted, payloadOf, pending, log, priorLog,
                    storageUp, crashesLeft, bypassed, gaps>>

StartCapture ==
  \land ~captureUp
  \land captureUp' = TRUE
  \land UNCHANGED <<occurred, accepted, payloadOf, pending, log, priorLog,
                    storageUp, crashesLeft, bypassed, gaps>>

\* Negative-test action: an execution path outside the capture gate.
\* It is excluded from Next; adding it should violate NoUnreportedBypass.
BypassEvent(e, p) ==
  \land e \in Events
  \land p \in Payloads
  \land e \notin occurred
  \land occurred' = occurred \cup {e}
  \land payloadOf' = [payloadOf EXCEPT ![e] = p]
  \land bypassed' = bypassed \cup {e}
  \land UNCHANGED <<accepted, pending, log, priorLog, captureUp, storageUp,
                    crashesLeft, gaps>>

ReportGap(e) ==
  \land e \in bypassed
  \land e \notin gaps
  \land gaps' = gaps \cup {e}
  \land UNCHANGED <<occurred, accepted, payloadOf, pending, log, priorLog,
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
  \land occurred \subseteq Events
  \land accepted \subseteq occurred
  \land pending \subseteq accepted
  \land LogSet(log) \subseteq accepted
  \land priorLog \in Seq(Events)
  \land IsPrefix(priorLog, log)
  \land payloadOf \in [Events -> Payloads \cup {NoPayload}]
  \land \A e \in accepted : payloadOf[e] \in Payloads
  \land bypassed \subseteq occurred
  \land gaps \subseteq bypassed
  \land crashesLeft \in Nat
  \land captureUp \in BOOLEAN
  \land storageUp \in BOOLEAN

NoDuplicateLogIds ==
  IsUnique(log)

AcceptedContentRetained ==
  \A e \in LogSet(log) : payloadOf[e] \in Payloads

NoUnreportedBypass ==
  bypassed \subseteq gaps

AcceptedPartition ==
  \land accepted = pending \cup LogSet(log)
  \land pending \cap LogSet(log) = {}

Safety ==
  \land TypeOK
  \land NoDuplicateLogIds
  \land AcceptedContentRetained
  \land NoUnreportedBypass
  \land AcceptedPartition

EventuallyPersisted ==
  \A e \in Events : (e \in accepted) ~> (e \in LogSet(log))

Spec ==
  \land Init
  \land [][Next]_vars
  \land \A e \in Events : WF_vars(Persist(e))
  \land WF_vars(RecoverStorage)
============================================================
