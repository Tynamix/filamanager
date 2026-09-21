# Domain Docs

This is a single-context repository. These rules describe how engineering skills should consume its domain documentation while exploring the codebase.

## Before exploring, read these

- **`CONTEXT.md`** at the repository root
- Relevant ADRs under **`docs/adr/`**

If these files don't exist, **proceed silently**. Don't flag their absence or suggest creating them upfront. The `/domain-modeling` skill—reached through `/grill-with-docs` and `/improve-codebase-architecture`—creates them lazily when terms or decisions are resolved.

## File structure

```text
/
├── CONTEXT.md
├── docs/adr/
│   ├── 0001-event-sourced-orders.md
│   └── 0002-postgres-for-write-model.md
└── src/
```

## Use the glossary's vocabulary

When output names a domain concept—for example, in an issue title, refactoring proposal, hypothesis, or test name—use the term defined in `CONTEXT.md`. Don't drift to synonyms the glossary explicitly avoids.

If the needed concept isn't in the glossary, reconsider whether the terminology belongs to the project or note the gap for `/domain-modeling`.

## Flag ADR conflicts

If output contradicts an existing ADR, surface the conflict explicitly instead of silently overriding it:

> _Contradicts ADR-0007 (event-sourced orders), but worth reopening because…_
