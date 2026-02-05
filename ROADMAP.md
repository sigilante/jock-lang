# Roadmap

## Cache noun builds

Cache large noun builds.

- Current status:  `hoon` and other libraries are rebuilt every time they are used, which is expensive and should be avoided.

## Debugging support

Implement per-line debugging traceback on Jock compilation.

## Floating-point support

Support a fractional-part number system.

(I, @sigilante, have a lot of opinions on this.  Talk to me before digging into this one.)

## Function self-reference by name

Allow functions to refer to themselves by name rather than strictly by `$`.

## Gate-building gate interface

Define a syntax to successfully use gate-building gates from the Hoon FFI.

## Generalized compiler namespace

Supply varargs and other features to the compiler for use in Jock programs.

This involves converting the single `$map` in the compiler door sample to a `mip` with standard entries like `libs` and `args`.

- Current status:  libraries can be supplied to the sample of the compiler door as a `(map term cord)`.  (This should be changed to `(map path cord)` for flexibility, versioning, etc.)  `jockc` supports preprocessed argument insertion, but this should be replaced with this better system.

## Jock imports ✅ IMPLEMENTED

Support Jock library imports just like Hoon imports.

- Current status:  `import mylib;` where `mylib.jock` is in the import directory works via AST inlining.  The library's parse tree (compose/func/let chains) is spliced into the importing file at parse time.  No new module system needed — the Rust loader already reads `.jock` files into the `libs` map.  Library files should contain definitions only (e.g. `func double(x: Atom) -> Atom { (x + x) }; ~`).

## Hoon return types

Implement Jock-compatible `$jype` values for Hoon FFI returns.

## `List` syntax support

Include syntactical affordances for indexing, slicing, etc.

```
let mylist = [1 2 3 4 5];
(
    mylist[0]
    mylist[1:4]
)
```

- Current status:  Index notation (`expr[idx]`) is implemented for both lists (runtime via `hoon.snag`) and tuples (compile-time axis resolution).  Slicing (`[1:4]`) is not yet implemented.

## `Map` type and syntax

Implement a native `Map` type with syntax support.

```
{
    'a' -> 'A'
    'b' -> 'B'
    'c' -> 'C'
}
```

## Operator associativity

Change to left-to-right association to minimize surprise.

## `Path` type

Implement a `List(String)` type with syntax support.

This will facilitate paths and wires for JockApp interactions.

## `print` keyword ✅ IMPLEMENTED

Produce output as a side effect.

```
let a = 5;
print(a);
a
```

- Current status:  Runtime prettyprinting works for all basic types.  `print(x)` generates Nock hint formulas that evaluate at runtime — the type (jype) selects the formatter at compile time, and the value is computed at runtime.  Supported types: `%number` (decimal via `hoon.scot-ud`), `%hex` (hex via `hoon.scot-ux`), `%chars` (passthrough), `%logical` (inline `%.y`/`%.n`), and `%fork` option types (runtime none/some check).
- Known issue:  Number formatting is slow (~10s per value) because the hoon library's arithmetic functions (`div`, `mod`, `add`, etc.) are not jetted.  The library is compiled with `(mint ut %noun)` which produces correct Nock but battery hashes don't match the kernel's jet registrations.  Fixing this requires either (a) compiling hoon.hoon in a way that produces matching battery hashes, (b) registering jets for the standalone core's batteries in the Nock runtime, or (c) caching the compiled noun (see "Cache noun builds" above) so the cost is amortized.

## `protocol` traits interface ✅ IMPLEMENTED

Define a list of methods and type relations to be validated at compile time.

- Current status:  Traits are implemented via `trait Name { method1; method2; }` syntax.  Classes can implement traits: `class C(S) impl Trait1, Trait2 { ... }`.  Operator overloading is supported: `trait Add(+) { add; }` for binary operators and `trait Neg(unary -) { neg; }` for unary operators, including arbitrary Unicode operators.  `Self` type resolves in method signatures.

```
compose trait Add(+) { add; };
compose trait Sub(-) { sub; };
compose struct PointState { x: Real, y: Real };
compose
  class Point(PointState) impl Add, Sub {
    add(self: Self, p: Self) -> Self { ( self.x + p.x  self.y + p.y ) }
    sub(self: Self, p: Self) -> Self { ( self.x - p.x  self.y - p.y ) }
  }
;
let p = Point { x: 101, y: 105 };
let q = Point { x: 42, y: 7 };
p + q
```

## REPL development

Produce a feature-complete, fast Jock REPL/CLI.

[Jojo](https://github.com/sigilante/jojo) is a proof of concept, and does not represent any serious thought towards the "best" solution.

## Strings

Implement true strings with operators.

Strings should be `cord` UTF-8 encodings, as `tape`s are several times larger in memory representation.  Strings may or may not be agnostic to quote type (defer this decision).

```
let forename:String = "Buckminster";
let surname:String = "Fuller";
forename + " " + surname
```

- Current status:  Right now we can write strings but operations on them must be routed through the Hoon FFI.  PR #59 contains work towards supporting and testing strings.
