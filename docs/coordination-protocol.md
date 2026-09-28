# Sortie multi-device coordination protocol (v1)

All shared state lives in the mail account: a hidden IMAP folder `Sortie`
(fallback `INBOX<delim>Sortie`, created then UNSUBSCRIBEd) plus two constant
keywords on user mail (`$SortiePending`, `$SortieDone`). No server.

## Principles
1. The IMAP server is the only clock (INTERNALDATE) and the only arbiter (UID order).
   Device wall clocks are never compared. Every device keeps a `ServerClock`: after each
   own APPEND it fetches that message's INTERNALDATE and pairs it with its monotonic
   clock; `serverNow() = lastServerTime + (monotonic - lastMonotonic)`. An unprimed
   device cannot claim leadership; its first action on connect is a `presence` append.
2. The control folder is an append-only log totally ordered by UID; compaction replaces
   a prefix with a `snapshot`.
3. Exactly one writer of automatic moves (the leader), fenced by an epoch. User actions
   (undo, correction, manual move) execute on whichever device the user is on.
4. Minimal footprint on user mail: only the two keywords above. Keywords are never
   per-folder or per-device (servers cap distinct keywords: Dovecot 100, Cyrus 128).
5. Decisions are deterministic from folder contents: any two devices reading the same
   state reach the same leader and pending set.

## Control message envelope
RFC 5322 message, appended with `\Seen` and WITHOUT the date argument so the server
stamps INTERNALDATE. `Content-Type: application/json`. Headers:
```
From/To: Sortie <sortie@sortie.invalid>
Subject: [Sortie] <type> <device short id>
Message-ID: <per-type template>
X-Sortie-Version: 1
X-Sortie-Type: <type>
X-Sortie-Device: <deviceId>
X-Sortie-Seq: <per-writer monotonic int>
X-Sortie-Epoch: <int, when relevant>
X-Sortie-Priority: <int, lease-claim only>
X-Sortie-Snapshot-Upto: <UID, snapshot only>
```
Followers evaluate leadership from a header-only FETCH (UID INTERNALDATE FLAGS
BODY.PEEK[HEADER.FIELDS (...)]). Bodies are fetched only for journal/snapshot types.
`Message-ID` is the idempotency key: after an ambiguous APPEND failure, SEARCH for it
before re-appending.

| Type | Message-ID | Writer | Lifetime | Body |
|---|---|---|---|---|
| lease-claim | `<lease-{dev}-{epoch}@sortie.invalid>` | candidate | until superseded | `{deviceName, platform, priority, epoch}` |
| lease-beat | `<beat-{dev}-{epoch}-{n}@sortie.invalid>` | leader | newest kept (append new, then delete previous) | `{}` |
| lease-release | `<release-{dev}-{epoch}@...>` | leader on quit/yield | until successor confirmed | `{}` |
| presence | `<presence-{dev}-{n}@...>` | every device | newest kept | `{deviceName, platform, priority, open:[msgKey], recentlyClosed:[{key, at}]}` |
| decision | `<j-{dev}-{seq}@...>` | leader | until compaction | `{epoch, items:[SortDecision.toJson()]}` |
| moved | `<j-{dev}-{seq}@...>` | leader (auto) or any device | until compaction | `{epoch?, items:[{key, from, to, cause: auto|undo|correction|manual, decisionId}]}` |
| undo | `<j-{dev}-{seq}@...>` | any device | until compaction | `{key, decisionId, executed: bool}` |
| correction | `<j-{dev}-{seq}@...>` | any device | kept in snapshot | `Correction.toJson()` |
| resolved | `<j-{dev}-{seq}@...>` | leader | until compaction | `{key, why: external-move|deleted|keep|expired}` |
| config | `<j-{dev}-{seq}@...>` | any device | latest kept | `SortConfig.toJson()`; last by UID wins |
| identities | `<j-{dev}-{seq}@...>` | any device | latest kept | `{items:[Identity.toJson()]}` for the account; last by UID wins |
| rules | `<j-{dev}-{seq}@...>` | any device | latest kept | `{items:[SortRule.toJson()]}` (no `hits`); last by UID wins |
| calendars | `<j-{dev}-{seq}@...>` | any device | latest kept | `{items:[CalendarSource.toJson()]}` (no tokens/passwords); global, mirrored in every account's journal |
| prefs | `<j-{dev}-{seq}@...>` | any device | latest kept | `{ai: AiSettings.toJson(), device:{threaded, notify, remoteImages, theme}}`; last by UID wins |
| snapshot | `<snap-{dev}-{uid}@...>` | leader | until next snapshot | `{version, lastEpoch, config, identities?, rules?, calendars?, prefs?, pending[], corrections[], log[], inboxUidValidity}` |

Message key for user mail: `{mid: messageIdHash, uid, uv, subject?, from?}`. `mid` is
primary; `uid+uv` is the fast path. Before any move the leader fetches the UID and checks
the Message-ID hash matches; otherwise re-locates via `UID SEARCH HEADER Message-ID`.

## Leader election
Priority: desktop 30 > Android FG-service 20 > Android WorkManager 15 > iOS 10; settings
override 100 ("prefer this device") or "never sort here" (never claims).

Definitions, evaluated identically by every device from one header fetch:
- `epochMax = max(claim.epoch, snapshot.lastEpoch)`.
- `fresh(C)`: newest lease-beat (or the claim itself) for `(C.device, C.epoch)` has
  `INTERNALDATE >= serverNow - leaseTTL` and no lease-release exists for it.
- `legitimate(C)`: epoch 1 with no other claims; or the epoch C.epoch-1 lease was
  expired/released before C was appended (C.internalDate > lastBeat + TTL, or a release
  with INTERNALDATE < C.internalDate); or C.priority > holder(C.epoch-1).priority
  (preemption).
- `activeLease`: among legitimate fresh claims, highest epoch; ties within an epoch by
  earliest INTERNALDATE, then highest priority, then lexicographically smallest deviceId.
- Void claims (share an epoch with activeLease but lost, or illegitimate): the owner
  deletes its own on next evaluation; anyone may delete after 10 x TTL.

Timers (defaults): heartbeat 60 s, leaseTTL 180 s, claimConfirmWindow 10 s,
claimBackoff = `rand(0..3 s) + (100 - min(p,100)) * 0.1 s` capped 15 s, handoffWait 15 s,
presenceInterval 60 s (also immediately on hold-set change), presenceTTL 180 s,
pollFallback 5 min, reopenSettle 30 s, staleCleanup 24 h.

State machine: Connecting -> Syncing -> Follower | Candidate -> Leader -> Yielding.
- Syncing: select control folder, check UIDVALIDITY, load snapshot + journal delta,
  append presence (primes ServerClock), evaluate.
- Follower: IDLE on control folder; re-evaluate on each change; apply journal; publish
  presence; become Candidate when lease expires/released or when own priority > holder.
- Candidate: wait backoff; re-evaluate (abort if someone holds); APPEND claim with
  epoch = epochMax + 1; wait confirm window; re-fetch; if own claim == activeLease ->
  Leader else delete own claim -> Follower.
- Leader: wait handoffWait; open INBOX ops connection; loop; heartbeat; fence before
  every batch (<= 25 moves): NOOP + refetch + confirm `activeLease == (me, myEpoch)`,
  otherwise abort with zero MOVEs. Any control-connection error -> stop moves, Connecting.
- Yielding: finish current batch (<= 5 s), APPEND lease-release, delete own beats.
- A reconnecting old leader always goes Connecting -> Syncing and, if it leads again,
  claims a NEW epoch. Moves it believed executed but has no `moved` record for are
  re-verified against the mailbox.
- iOS: claims only if allowed in settings and foregrounded. In a BGAppRefresh window:
  one cycle (connect, sync, evaluate, claim if allowed, sort one batch, release).

## Sort journal and badges
Leader flow: INBOX IDLE reports new UIDs -> classify -> APPEND `decision` batch ->
`UID STORE +FLAGS ($SortiePending)`. Devices' control IDLE fires; they apply the decision
and show badges within ~1-2 s. When the read-guard clears: verify identity, STORE
`+FLAGS ($SortieDone) -FLAGS ($SortiePending)`, UID MOVE, APPEND `moved`.
- Undo from any device: locate by mid in dest, UID MOVE back to INBOX (`$SortieDone`
  stays -> never re-sorted), APPEND `undo{executed:true}` + `moved{cause: undo}`.
  Offline: `undo{executed:false}`; the leader executes.
- Correction ("should have gone to X"): device moves to X, appends `correction` +
  `moved{cause: correction}`.
- External client moved/deleted a pending message: leader's pre-move check fails ->
  `resolved{why: external-move|deleted}`. Found in a Sortie destination -> correction.
- A `$SortieDone` message reappearing in INBOX: never auto-sorted again; weak
  `correction{actual: INBOX}`.
- If PERMANENTFLAGS lacks `\*`, skip keywords; journal-only mode.

Materialized view (drift tables `journal_events`, `journal_cursors`, plus
`sort_decisions`/`corrections` mirrors): pending map (badges), log (Sort Log screen,
undo), corrections (few-shot), config, cursor `{uidValidity, snapshotUid, lastAppliedUid}`.

## Shared config
Identities and signatures, sort rules, the calendar list and preferences travel in the
four sections above; each is an independent last-writer-wins-by-UID section so devices
editing different sections never clobber each other. Secrets (passwords, API keys,
OAuth/refresh tokens, CalDAV passwords, sync tokens, ctags) are never written: bodies
are built from the entities' `toJson()` forms, which exclude them; a calendar received
without its credential stays "needs sign-in" until the user signs in on that device.
`accountId` inside items is the writer's local id and is replaced by the reader's.

Echo rule (`SharedConfigSync`, one per account): per section keep the content hash last
seen from the journal (applied) or published, persisted locally. Local edits are
debounced 2 s and published only when their canonical hash (keys sorted, items sorted by
id, `accountId` dropped) differs; applying a record stores its hash *before* the local
write so the watcher that fires afterwards stays quiet. Ties: later UID wins and the
loser adopts it via apply. First run: local content with no journal section is published
on connect; an empty/default local section never is, so a fresh device cannot clobber.
Calendars are global: the writer's watcher publishes to every account's journal, readers
apply from any, and the hash check bounds the fan-out. Snapshots carry a section only if
the journal has carried it (never "shared as empty"). Records or snapshots from an older
app version that lack a section, or a section without `items`, are ignored.

## Read-guard
A pending message moves only when ALL hold:
1. `leaveUntilRead` policy satisfied: `none`, or (`all`, or `personalOnly` and the
   message is not bulk) requires `\Seen` and `serverNow - seenObservedAt >= grace`
   (default 7 min). `seenObservedAt` is when the leader first observed `\Seen`; a new
   leader initialises it to its takeover time for already-seen messages.
2. Not in the `open` set of any presence with INTERNALDATE >= serverNow - presenceTTL.
3. Not opened anywhere in the last reopenSettle (30 s).
4. Pre-move identity verification passes.
Fast path: closing a `\Seen` message publishes `recentlyClosed`; the leader moves after
reopenSettle instead of full grace. On the leader's own UI the move happens immediately
on close. Readers subscribe to `moved` events and follow the message (toast + Undo).

Why presence-carried holds rather than a `$SortieHold` keyword: a keyword has no owner
or timestamp so a crashed reader would block forever, and per-device keywords hit the
server cap. Presence expires automatically.

## Compaction
Leader only, after fencing. Trigger: > 300 journal messages or oldest > 14 days, checked
hourly. Steps: (1) U = highest applied journal UID; build snapshot; (2) APPEND snapshot
with `X-Sortie-Snapshot-Upto: U`, confirm; (3) `\Deleted` + `UID EXPUNGE` journal UIDs
<= U and older snapshots (lease/presence untouched). Snapshot > ~2 MB: drop oldest log,
then oldest corrections. Follower sync: if UIDVALIDITY changed reset; load newest
snapshot if its UID > cursor.snapshotUid; apply journal UIDs > lastApplied in order.

## Bootstrap / edge cases
- Namespace: try `Sortie` at root; on NO, `INBOX<delim>Sortie`. Unsubscribe after create.
- Control folder deleted by user: SELECT fails or UIDVALIDITY changes -> recreate, reset
  cursor, presence, election; new leader re-seeds a snapshot from its local view;
  `$SortiePending` on messages is the second recovery source.
- Dovecot `mail_max_userip_connections` default 10: leader uses 3 connections + UI's 2.
