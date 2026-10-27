# Pijulation provenance model (TLA+)

Status: **initial executable specification; not yet TLC-validated**.

This model formalizes the journal boundary first. It does not claim to prove that
real-world activity is exhaustively observed. It distinguishes:

- `occurred`: modeled activities in the environment;
- `accepted`: events accepted by the capture gate;
- `pending`: accepted events waiting for canonical persistence;
- `log`: ordered canonical journal;
- `bypassed`: activities that escaped the capture gate in a negative-test scenario;
- `gaps`: bypasses explicitly reported as capture gaps.

## Core contract

1. A controlled activity can be accepted only while the capture gate is up.
2. Acceptance atomically adds the full event payload to a durable pending spool.
   This is an abstraction: implementation must prove or test the corresponding
   local write-ahead-log behavior.
3. Canonical persistence appends an accepted event and removes it from pending.
4. Storage outage can delay persistence; it must not silently erase pending events.
5. The journal is append-only: every transition must preserve the previous log
   as a prefix.
6. The model contains no privacy/publicity classification and no content-based
   retention filter. Payloads are opaque values.
7. A bypass is not silently treated as captured. The negative-test action
   `BypassEvent` is intentionally excluded from `Next`; adding it to the
   transition relation should produce a counterexample to `NoUnreportedBypass`.

## Guarantees and boundaries

The intended liveness claim is that every accepted event is eventually persisted.
That claim requires the storage to recover and eventually remain available, plus
fair scheduling of persistence. The current `Spec` includes weak fairness for
persistence and recovery, but does **not** by itself assume that storage
eventually remains up. TLC may therefore find a liveness counterexample caused
by repeated outages. If so, that is an explicit missing assumption, not a reason
to weaken the property silently.

The model assumes the capture gate's acceptance step and durable-spool write are
atomic. This is a refinement obligation for the implementation. If the capture
process can acknowledge an event before its payload is durably spooled, a crash
can violate the contract.

Cryptographic tamper evidence, signatures, external witnesses, causal ordering,
multi-source event identity, Pijul change correlation and validation digests are
not yet modeled. They are the next refinement layer.

## Verification matrix

| ID | Property / scenario | Expected result | Current mechanism |
|---|---|---|---|
| M-01 | Type and state consistency | Pass | `TypeOK` invariant |
| M-02 | No duplicate event IDs in canonical log | Pass | `NoDuplicateLogIds` |
| M-03 | Persisted event retains an accepted payload | Pass | `AcceptedContentRetained` |
| M-04 | Pending events are not also pending after persistence | Pass | `NoSilentPendingLoss` |
| M-05 | Every transition preserves the previous log as a prefix | Pass | `AppendOnlyStep` action property |
| M-06 | Controlled capture while capture gate is down | No such transition | `CaptureEvent` precondition |
| M-07 | Unreported activity bypassing the gate | Counterexample if bypass is added to `Next` | `NoUnreportedBypass` |
| M-08 | Repeated storage outages can prevent progress | Counterexample possible without eventual-stability assumption | `EventuallyPersisted` |
| M-09 | Two different payloads reuse one event ID | Rejected by model identity contract; collision scenario still needs an explicit negative model |
| M-10 | Validation result references exact code digest | Not modeled yet | Next refinement |
| M-11 | Causal order across ACP/MCP/filesystem/Pijul | Not modeled yet | Next refinement |
| M-12 | Merkle consistency / externally detectable split views | Not modeled yet | Next refinement |

## Next refinement order

1. Make TLC syntax and bounded model checking pass locally.
2. Add explicit event identity/payload-collision negative tests.
3. Add a failure-injection model for capture/spool/canonical-store boundaries.
4. Add causal references and multi-source ordering.
5. Bind validation records to exact content digests and toolchain/configuration.
6. Add cryptographic journal commitments and consistency proofs.
7. Define a refinement map from implementation events to this abstract state.

No GitHub Actions were launched for this work.
