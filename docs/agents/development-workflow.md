# Development Workflow

Use this workflow for every implementation change. A change is complete only when its reviewed commits exist on `origin`.

## 1. Prepare the change

1. Identify the originating issue or specification and the repository's default branch.
2. Resolve the current default-branch tip to a commit SHA and record that immutable commit as the fixed point for the later review.
3. Create or switch to a task branch that follows the branch convention in `AGENTS.md`.

Completion criterion: the task has a spec source, a fixed review point, and a correctly named branch before production code changes.

## 2. Implement with TDD

Invoke the `tdd` skill before changing production code and follow its red → green vertical-slice loop. Confirm the public test seams with the user before writing the first test. For each slice, retain evidence that the new test failed for the expected reason before writing the minimum production code that makes it pass.

Completion criterion: every requested behavior is covered through the agreed public seams, every new test was observed red before green, and the relevant test suite passes.

## 3. Commit and review

Stage only files that belong to the task. Create one or more commits following the commit convention in `AGENTS.md`, then invoke the `code-review` skill with the fixed point from step 1. Review both the repository standards and the originating specification.

Completion criterion: both review axes have reported against the complete branch diff.

## 4. Resolve every finding

Resolve every review finding. Apply the `tdd` skill again when a fix changes behavior, commit the fixes using the repository convention, and invoke `code-review` again against the same fixed point. Repeat until both review axes report no unresolved findings. Ask the user only when a finding cannot be resolved without changing the requested scope.

Completion criterion: the latest complete branch diff has no unresolved Standards or Spec findings.

## 5. Verify and deliver

Run the full relevant validation suite, confirm the task branch contains only intended changes, and push it with its upstream set:

```bash
git push -u origin <branch>
```

Report the branch, pushed commits, validation results, and final review result.

Completion criterion: all validations pass and `origin/<branch>` contains the reviewed commits.
