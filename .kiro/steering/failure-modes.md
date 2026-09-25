# Failure modes

Named code smells. Planning avoids them in the HOW; verification flags them by name. Each entry: one line, then a minimal bad/good pair. Examples lean Scala; the smell is language-neutral, translate the shape.

Use the entry that bites. This is a vocabulary, not a checklist to complete.

## Dispatch tags
A type that exists only to be matched on, so a dispatcher can pick a function. Store the function directly.
```scala
// bad
Map("stage_1" -> CsvSource); t match { case CsvSource => Loaders.csv(...) }
// good
Map("stage_1" -> Loaders.csv)
```

## Useless wrapper
A class that groups two functions "to keep them together" and adds nothing but a hop.
```scala
// bad
case class StageOp(read: ..., apply: ...)
// good
Map[String, (SparkSession, String, DataFrame) => DataFrame]
```

## Caller's dispatch inside the callee
A function that branches on whether its input is present. The caller knows; let the caller decide.
```scala
// bad
def enrich(df, col, source: Option[DataFrame]) = source match { ... }
// good
def enrich(df, col, lookup: DataFrame) = ...   // caller: paths.get(col).fold(df)(...)
```

## Loop-generated tests
A loop in a test file emitting N tests. Hides names, counts, and intent.
```scala
// bad
cases.foreach { case (in, out) => s"maps $in" in { f(in) shouldBe out } }
// good
"builds the full record" in { result shouldBe Expected(a = ..., b = ..., c = ...) }
```

## One-line helper
A private method wrapping a single self-explanatory expression. Inline it.
```scala
// bad
private def colName(s: Int) = s"stage_$s"
// good
df.withColumn(s"stage_$s", ...)
```

## Single-use constant
A named constant referenced once. Inline unless the value is non-obvious or used three-plus times.
```scala
// bad
private val KeyCol = "KEY"; SourceSpec(path, inputField = KeyCol)
// good
SourceSpec(path, inputField = "KEY")
```

## Defensive guard for an impossible case
A check for a state production guarantees away. Trust the contract; fail loud if it lies.
```scala
// bad
if (sources.nonEmpty) Readers.init()
// good
Readers.init()
```

## Pre-fill then overwrite
Creating placeholders every step must then undo. Let each step add what it owns; fill gaps once at the end.

## Stage-label variable names
Intermediates named for where they sit in the pipeline (or worse, overloading a real term). Name what the value is; chain the rest.
```scala
// bad
val deduped = ...; val enriched = deduped.transform(...)
// good
val invoices = readCsv(path).transform(...).transform(...)
```

## Self-wrapping methods
A pair like read + apply where apply re-branches on what read produced. The caller threads them; no internal cases.

## Currying without partial application
Multiple parameter lists no caller ever partially applies. One list.

## Extension method for one call site
A `.foo` extension used once. Plain function. Extensions are for operations used method-style across the codebase.

## Vocabulary misuse
A new name that collides with an existing codebase meaning. Grep first; reuse the meaning or pick a new word.

## Generic shape over one concrete case
An abstraction generalising cases that share nothing. A flat module of named functions is the structure.

## Speculative configuration
A flag for a fact that is static per environment or market. Hardcode the fact; flags are for genuine runtime variation.
```scala
// bad
opt[String]("stage-1-type")   // the story fixes this per market
// good
Market.B -> Map("stage_1" -> Loaders.json("lookupKey"))
```

## Adding an entry
When the same new smell is flagged twice, add it here: one line, minimal pair. That's how the vocabulary grows.
