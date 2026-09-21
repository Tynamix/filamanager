## Agent skills

### Development workflow

Every implementation change follows the TDD, review, and delivery workflow in `docs/agents/development-workflow.md`.

### Issue tracker

Issues are tracked as local Markdown files under `.scratch/`. See `docs/agents/issue-tracker.md`.

### Domain docs

This repository uses the single-context domain documentation layout. See `docs/agents/domain.md`.

## Documentation language

Write all repository documentation in English, including context glossaries, ADRs, specifications, issue files, research notes, and handoffs.

## Git conventions

- Name branches `<type>/<kebab-case-description>`, using a Conventional Commit type such as `feat`, `fix`, `docs`, `refactor`, `test`, `build`, `ci`, or `chore`.
- Write commit messages in Conventional Commits format: `<type>(optional-scope): <imperative description>`.
