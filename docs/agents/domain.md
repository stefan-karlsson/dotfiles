# Domain Docs

How the engineering skills should consume this repository's domain documentation when exploring the codebase.

## Before exploring, read these

- **`CONTEXT.md`** at the repository root, or
- **`CONTEXT-MAP.md`** at the repository root if it exists — it points at one `CONTEXT.md` per context. Read each one relevant to the topic.
- **`docs/adr/`** — read ADRs that touch the area you're about to work in.

If any of these files don't exist, proceed silently. The `/domain-modeling` skill, reached through `/grill-with-docs`, creates them lazily when terms or decisions actually become settled.

## File structure

This is a single-context repository. Use one root `CONTEXT.md` and `docs/adr/` for architecture decisions.

## Use the glossary's vocabulary

When naming a domain concept in an issue, refactor proposal, hypothesis, or test, use the term defined in `CONTEXT.md`. If the required concept is absent, reconsider the language or record it through `/domain-modeling`.

## Flag ADR conflicts

Surface contradictions with existing ADRs explicitly rather than silently overriding them.
