# Pijulation provenance model (TLA+)

Status: **initial specification; TLC execution still required before claiming verification**.

This model formalizes the journal boundary first. It does not claim to prove
that real-world activity is exhaustively observed. It distinguishes:

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
   The `acceptedPayload` map freezes the payload at acceptance, and the
   `AcceptedContentRetained` invariant checks that the accepted payload is unchanged.
4. Storage outages can delay persistence; accepted events remain in the pending
   set until persisted.
5. The journal is append-only: `priorLog` records the log immediately before
   the latest persistence transition; `TypeOK` checks that it is a prefix of
   the current log. The TLC invariant therefore checks a state predicate rather
   than relying on a temporal formula containing primed variables.
6. The model contains no privacy/publicity classification and no content-based
   retention filter. Payloads are opaque values.
7. A bypass is not silently treated as captured. `ProvenanceBypass.tla` adds
   the bypass action to the transition relation; its TLC configuration is
   expected to produce a counterexample to `NoUnreportedBypass`.

## Guarantees and boundaries

The liveness property states that every accepted event is eventually persisted.
The model bounds storage crashes with `MaxCrashes`, and gives weak fairness to
recovery and to persistence of each event. This makes outages finite in the
bounded model. It does not model permanent media loss, disk exhaustion, loss of
the durable spool, or an adversary able to rewrite storage.

The model assumes the capture gate's acceptance step and durable-spool write are
atomic. This is a refinement obligation for the implementation. If capture
acknowledges an event before its payload is durably spooled, a crash can violate
the contract.

The invariant `AcceptedPartition` states that every accepted event is either
pending or present in the canonical log, but never both. It is the central
no-logical-loss invariant. The `priorLog` state variable makes append-only
history checkable as a TLC state invariant; every action must frame it, while
`Persist(e)` updates it to the pre-append log.

Cryptographic tamper evidence, signatures, external witnesses, causal ordering,
multi-source event identity, Pijul change correlation and validation digests are
not yet modeled. They are the next refinement layer.

## Verification matrix

| ID | Property / scenario | Expected result | Current mechanism |
|---|---|---|---|
| M-01 | Type and state consistency | Pass | `TypeOK` invariant |
| M-02 | No duplicate event IDs in canonical log | Pass | `NoDuplicateLogIds` |
| M-03 | Persisted event retains its accepted payload | Pass | `AcceptedContentRetained` |
| M-04 | Every accepted event is pending or persisted, but not both | Pass | `AcceptedPartition` |
| M-05 | Last recorded prior log is a prefix of the current log | Pass expected | `TypeOK` invariant over `priorLog`; TLC execution pending |
| M-06 | Controlled capture while capture gate is down | No such transition | `CaptureEvent` precondition |
| M-07 | Unreported activity bypassing the gate | Expected counterexample; not yet run | `ProvenanceBypass.cfg`, `NoUnreportedBypass` |
| M-08 | Bounded storage outages followed by recovery | Liveness should pass in this finite model | `MaxCrashes`, fairness, `EventuallyPersisted` |
| M-09 | Two different payloads reuse one event ID | Not yet modeled as a separate negative case | Next refinement |
| M-10 | Validation result references exact code digest | Not modeled yet | Next refinement |
| M-11 | Causal order across ACP/MCP/filesystem/Pijul | Not modeled yet | Next refinement |
| M-12 | Merkle consistency / externally detectable split views | Not modeled yet | Next refinement |

## Next refinement order

1. Execute TLC locally and resolve all syntax, state-space and liveness findings.
2. Add explicit event identity/payload-collision negative tests.
3. Add failure injection at the capture/spool/canonical-store boundaries.
4. Add causal references and multi-source ordering.
5. Bind validation records to exact content digests and toolchain/configuration.
6. Add cryptographic journal commitments and consistency proofs.
7. Define a refinement map from implementation events to this abstract state.

No GitHub Actions were launched for this work.


## Negative test: accepted payload mutation

`ProvenancePayloadTamper.tla` deliberately adds a transition that changes the
payload of an already accepted event while leaving `acceptedPayload` unchanged.
The configuration `ProvenancePayloadTamper.cfg` should make TLC report a
counterexample to `AcceptedContentRetained`. This is an expected negative test,
not evidence that TLC has already been run.


A second negative test, `ProvenancePayloadOverwrite.tla` with
`ProvenancePayloadOverwrite.cfg`, mutates the frozen `acceptedPayload` record
while leaving `payloadOf` unchanged. TLC should also find a counterexample to
`AcceptedContentRetained`. Both negative models are intentional fault
injections; neither has been executed with TLC yet.
