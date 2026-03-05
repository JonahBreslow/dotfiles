---
name: reverse-interview
description: Clarifies vague or high-level prompts by asking targeted questions about goals, scope, constraints, and edge cases. Use when the user describes a feature, enhancement, or product idea without detail, says they have a "high-level" or "10,000 foot" view, or when their request is ambiguous and key decisions are unspecified.
---

# Reverse Interview

When the user gives a high-level or vague request (feature, enhancement, product idea), **pause before building**. Run a short "reverse interview" to surface assumptions, constraints, and details they haven't specified. Goal: enough clarity to avoid wrong direction or rework, not to interrogate.

## When to Use

- User describes a feature/enhancement/product in broad terms only
- User says they have a "10,000 foot view," "rough idea," or "haven't thought through the details"
- Request is ambiguous (missing who, what success looks like, scope, or constraints)
- Multiple reasonable interpretations exist and the right one isn't clear

## Question Categories

Ask a small set of questions (3–6), chosen for the request. Don't ask everything; prioritize what would most change the approach.

**Goals & success**
- What does "done" or "success" look like? How would we know it's working?
- Who is this for (user type, role, workflow)?
- What problem does this solve that isn't solved today?

**Scope & boundaries**
- What's in scope for this iteration vs. "later"?
- What is explicitly out of scope?
- Are we replacing something existing or adding net-new?

**Constraints & context**
- Any hard constraints (performance, compliance, deadlines, dependencies)?
- Existing patterns, APIs, or systems this must fit into?
- Any non-goals or "nice to have" we should deprioritize?

**Edge cases & behavior**
- What are the main edge cases or failure modes to handle?
- How should it behave when data is missing, stale, or invalid?
- Any error or empty states the user will see?

**Format & output**
- Any specific format, UI, or output shape required?
- Any examples or references (docs, screens, tickets) to align to?

## How to Run the Interview

1. **Acknowledge** the idea briefly so the user feels heard.
2. **Reframe** in one sentence what you understood (goals, scope, or outcome).
3. **Ask** 3–6 questions, grouped by theme. Prefer open-ended; use bullet lists only if it keeps the message short.
4. **Offer** to turn their answers into a short spec or checklist before implementation.

Keep tone collaborative and curious. Phrase questions as "To make sure I build the right thing…" or "To scope this well…" rather than "You didn't specify…"

## When to Stop Interviewing

- User has answered enough that you can propose a concrete approach or next step.
- User asks to "just start" or "use your judgment" — then state your assumptions in one short paragraph and proceed.
- User pushes back on more questions — respect that and proceed with stated assumptions.

## Example Flow

**User:** "I want to add a way for instructors to block out times when they're not available."

**Agent (reverse interview):**
- Briefly acknowledge: e.g. instructor unavailability / blocking.
- Reframe: "So we're adding a way for instructors to mark times they're not available, and the system should treat those as non-bookable."
- Ask a few from the categories above, e.g.:
  - What does "block out" mean in the UI — calendar slots, date ranges, recurring rules?
  - Should existing bookings in that range be allowed, or should blocking prevent new bookings only?
  - Any need to sync with external calendars or keep this in-app only?
  - Is this for this quarter or a first cut we can iterate on?
- Offer: "Once you answer these, I can outline the data model and API changes, or we can go straight to implementation with my assumptions written down."
