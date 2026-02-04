# Jock Implementation Roadmap: Immediate Next Steps
## For Claude Code Execution

**Repository:** github.com/zorp-corp/jock-lang (main) / github.com/sigilante/jock-lang (development fork)
**Current Branch:** `sigilante/jype-refactor`
**Target:** Production-ready type system + NockApp compatibility
**Last Updated:** 2026-02-03

---

## Sprint 1: Type System Foundation ✅ COMPLETE

### Task 1.1: Struct Implementation ✅
**Location:** `/common/hoon/lib/jock.hoon`

**Completed:**
- [x] Parser recognizes `struct` keyword and named field definitions
- [x] AST node: `[%struct name=cord fields=(list [name=term type=jype])]`
- [x] Struct literal construction: `Point { x: 42, y: 7 }`
- [x] Field access via `.` operator compiles to axis lookup through `struct-to-jype`
- [x] Field update via `=` operator (uses Nock 10 edit)
- [x] Struct bunt (default values) via `type-to-default`
- [x] Struct as function parameter type (eager `%limb` resolution in lambda mint)
- [x] Struct as function return type (stripped return type name in `call-core`)
- [x] Nested structs — field types resolved eagerly at definition time
- [x] Multiple struct definitions coexist (Nock 8 push-onto-subject)

**Nock Compilation (actual):**
- Struct definition: `compose struct Point { x: Real, y: Real };` → Nock 8 pushes bunt `[0 0]` onto subject
- Struct literal: `Point { x: 1, y: 2 }` → compiles field values in definition order
- Field access: `p.x` → `struct-to-jype` maps fields to axes, `axis-at-name` resolves

**Tests:**
- `struct-basic.jock`: Define + reference struct type
- `struct-field-access.jock`: `p.x` → 42
- `struct-func-param.jock`: `func getx(p: Point) -> Real { p.x }` → 42
- `struct-func-simple.jock`: `func identity(p: Point) -> Point { p }` → [42 7]
- `struct-nested-basic.jock`: `r.origin.x` through Rect→Point → 1
- `struct-nested-shallow.jock`: `r.origin` → [1 2]

### Task 1.2: Newtype Wrappers
**Status:** Not started. Deferred — struct implementation covers the core use case.

### Task 1.3: Type Aliases ✅
**Completed:**
- [x] `alias` keyword parsed
- [x] Aliases resolve to target type at definition time
- [x] No runtime distinction — transparent substitution
- Generic aliases not yet supported (requires generics, Sprint 4)

---

## Sprint 2: Impl Blocks & Traits ✅ COMPLETE

### Design Direction

Structs + impl blocks use the **class-with-struct-state** pattern. The underlying Hoon model is the **door** (a core with a sample):
- **Struct** = the sample type (data layout)
- **Class with impl** = the battery (methods operating on that data) + trait validation
- Together they form a door: `[battery sample]`

### Task 2.1: Class with Struct State + Methods ✅

**Completed:**
- [x] `class Name(StructType) { ... }` parses and compiles
- [x] Methods stored as `(map term jock)` in AST
- [x] Methods compile to battery arms of a Nock core (door)
- [x] `self` parameter binds to the struct instance (door sample at axis +6)
- [x] Method calls resolve via subject walk + core invocation
- [x] `Self` type resolves to the implementing struct type in method signatures
- [x] Constructor syntax: `Point { x: 42, y: 7 }` creates struct instance

**Actual Syntax:**
```jock
compose struct PointState { x: Real, y: Real };
compose
  class Point(PointState) {
    add(self: Self, p: Self) -> Self { ( self.x + p.x  self.y + p.y ) }
    neg(self: Self) -> Real { self.y }
  }
;
let p = Point { x: 101, y: 105 };
let q = Point { x: 42, y: 7 };
p.add(q)
```

**Tests:**
- `class-basic.jock`: Basic class with struct state and method call
- `class-define.jock`: Class definition and construction
- `class-3d.jock`: 3D point class with methods

### Task 2.2: Trait Definition & Validation ✅

**Completed:**
- [x] `trait Name { method1; method2; }` parses
- [x] Trait signatures stored in compilation environment
- [x] `impl Trait` clause on class validates method presence against trait
- [x] Multiple traits: `class C(S) impl Trait1, Trait2 { ... }`
- [x] `Self` type parameter resolves to implementing struct type
- [x] Missing methods produce compile error

**Actual Syntax:**
```jock
compose trait Arithmetic { add; neg; };
compose trait Subtraction { sub; };
compose
  class Point(PointState) impl Arithmetic, Subtraction {
    add(self: Self, p: Self) -> Self { ( self.x + p.x  self.y + p.y ) }
    neg(self: Self) -> Real { self.y }
    sub(self: Self, p: Self) -> Self { ( self.x - p.x  self.y - p.y ) }
  }
;
```

**Tests:**
- `trait-basic.jock`: Trait definition + class impl validation
- `trait-self.jock`: `Self` type in method signatures
- `trait-multiple.jock`: Class implementing multiple traits

### Task 2.3: Operator Overloading ✅

**Completed:**
- [x] Traits can bind to operators: `trait Add(+) { add; }` and `trait Neg(unary -) { neg; }`
- [x] Binary operator overloading: `p + q` dispatches to `add` method
- [x] Unary operator overloading: `-w` dispatches to `neg` method
- [x] Arbitrary Unicode operators: `trait Neg(unary ⊖) { neg; }` → `⊖w`
- [x] Operator whitelist system for custom operators

**Tests:**
- `op-overload.jock`: Binary `+` and `-` overloads
- `unary-parens.jock`: Unary `-` with parenthesized syntax
- `unary-unicode.jock`: Unicode operator `⊖`
- `unary-tuple-2.jock`, `unary-tuple-3.jock`: Unary ops on tuples
- `unary-sint.jock`: Unary negation on signed integers

### Task 2.4: Index Notation ✅

**Completed:**
- [x] `expr[idx]` syntax parsed into `%index` AST node
- [x] Tuple indexing: compile-time axis resolution via `tuple-axis` / `get-index-number`
- [x] List indexing: generates `hoon.snag` call nock directly (no `%call` re-entry)
- [x] Nested indexing: `b[1][0]` chains correctly
- [x] Path-basic test for path noun syntax

**Tests:**
- `indexing-tuple.jock`: `t[0]`, `t[1]`, `t[2]` on tuple → `(100 200 300)`
- `indexing-list.jock`: `a[0]` on list → `100`
- `indexing-nested.jock`: `b[1][0]` on nested list → `30`
- `path-basic.jock`: Path noun syntax

---

## Sprint 3: Unions & Pattern Matching (2 weeks)

### Task 3.1: Union Definition
**Location:** Parser + type system

**Requirements:**
- Head-tagged cells for variants
- Support multiple fields per variant
- Type-safe construction

**Example:**
```jock
union Result {
  case ok(value: Atom)
  case err(code: Atom, msg: Chars)
}

let success = Result::ok(42);
let failure = Result::err(404, "Not found");
```

**Nock Representation:**
- `ok(42)` → `[%ok 42]`
- `err(404, "Not found")` → `[%err 404 "Not found"]`

**Acceptance Criteria:**
- [ ] Union definitions parse
- [ ] Variant construction works
- [ ] Head tags generated correctly
- [ ] Type checker validates usage

### Task 3.2: Pattern Matching
**Location:** Compiler control flow

**Requirements:**
- `match` or `switch` keyword
- Exhaustiveness checking
- Binding variables from patterns

**Example:**
```jock
match result {
  ok(val) -> val * 2
  err(code, msg) -> {
    print("Error " + code + ": " + msg);
    0
  }
}
```

**Implementation:**
- Compile to nested Nock 6 (if-then-else)
- Test head tag with Nock 5 (equality)
- Extract fields with Nock 0 (slot)

**Acceptance Criteria:**
- [ ] Pattern matching syntax parses
- [ ] Exhaustiveness checker works
- [ ] Variable binding works
- [ ] Compiles to correct Nock
- [ ] Type checker validates patterns

---

## Sprint 4: Generics & Monomorphization (2 weeks)

### Task 4.1: Generic Function Syntax
**Location:** Parser + type system

**Requirements:**
- Type parameters in angle brackets
- Type parameter binding at call site
- Explicit type annotations on parameters

**Example:**
```jock
func first<T>(xs: List<T>) -> ?T {
  match xs {
    [] -> ~
    [head, ..tail] -> [~ head]
  }
}

let x = first([1, 2, 3]);  // T = Atom inferred
```

**Acceptance Criteria:**
- [ ] Generic syntax parses
- [ ] Type parameters tracked in environment
- [ ] Call site type inference works
- [ ] Empty collection annotation required

### Task 4.2: Monomorphization Pass
**Location:** Compiler backend

**Requirements:**
- Generate separate Nock for each concrete type
- Maintain mapping: (function, type args) → compiled Nock
- No runtime polymorphism

**Implementation Strategy:**
1. During compilation, track generic function calls
2. For each unique type instantiation, generate specialized Nock
3. Replace generic calls with specialized versions

**Acceptance Criteria:**
- [ ] Monomorphization generates correct Nock
- [ ] Each type instantiation compiled separately
- [ ] Performance is good (no overhead)
- [ ] Test with multiple type instantiations

---

## Sprint 5: NockApp Kernel Interface (1 week)

### Task 5.1: Kernel Type Definitions
**Location:** `/common/hoon/jib/kernel.jock` (new file)

**Create Standard Types:**
```jock
alias Tang = List<Chars>
alias Term = Chars

struct Goof {
  mote: Term
  tang: Tang
}

alias Wire = Path

struct Input {
  eny: Uint
  our: Hex
  now: Date
  cause: Noun
}

struct Ovum {
  wire: Wire
  input: Input
}

struct Crud {
  goof: Goof
  input: Input
}
```

**Acceptance Criteria:**
- [ ] Types defined in standard library
- [ ] Compile correctly to Nock
- [ ] Compatible with Hoon equivalents

### Task 5.2: Kernel Class Template
**Location:** `/common/hoon/jib/kernel-template.jock` (new file)

**Create:**
```jock
class Kernel<S>(state: S) {
  load(old: Noun) -> S {
    // Override in subclass
    old as! S
  }
  
  wish(expr: Noun) -> Noun {
    crash("wish not implemented")
  }
  
  peek(path: Path) -> ?(?(Noun)) {
    // Override in subclass
    ~
  }
  
  poke(cause: Noun) -> (List<Noun>, S) {
    // Override in subclass
    ([], state)
  }
}
```

**Acceptance Criteria:**
- [ ] Template compiles
- [ ] Arms at correct axes (+4, +10, +22, +23)
- [ ] Can be extended by user code
- [ ] Test with simple kernel

### Task 5.3: Integration Test
**Location:** `/common/hoon/try/simple-kernel.jock` (new file)

**Write Simple Kernel:**
```jock
struct CounterState {
  count: Atom
}

class CounterKernel extends Kernel<CounterState> {
  peek(path: Path) -> ?(?(Noun)) {
    match path {
      /count -> [~ ~ state.count]
      _ -> [~ ~]
    }
  }
  
  poke(cause: Noun) -> (List<Noun>, CounterState) {
    match cause {
      [%increment, n] -> {
        let new_state = CounterState(state.count + n);
        ([], new_state)
      }
      _ -> ([], state)
    }
  }
}
```

**Test Via:**
```bash
./jockc ./common/hoon/try/simple-kernel --import-dir ./common/hoon/jib
# Should build and run successfully
```

**Acceptance Criteria:**
- [ ] Kernel compiles to valid Nock
- [ ] Arms at correct axes
- [ ] Can be invoked via NockApp runtime
- [ ] State persists across pokes

---

## Sprint 6: Path Syntax & Standard Library (1 week)

### Task 6.1: Path Parser
**Location:** Parser in `/crates/jockc/hoon/lib/jock.hoon`

**Requirements:**
- Recognize `/foo/bar/baz` syntax
- Support interpolation: `/(variable)`
- Compile to `List<Chars>`

**Example:**
```jock
let segment = "users";
let user_id = "123";
let path = /(segment)/(user_id)/profile;
// Compiles to: ["users" "123" "profile"]
```

**Acceptance Criteria:**
- [ ] Path syntax parses
- [ ] Interpolation works
- [ ] Compiles to correct Nock
- [ ] Type checking validates interpolated values

### Task 6.2: Basic Standard Library
**Location:** `/common/hoon/jib/*.jock` (new files)

**Create:**
- `list.jock`: length, first, last, append, concat, reverse
- `string.jock`: concat, split, trim, to_chars, from_chars
- `math.jock`: basic arithmetic, min, max, abs
- `option.jock`: map, flat_map, unwrap_or, is_some

**Example (`list.jock`):**
```jock
func length<T>(xs: List<T>) -> Atom {
  match xs {
    [] -> 0
    [_, ..tail] -> 1 + length(tail)
  }
}

func first<T>(xs: List<T>) -> ?T {
  match xs {
    [] -> ~
    [head, ..] -> [~ head]
  }
}
```

**Acceptance Criteria:**
- [ ] Standard library modules compile
- [ ] Can be imported in user code
- [ ] Functions work correctly
- [ ] Well-documented with examples

---

## Sprint 7: Optimization & Polish (1 week)

### Task 7.1: Basic Subject Knowledge Analysis
**Location:** Compiler optimizer

**Requirements:**
- Track known subject structure during compilation
- Compute axes statically
- Fold constants where possible

**Example Optimization:**
```jock
let x = 5;
let y = x + 3;
y * 2
```

**Before:**
```nock
[8 [1 5] 8 [7 [0 2] 4 4 4 0 1] 7 [0 2] 4 4 4 4 0 1] 0 1]
```

**After:**
```nock
[1 16]  // (5 + 3) * 2 = 16
```

**Acceptance Criteria:**
- [ ] Constant folding works
- [ ] Static axis computation works
- [ ] Benchmark shows improvement
- [ ] No correctness regressions

### Task 7.2: Error Messages
**Location:** All compiler phases

**Requirements:**
- Clear, actionable error messages
- Show source location
- Suggest fixes where possible

**Example:**
```
Error: Type mismatch at line 10, column 5
  Expected: Atom
  Found:    List<Atom>

  let x: Atom = [1, 2, 3];
                ^^^^^^^^^

Suggestion: Did you mean to use List<Atom> as the type?
```

**Acceptance Criteria:**
- [ ] All compiler errors include source location
- [ ] Type errors show expected vs. actual
- [ ] Suggestions provided where applicable
- [ ] Format is consistent across errors

### Task 7.3: Documentation
**Location:** `/docs/*.md` (new directory)

**Create:**
- `LANGUAGE_REFERENCE.md`: Complete syntax guide
- `TYPE_SYSTEM.md`: Types, traits, generics
- `NOCKAPP_GUIDE.md`: Building kernels
- `STDLIB_API.md`: Standard library reference
- `EXAMPLES.md`: Practical examples

**Acceptance Criteria:**
- [ ] Documentation is comprehensive
- [ ] Examples compile and run
- [ ] Clear explanations with rationale
- [ ] Searchable and well-organized

---

## Testing Strategy

### Unit Tests
**Location:** `/crates/jockc/hoon/lib/test-jock.hoon`

**Add Tests For:**
- [ ] Struct creation and field access
- [ ] Newtype wrapping and unwrapping
- [ ] Type aliases
- [ ] Trait definitions
- [ ] Impl blocks and method calls
- [ ] Union construction and matching
- [ ] Generic functions
- [ ] Path syntax
- [ ] Standard library functions

### Integration Tests
**Location:** `/common/hoon/try/*-test.jock`

**Add Tests For:**
- [ ] Simple NockApp kernel
- [ ] Stateful kernel with multiple pokes
- [ ] Kernel with working peek
- [ ] Complex type composition
- [ ] Real-world-ish applications

### Performance Benchmarks
**Location:** `/benchmarks/*.jock`

**Benchmark:**
- [ ] Fibonacci (recursive)
- [ ] List operations (map, filter, fold)
- [ ] Struct field access
- [ ] Method dispatch overhead
- [ ] Pattern matching cost

---

## Continuous Integration

### Build Checks
- [ ] All code compiles without warnings
- [ ] All tests pass
- [ ] No regressions in existing functionality
- [ ] Documentation builds

### Code Quality
- [ ] Consistent naming conventions
- [ ] Comments explain non-obvious code
- [ ] No dead code
- [ ] Hoon code follows style guide

---

## Definition of Done

### Feature Complete When:
1. Implementation matches specification
2. Unit tests pass (100% coverage for new code)
3. Integration tests pass
4. Documentation written
5. Examples work
6. Code reviewed
7. Performance acceptable (no worse than 2x naive)
8. No known bugs

### Beta Release When:
- [ ] All Sprint 1-6 tasks complete
- [ ] 100+ tests passing
- [ ] Documentation 80% complete
- [ ] At least 3 example applications work
- [ ] Type system validates all examples
- [ ] NockApp kernel interface tested

---

## Tools & Environment

### Required Tools
- Rust toolchain (1.70+)
- Hoon compiler (from nockchain)
- NockVM (from nockchain)
- Git
- Make

### Build Commands
```bash
# Build jockc compiler
make jockc

# Build jockt test runner
make jockt

# Run specific test
./jockt exec <test-number> --import-dir ./common/hoon/jib

# Run all tests
./jockt test-all --import-dir ./common/hoon/jib

# Run example
./jockc ./common/hoon/try/<example>.jock --import-dir ./common/hoon/jib
```

### Development Workflow
1. Edit Hoon code in `/crates/jockc/hoon/lib/jock.hoon`
2. Edit Rust wrapper in `/crates/jockc/main.rs` (if needed)
3. Run `make jockc` to rebuild
4. Test with `./jockt` or `./jockc`
5. Commit with clear message

---

## Immediate Next Actions (This Week)

### Priority 1: Sprint 3 — Unions & Pattern Matching
1. Design union/sum type AST representation
2. Implement `union` keyword parser
3. Implement variant construction with head tags
4. Implement `match` with exhaustiveness checking
5. Build Result/Option types as union examples

### Priority 2: Stabilize Indexing
1. Verify list indexing end-to-end (blocked on cold Hoon compile time after cache clear)
2. Verify nested list indexing
3. Add error messages for out-of-bounds or wrong-type index targets

### Priority 3: Improve Error Messages
1. Add source locations to type errors
2. Improve trait validation error messages (which method is missing)
3. Add suggestions for common mistakes

---

## Questions to Answer During Implementation

### Type System
- [ ] How do we handle recursive types?
- [ ] What's the scoping rule for type parameters?
- [ ] How do we handle trait coherence?
- [ ] What's the story for type inference limits?

### Compilation
- [ ] What's the exact Nock pattern for method dispatch?
- [ ] How do we ensure jet matching works?
- [ ] What's the memory layout for complex nested types?
- [ ] How do we handle stack overflow in recursion?

### Interop
- [ ] How do we call Jock from Hoon?
- [ ] How do we handle Hoon irregular syntax in FFI?
- [ ] What's the ABI for Jock/Hoon function boundaries?
- [ ] How do we share types between Jock and Hoon?

---

## Success Metrics

### Week 1-2 (Sprint 1) ✅
- Structs parse and compile
- Can create struct, access fields, update fields
- Type aliases work
- Nested structs work
- 10+ struct/alias tests passing

### Week 3-4 (Sprint 2) ✅
- Traits defined, stored, and validated
- Classes with struct state compile to doors
- Method calls work with `Self` type
- Operator overloading (binary + unary, including Unicode)
- Index notation for tuples (compile-time) and lists (runtime via snag)
- 25+ tests passing (traits, classes, operators, indexing)

### Week 5-6 (Sprint 3)
- Unions work with pattern matching
- Exhaustiveness checking
- Can build simple Result/Option types
- 40+ tests passing

### Week 7-8 (Sprint 4)
- Generics compile with monomorphization
- Type inference works
- Standard generic functions (first, map, etc.)
- 60+ tests passing

### Week 9 (Sprint 5)
- NockApp kernel template works
- Simple counter kernel compiles and runs
- Arms at correct axes
- 70+ tests passing

### Week 10 (Sprint 6)
- Path syntax works
- Basic standard library available
- Can build small applications
- 85+ tests passing

### Week 11 (Sprint 7)
- Optimizations showing improvement
- Error messages are clear
- Documentation complete
- 100+ tests passing

---

## Communication Plan

### Daily Standup (Async)
- What did I complete yesterday?
- What am I working on today?
- Any blockers?

### Weekly Review
- Progress against sprint goals
- Demos of working features
- Adjust priorities if needed

### Monthly Retrospective
- What went well?
- What could improve?
- Update roadmap based on learning

---

## Getting Help

### When Stuck
1. Read existing code for patterns
2. Consult Nock documentation
3. Check Hoon implementation
4. Ask in Urbit developer groups
5. Create GitHub issue with minimal reproduction

### Resources
- Jock docs: https://docs.jock.org
- Nock spec: https://docs.urbit.org/language/nock
- Hoon docs: https://docs.urbit.org/language/hoon
- NockApp: https://github.com/zorp-corp/nockchain

---

This roadmap is aggressive but achievable with focused effort. Each sprint builds on the previous, with clear acceptance criteria and tests. The result will be a production-ready type system and NockApp compatibility, enabling real applications in Jock.

Let's make Nock programming accessible without compromising on rigor or performance. The future is deterministic computation, and Jock is the practical path to get there.

**Status:** Sprints 1-2 complete, Sprint 3 next
**Last Updated:** 2026-02-03
**Owner:** Claude Code + Senior Engineering Team
