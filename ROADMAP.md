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

## Jock imports

Support Jock library imports just like Hoon imports.

This probably requires changing the library map to use paths as the keys instead of terms.

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

## `print` keyword

Produce output as a side effect.

We can print literals fine, but references (variables) are not yet complete.

```
let a = 5;
print(a);
a
```

- Current status:  PR #53 contains work towards wrapping the environment in a closure so that references can be resolved at runtime.

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
