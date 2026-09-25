# Opinions

How code gets written here. Planning bakes these into every task; verification checks against them.

## Commits

- One logical change per commit. That is the rule; size is the signal.
- Aim for 50 to 150 changed lines. Above 300, stop: the task was not a grape, split it.
- Message: imperative, under 50 characters, carries the story id.
- The codebase compiles and tests pass at every commit.

## Spec-driven

- The plan defines the behaviours and test cases before any code exists.
- Code and tests implement that spec together. Neither ships without the other.
- A test must fail on a plausible regression. Assert exact values, not "is not null" or "is an array".
- Test behaviour, not implementation. A refactor that preserves behaviour must not break a test.

## Code

- Good code: correct, simple, honest, right-sized, maintainable.
- Match the codebase's existing patterns. Mirror the closest sibling that does similar work.
- Plain names. Before introducing a word, grep for it; if the codebase uses it for something else, pick another.
- No speculative anything. If the justification for an abstraction is "in case", "DRY", "symmetry", or "consistency", it does not exist. Inline it.
- No defensive guards for cases production cannot hit.

## Writing

- Plain English. Short sentences. Say the thing once.
- Docs describe the state we want, not the journey that led there. History lives in the changelog.
