# Automated pull request review

## Source

The user requested a code review workflow like `quiztrip-web` and supplied its
OpenCode GitHub Actions workflow as a reference.

## Acceptance criteria

- Review same-repository pull requests when opened, updated, reopened, or
  marked ready for review; skip Renovate PRs.
- Run the OpenCode GitHub Action using the supplied OpenRouter model and an
  `OPENROUTER_API_KEY` repository secret.
- Give the reviewer the complete Git history needed to compare the PR with its
  base branch and permission to publish review feedback, without repository
  write access or OIDC.
- Assess risk and delegate focused review dimensions to subagents according to
  the supplied low, medium, and high risk scheme.
- Publish a concise final summary with a verdict, concrete findings, file
  locations, and suggested fixes. Avoid changing the PR code.
- Document the repository setup needed to activate the workflow.
