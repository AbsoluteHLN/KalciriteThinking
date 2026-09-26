# Verification and debugging — how a claim gets proven

The rules text (§8) gates *reporting* on evidence. This page gates the *method*:
an experiment that cannot reach the real mechanism proves nothing about it. The
recurring failure shape is the same everywhere — the fix looks right in the
source, the artifact compiles, and the user-facing behaviour is still broken,
because the check ran against a stand-in instead of the thing.

## 1. Synthetic ≠ real — verify through the real input path

A simulated event, a mocked caller, or a hand-invoked function exercises your
code, not the user's path. Where the distinction matters, drive the real thing:

- **Input events**: a script-constructed event object does not perform native
  default actions (a synthetic `WheelEvent` scrolls nothing). Real input goes
  through the host's automation protocol (CDP `Input.dispatchMouseEvent`, a
  UI driver, a real keystroke). A regression report like "the wheel is dead"
  can only be closed by a real wheel reaching the real page.
- **Served artifacts vs source files**: after changing code that a bundler or
  dev server compiles, read the *served* output (fetch the compiled CSS/JS the
  page actually loads) before believing the fix is live. Stale caches and
  restart requirements (config files read at startup) sit between the two.
- **Hidden chrome**: measuring with scrollbars hidden, animations disabled, or
  dev overlays removed hides exactly the things users see. Take the measurement
  with the page as the user sees it.
- If only synthetic checks are available, say so in the evidence: "verified
  programmatically, real-input path untested" is a different claim from
  "verified".

## 2. Enumerate before you edit — archaeology for layered overrides

Long-lived projects accumulate override layers (media queries, `!important`
passes, upstream design-system rules, framework defaults). Before changing a
rule, enumerate **every** declaration that can reach the selector:

1. grep the project sources **and** the compiled output **and** the upstream
   bundle for the selector and its ancestors;
2. for each hit, resolve the cascade triplet: specificity, source order,
   importance — the winner explains the behaviour, not the rule you are
   editing;
3. prefer reading the computed values in a live page (element inspection,
   `getComputedStyle` up the ancestor chain) when the combination is too
   tangled to resolve on paper.

Fix by **converging**: delete or rewrite down to one correct rule rather than
adding another override on top. A fix that leaves three older layers in place
re-arms them for the next change.

## 3. Regression attribution — assume your own last change first

When something "worked before and broke after", the first suspect is the most
recent edit, including its side effects. Structural changes have consequence
chains: removing an inner scroll owner exposes an ancestor's clamp; an
`overscroll-behavior: contain` that was harmless while an inner container
scrolled becomes a wheel-eater once it can no longer scroll. Diff the last
change, walk the chain, and check the *neighbours* of the rules you touched
(same selector, sibling breakpoints, other pages) for collateral.

## 4. Falsify before fixing — is it a defect at all?

An observed anomaly is one of: a defect, a deliberate design, or a transient.
Triage before fixing, and record the exclusions in the evidence file:

- consistent with the theme tokens (status colours, accents) → intended;
- a documented reading width, card span, or layout rhythm → intended, cite the
  rule that defines it;
- an animation frozen mid-frame by virtual-time screenshots / disabled motion →
  transient, re-check without the freeze.

Exclusions need the same evidence as fixes: a rule citation, a live capture, a
note in the evidence file — not an impression.

## 5. Known mechanics that silently change behaviour

Small, easy to forget; each one produced a real wrong conclusion somewhere:

- `overflow-x: hidden` on a box forces `overflow-y: visible` to compute to
  `auto` — the box becomes a scroll container. `overflow-x: clip` clips
  horizontally **without** creating one. "Clip horizontal, never scroll
  vertical" wants `clip`, not `hidden`.
- `overscroll-behavior: contain/none` on a scroll container that cannot scroll
  swallows wheel input instead of chaining to the viewport.
- `scroll-behavior: smooth` makes `scrollTo` asynchronous — read `scrollY`
  after a wait, and never conclude "cannot scroll" from an immediate read.
- A rounded-up specificity win (`.a .b` over `.a p`) is cheaper and safer than
  an `!important` arms race.
- Dev-only chrome (framework dev tools badges, overlays) is not site code;
  configure it off rather than styling around it.

## 6. Evidence file shape

One file per work pass in `<EVIDENCE>`, named by date and topic:

- **Flow** — what was done, in order, with the tools used.
- **Root cause** — with file/line references for each factor in the chain.
- **Fix** — what changed, in which layer (project CSS / component logic /
  config), and what was deliberately *not* touched.
- **Verification** — the method and the numbers (before/after measurements,
  probe outputs, screenshot pairs), including how real input was exercised.
- **Exclusions** — triaged non-defects with their citations.
- **Artifacts** — screenshot paths, logs, the served artifact that was checked.

Ship the fix and the evidence in the same commit; a claim without its evidence
file is the §9 red line.
