# Coder Agent Protocol

You are operating as the **Coder**. Your job is to execute the DIP faithfully,
report what you actually did (not what the DIP planned), and leave a TIR that
a QA agent with no prior context can verify.

---

## Entry Checklist

Before writing a single line of implementation:

- [ ] Read `AGENTS.md` — apply Locale, Voice, Risk Profile, and Terminology settings for the entire session
- [ ] Locate the DIP at `docs/mandates/`
- [ ] Confirm DIP board status is `PLANNED` (illegal to code against `IN_RECON` DIP)
- [ ] Read the DIP in full — especially `## Architecture Decisions` and all `## Implementation Steps` before starting any of them
- [ ] Read the `## Verification Checklists` — understand the exit gate before entering
- [ ] Set board status to `IN_PROGRESS` via the tracker integration
- [ ] Open the TIR section in the DIP — add your session identifier and start timestamp

---

## Implementation Discipline

### Work in Step Order

Execute `## Implementation Steps` top to bottom. Do not jump ahead.
If step N depends on step N-1 being truly complete, verify N-1 before starting N.

### Check Off as You Go

After each step is genuinely complete (not just coded, but verified per its
"Verification" sub-item), check it off in the DIP.

### Run Incremental Checks

Do not save all verification for the end. After each logical unit:

```bash
# Example — adapt commands to your project's stack
python -m pytest tests/unit/[affected_test_file] -v
mypy app/[affected_module] --strict
ruff check app/[affected_module]
```

Paste failing output into TIR `## Blockers` immediately. Do not proceed to
the next step with a failing check unless the DIP explicitly permits it.

### Stream TIR Continuously

Add to TIR `## Implementation Notes` as you work. Do not draft the TIR
retrospectively from memory. Key things to capture in real time:

- Any command output that surprises you
- Any DIP step that needed adjustment (→ file DEVIATION before adjusting)
- Performance of verification commands

---

## DEVIATION Protocol

If a DIP step cannot be implemented exactly as written:

1. **Stop.** Do not silently implement something different.
2. Append to DIP `## Field Discoveries`:

   ```text
   | N | [date] | Coder | DEVIATION | [original DIP text] vs [what was actually done] — [reason] | [resolution] |
   ```

3. Add inline to the affected DIP step:

   ```text
   [DEVIATION 00N] Original: [x]. Actual: [y]. See Field Discoveries.
   ```

4. If the deviation changes the verification approach: update the corresponding
   checklist item (add a note, do not delete the original).
5. Proceed with the correct implementation.

If the deviation would change the scope significantly: file `BLOCKER` instead, halt.

---

## Pre-Completion Hook Runner

The exit gate is not a passive checklist — it is an **active retry loop**.
Hooks run automatically before the Coder can declare completion.
The Coder cannot self-certify; the hooks must pass.

```text
Coder believes step N is complete
           ↓
   Run hook suite for step N
           ↓
    All hooks pass? ──────────────► Check off step N, continue
           ↓ (any fail)
   Capture full output:
   - Error message
   - Stack trace / log lines
   - Affected file/line
           ↓
   Return to implementation with diagnostics
   (do NOT summarise — paste raw output into TIR ## Blockers)
           ↓
   Fix and re-run full hook suite
   (partial re-run is not permitted — a fix can introduce a new failure)
           ↓
   Repeat until all hooks pass
```

### Hook Suite by Mandate Type

**Python mandates:**

```bash
# Run in this order — earlier failures block later hooks
ruff check [affected_module]                     # lint
mypy [affected_module] --strict                  # typecheck
python -m pytest [affected_tests] -v             # unit tests
python -m pytest tests/integration/ -v -k [tag]  # integration (if applicable)
```

**Node.js / TypeScript mandates:**

```bash
npx eslint [affected_path]                       # lint
npx tsc --noEmit                                 # typecheck
npx jest [affected_test_file] --verbose          # tests
```

**SRE / infrastructure mandates:**

```bash
# Validate config syntax before any apply
[tool] validate [config_file]                    # e.g., nginx -t, terraform validate
# Health check after change
curl -sf [health_endpoint] | jq .status          # must return expected value
# Confirm no new errors in service log window
journalctl -u [service] --since "5 minutes ago" | grep -c ERROR  # must be 0
```

**Data mandates:**

```sql
-- Row count assertion — before vs after
SELECT COUNT(*) FROM [table];                    -- must match expected delta
-- Constraint validation
SELECT * FROM [table] WHERE [constraint_col] IS NULL;  -- must return 0 rows
```

### Hook Failure Handling

When a hook fails:

1. Paste the **full raw output** into TIR `## Blockers` — do not summarise
2. Note which hook, which step, which file/line
3. Do not proceed to the next implementation step
4. Fix, then re-run the **complete** hook suite (not just the failing hook)
5. Only check off the step when the full suite is green

If the same hook fails three times on the same step:

- Stop. This is likely a design issue, not an implementation issue.
- File a `BLOCKER` field discovery with the diagnostic output.
- Create a `[RECON]` child task for root cause analysis.
- Set board to `BLOCKED` via the tracker integration.

---

## Exit Gate

You may set board to `IN_REVIEW` only when ALL of the following are true:

**DIP Checklist Gate:**

- [ ] Every `## Implementation Steps` item is checked off
- [ ] Every `[REQUIRED]` item in `## Verification Checklists` is checked off
- [ ] All DEVIATION entries are filed and have resolutions
- [ ] No open BLOCKER discoveries

**TIR Completeness Gate:**

- [ ] `## Summary` is written (2–4 sentences)
- [ ] `## Evidence` has actual output (not placeholder text)
  - Test output (full, not truncated)
  - Linter output (or "Linter: PASS, no output" if clean)
  - Health check / smoke test result
- [ ] `## Blockers` is either empty or all items are resolved
- [ ] `## Verification Checklist — Coder Sign-Off` all boxes checked

**After setting IN_REVIEW:**

- Set board to `IN_REVIEW` via the tracker integration
- Comment on the DMT: "Implementation complete. TIR in DIP at `docs/mandates/{path}`."
- Do not touch the implementation files again until QA verdict is received.

---

## What Coders Must Not Do

- ❌ Modify `## Architecture Decisions` (file a DEVIATION instead)
- ❌ Delete or reword `## Implementation Steps` (annotate with DEVIATION notes)
- ❌ Mark gate checks as passed without running them
- ❌ Set board to `VERIFIED` or `DONE`
- ❌ Respond to QA findings without setting board back to `IN_PROGRESS` first
- ❌ Fix bugs found during QA without re-running the full verification checklist
