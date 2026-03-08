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

## `Map` and `Set` type and syntax ✅ IMPLEMENTED

Implement native `Map` and `Set` types with syntax support.

- Current status: Map and Set are fully implemented with bracket notation only.  Literal syntax: `{'a' -> 1, 'b' -> 2}` (Map), `{1, 2, 3}` (Set), `{->}` / `{}` (empty).  Operations: `m[k]` (get → option), `m[k?]` (has → bool), `m[k] = v;` (put), `m[!k]` (del).  Key types supported include atoms, chars, and number pairs.  92 regression tests in `common/tests/` cover all operations.

```
let m = {'a' -> 100, 'b' -> 200};
m['c'] = 300;
(m['a'] m['b'?] m[!'a'])
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

## Strings ✅ IMPLEMENTED (pending jet performance)

Implement true strings with operators.

Strings are `cord` (`@t`) UTF-8 encodings.  `"foo"` = `String`; `'foo'` = `Chars` (symbol/key use).  Both are the same underlying atom; different Jock types.

```
let forename:String = "Buckminster";
let surname:String = "Fuller";
forename + " " + surname
```

- Current status:  String and Chars literals, `+` concatenation, `lent(s)` byte-length, `s[i]` byte-index, and `s[i:j]` byte-slice are all implemented and correct.  String ops compile to Nock calls to `met`/`cat`/`cut` from hoon.hoon.  **Performance is very slow** because these arms are unjetted — see "Jet Matching" below.  String tests hang on CI until jetting is resolved.

## Jet Matching

Enable jet dispatch for hoon.hoon arms so that string operations and arithmetic run at native speed.

### Background

Jock's compiler (`jock.hoon`) calls standard Hoon library arms (`met`, `cat`, `cut`, `add`, `sub`, etc.) from `hoon.hoon` at runtime to implement string ops and arithmetic.  NockApp's jet system could replace these with fast Rust implementations — but jets only fire when the called battery has matching hint labels registered.

The hint mechanism requires:
- A core-level hint `~%  %k.136  ~  ~` on the Hoon core
- Per-arm hints `~/  %arm-name` on each arm to be jetted

`hoon.hoon` already has the `~%  %k.136  ~  ~` core-level hint, but has **no** per-arm `~/` hints — and `hoon.hoon` cannot be modified.  As a result, the hot state entries in `crates/jockc/main.rs` register the right paths but never fire.

### Proposed fix: `jruntime.hoon`

Create a new file `common/hoon/lib/jruntime.hoon` (freely modifiable) that:

1. Has `~%  %k.136  ~  ~` and per-arm `~/  %name` hints
2. Contains wet-gate wrappers that delegate to the corresponding hoon.hoon arms in the subject
3. Is compiled into `jockc.jam` as part of the Jock kernel
4. Is callable from jock.hoon's codegen for the specific arms that need jetting

Example structure:
```hoon
~%  %k.136  ~  ~
|%
~/  %met
++  met  |*([a=bloq b=*] (met:hoon a b))
~/  %cat
++  cat  |*([a=bloq b=* c=*] (cat:hoon a b c))
~/  %cut
++  cut  |*([a=bloq b=[p=@ q=@] c=*] (cut:hoon a b c))
~/  %add
++  add  |*([a=@ b=@] (add:hoon a b))
:: ... all other jetted arms ...
--
```

When jetted, the Rust implementation runs directly (bypassing the wrapper body).  When not jetted (fallback), the wrapper delegates to hoon.hoon — correct but slow.  Two cores having the same `%k.136` label don't conflict: each registers by its own battery hash.

### Implementation steps

1. **`common/hoon/lib/jruntime.hoon`** — create the wrapper file with all arms that should be jetted.  Wet gates required (dry gates cause rest-loop during jock.hoon mint).  Arms needed at minimum: `met`, `cat`, `cut`, `add`, `dec`, `sub`, `mul`, `div`, `mod`, `dvr`, `gte`, `gth`, `lte`, `lth`, `mug`, `dor`, `gor`, `mor`.

2. **`crates/jockc/hoon/lib/jruntime.hoon`** — symlink or copy into jockc's lib dir so `hoonc` compiles it into `jockc.jam`.

3. **`common/hoon/lib/jock.hoon`** — add a `jruntime-lib` arm alongside `hoon-lib` that resolves the jruntime core from the Jock compiler's subject.  Update `make-hoon-binop` (and `make-hoon-call`) to route jetted arms through `jruntime-lib` instead of `hoon-lib`.

4. **`crates/jockc/main.rs`** — restore hot state entries for `met`, `cat`, `cut` (removed in cleanup); verify all other entries are present.  The `jet_met`/`jet_cat`/`jet_cut` Rust implementations must handle the wet-gate sample axis correctly (`+<+<` not `+<`).

5. **Build and test** — `make clean-jam && make jockc`, then run string tests; they should complete within timeout.  Run full test suite to confirm no regressions.

### Known complication

Wet gate sample extraction: for a wet gate `|*([a b] ...)`, the sample is at a different axis than for a dry gate.  The Rust jet implementations in `nockvm` must extract arguments at the correct axis.  Confirmed axis for wet gates: `+<+<.gate` (not `+<.gate`).  Verify each jet implementation handles this.
