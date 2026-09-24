# Cost-tiered routing and session handoff

Read this when: delegating work, choosing a model, handing off to another session,
or deciding whether route selection exists at all.

## Principle

Spend the expensive model on judgement, not on reading. Route work by **required
reasoning depth**, not by task size or by novelty.

| Work | Tier |
|---|---|
| Design, architecture, trade-offs, security, final adjudication | Strong / parent route |
| Bulk file reading, mechanical refactors, log triage, structured extraction, doc drafting, per-file audits | Cheapest capable route |

A cheap model asked to make a design decision is a cost saving that becomes a
defect. A strong model used to grep forty files is the same mistake inverted.

## Routing procedure

1. **Discover, never guess.** Call the catalog/discovery tool for subagent models
   (in DSH: `list_subagent_models`; elsewhere: the equivalent route-listing tool or
   config file) before naming a model.
2. **Preferred cheap family** — the boundary file lists this machine's preferred
   provider and its exact model ids. Names shown in a UI are often *display names*;
   the routing field usually needs the **configured id**. Read the config, do not
   transcribe the label.
3. **Fuzzy-match when the exact name is absent** — match on family keywords (e.g.
   `GLM`, `DeepSeek`, `Qwen`, `Flash`, `mini`, `small`) case-insensitively and pick
   the nearest cheap sibling. Say which sibling you picked and why.
4. **Never leave the authorised provider.** The boundary file names it (e.g. a
   campus/self-hosted gateway). Cross-provider guessing is a failure, not initiative.
5. **Record the substitution** — if you used a different model than intended, say so
   in the report.
6. **Do not burn budget finding a name** — no settings edits, no probing loops, no
   network exploration to resolve a model id.

## Preconditions are real (check, do not assume)

Whether you can choose a model at all, where the switch lives, and when it takes
effect are **host facts, not rule facts** — they belong in the boundary file. Treat
"the session exposes `provider` / `model`" as a hypothesis to verify, not a default.

- **Verify before delegating with a route.** If the delegation tool does not offer
  the field, the capability does not exist for this session.
- **If the fields are not available: do not fabricate them.** Delegate on the
  inherited route, or do the work inline, and state that model selection was
  unavailable.
- **Enablement usually applies at session creation.** Many hosts read the routing
  policy once and inherit it into children, so editing settings mid-session changes
  nothing for the running session. Open a new session instead of pretending.
- **Worked example (DSH).** `subagent` / `subagent_fork` expose `provider` / `model` /
  `reasoning_effort` plus `list_subagent_models` only when the session was composed
  with `subagent-model-selection: {enabled: true, allowedModels: [...]}`; that policy
  is recorded at session creation and inherited by children, and restored sessions
  keep the policy they recorded. `subagent_fork` deliberately stays on the parent
  route (KV-cache reuse) even when the fields are available.

## Session handoff protocol

A child agent does not see the parent conversation. Every delegation must be
self-contained:

| Section | Content |
|---|---|
| Context | Why this exists; what is already true; relevant file paths |
| Task | One concrete, bounded deliverable |
| Boundary | Exactly what may be read and written; what must not be touched |
| Deliverable | Expected artifact and its absolute target path |
| Acceptance | How the result will be judged |
| Forbidden | Known traps: network installs, deleting caches, touching user data |

Rules:

- **Absolute paths only.** Materialise attachments to disk first, then hand over the
  path — never a description of where something "should" be.
- **Name the route** (`provider` + `model`) and the read/write scope in the prompt.
- **Return format**: execution summary, changed-file list, evidence paths, open
  questions, what the child could not verify.
- **Human handoff** (new session or another person): current state, files changed,
  evidence paths, next step. Not a narrative of the process.
- Run independent delegations in parallel; wait in the foreground only when the next
  action depends on the result.

## Delegation and model selection are host-specific

**Sub-agent creation and route selection are not universal.** The tools differ
between hosts, and whether a delegation may name its own model is a property of
*that* host, not of this rule text. So these are interview subjects and boundary
values, exactly like cache paths:

| Boundary key | Ask | Why it changes behaviour |
|---|---|---|
| `HOST_AGENT` | Which agent / harness is this, and which version? | decides which equivalent wording applies |
| `DELEGATION_TOOLS` | Which delegation tools exist, and how do they differ? | a fresh-context child and a fork of the parent conversation receive and return different things |
| `ROUTE_SELECTION_SUPPORTED` | Can a delegation name its own provider / model? | if not, either do the work inline or accept the inherited route — do not pretend |
| `ROUTE_TOOL` | How are the available routes discovered? | discover, never guess |
| `ROUTE_ENABLE_SETTING` | Which setting enables route selection? | tells the user the exact place to change |
| `ROUTE_TAKES_EFFECT` | When does that change take effect — new session, restart, immediately? | decides whether to open a new session or just retry |
| `CONCURRENCY_LIMIT` | Any concurrency or budget ceiling? | parallel fan-out must respect it |

**Absence of a record means "not supported."** Fall back to the inherited route, say
so in the report, and never invent `provider` / `model` fields.

Recording the answers, per host shape:

| Situation | What to record |
|---|---|
| an equivalent route setting exists | its location in `ROUTE_ENABLE_SETTING`, its timing in `ROUTE_TAKES_EFFECT` (`new session` / `immediate` / `restart`) |
| delegation exists but cannot choose a model | `ROUTE_SELECTION_SUPPORTED = none`; the rules degrade to "work inline, or accept the inherited route" |
| there is no delegation at all | `DELEGATION_TOOLS = none`; §2's cost tiers decide only whether to open a new session |
| a concurrency or budget ceiling exists | `CONCURRENCY_LIMIT`; read it before fanning out |

Write them to **two** places: the machine-config document's model-routing section (the full
key set), and the loaded `SKILL.md`'s `kalcirite:local-profile` block (at least
`ROUTE_PROVIDER`, `CHEAP_MODELS`, `ROUTE_TOOL`, `ROUTE_SELECTION_SUPPORTED`). The
[`interview.md`](interview.md) question 6 walks through them.

## A delegation prompt that survives

```
Context   <why this exists, what is already true, absolute paths>
Task      <one bounded deliverable>
Boundary  read: <paths>   write: <paths>   never touch: <paths>
Deliver   <artifact> at <absolute target path>
Accept    <how the result is judged>
Forbidden network installs; deleting anything under the dependency cache; user data
Route     provider <id> model <id>   (omit entirely if this session forbids it)
```

If you cannot fill every line, the task is not ready to delegate.
