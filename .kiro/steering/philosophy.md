# Philosophy

When the rules don't cover a situation, fall back to this.

## The goal is good code, not good process

What ships is judged, not the ceremony that produced it. Good code is correct, simple, honest, right-sized, and maintainable. Every practice in this system exists to produce that; when a practice stops serving the change in front of you, the quality of the change wins. There are two failures: shipping bad code, and shipping process-compliant mediocrity. The second one hides better.

## Simplicity is minimum cognitive load

The measure of simple: how much a reader must hold in their head to understand what the code does and that it is correct. Every line, name, and layer of indirection charges that reader. Anything that doesn't pay for itself in clarity or capability is a cost with no benefit. This is the lens; every other rule is what falls out when you point it at a recurring situation.

## Principles are residue, not commands

The rules in this system were not invented; they are what remains after asking the right question many times. When a rule and the lens disagree, the lens wins, because the rule was only ever a cached answer.

## Ask five whys before adding anything

Before adding a helper, a wrapper, a config knob, a layer: ask "why does this exist?" five times. If the answer at depth three is "in case we need it later", "to avoid repeating", "for symmetry", or "the pattern looks similar", the thing does not exist. This is mechanical; run it, don't trust taste.

## Design on truth

Discovering a missing concept mid-implementation means the plan was built on assumption instead of evidence. Ground the plan in what the code actually says: read it, cite it, test claims against it. Questions the evidence cannot answer go to a human, once, with the evidence attached.

## Names are promises

A name tells the reader what to expect. Reusing a word the codebase already gave a meaning breaks that promise. A grand name on a trivial body breaks it the other way. Check both before naming anything.

## Inlining is the default

Extracting a piece of code costs a jump for every future reader. Extract only when the name carries meaning the inline form doesn't, the logic is genuinely reused, or the body hides complexity worth labelling. Three similar lines beat a premature abstraction.

## Simple is relative to the reader

Calibrate to the codebase's actual maintainers. Idiomatic constructs are fine for fluent readers; don't dumb code down for a hypothetical novice, and don't dress it up to look sophisticated.

## Tests are part of the code

Code without tests doesn't exist yet. Tests are written with the code, pinned to the spec the plan defined, strong enough to fail when the behaviour breaks.
