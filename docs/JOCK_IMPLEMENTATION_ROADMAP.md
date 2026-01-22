# Jock Implementation Roadmap: Immediate Next Steps
## For Claude Code Execution

**Repository:** github.com/zorp-corp/jock-lang (main) / github.com/sigilante/jock-lang (development fork)
**Current Branch:** Beta development
**Target:** Production-ready type system + NockApp compatibility

---

## Sprint 1: Type System Foundation (2 weeks)

### Task 1.1: Struct Implementation
**Location:** `/crates/jockc/hoon/lib/jock.hoon`

**Requirements:**
- Parse struct definitions with named fields
- Generate AST nodes for struct types
- Compile to Nock door structure
- Support field access via `.` operator
- Implement structural type checking

**Example Code:**
```jock
struct Point {
  x: Real
  y: Real
}

let p = Point(1.0, 2.0);
let x_val = p.x;
```

**Nock Compilation Target:**
```nock
// Point as door: [battery sample]
// sample: [x y]
// battery: [constructor field-accessors ...]
[8 [1 [x-val y-val]] [1 /* arms */] 0 1]
```

**Acceptance Criteria:**
- [ ] Parser recognizes `struct` keyword and field definitions
- [ ] AST includes struct type information
- [ ] Compiler generates correct Nock core
- [ ] Field access compiles to correct axis lookup
- [ ] Type checker validates field types
- [ ] Test: Can create struct, access fields, pass around

### Task 1.2: Newtype Wrappers
**Location:** Same file

**Requirements:**
- Single-field structs create nominal types
- Require explicit cast to unwrap
- Maintain type distinction at compile time

**Example:**
```jock
struct UserId(Atom)

let id = UserId(42);
let raw = id as Atom;  // OK
let bad: Atom = id;    // Error: type mismatch
```

**Implementation Notes:**
- Use same door structure as structs
- Type checker maintains distinction
- `as` operator performs structural cast

**Acceptance Criteria:**
- [ ] Single-field structs parse correctly
- [ ] Type system treats as distinct type
- [ ] Cast operator works correctly
- [ ] Compile-time type errors for mismatches

### Task 1.3: Type Aliases
**Location:** Same file

**Requirements:**
- Transparent aliases (no wrapper)
- Compile-time substitution
- Support generic aliases

**Example:**
```jock
alias Path = List<Chars>
alias Wire = Path

let p: Path = /foo/bar;
let w: Wire = p;  // No cast needed
```

**Implementation:**
- Resolve aliases during type checking phase
- Substitute at AST level
- No runtime distinction

**Acceptance Criteria:**
- [ ] Parser recognizes `alias` keyword
- [ ] Type checker substitutes aliases
- [ ] No cast required for compatible aliases
- [ ] Generic aliases work correctly

---

## Sprint 2: Traits & Impl (2 weeks)

### Task 2.1: Trait Definition
**Location:** `/crates/jockc/hoon/lib/jock.hoon`

**Requirements:**
- Define trait syntax
- Parse trait definitions
- Store trait requirements in compilation environment
- Support `Self` type parameter

**Example:**
```jock
trait Arithmetic {
  add(self, other: Self) -> Self
  neg(self) -> Self
}
```

**Implementation Strategy:**
- Trait = named collection of method signatures
- Store in compilation environment as type constraint
- No code generation at trait definition

**Acceptance Criteria:**
- [ ] Parser recognizes `trait` keyword
- [ ] Trait definitions stored in environment
- [ ] Method signatures validated
- [ ] `Self` type parameter works

### Task 2.2: Impl Blocks (via Class)
**Location:** Same file

**Requirements:**
- Use `class` keyword for subject scope management
- Compile impl to Nock core with methods in battery
- Subject-oriented method resolution

**Example:**
```jock
class Point(x: Atom, y: Atom) {
  add(self, other: Point) -> Point {
    Point(self.x + other.x, self.y + other.y)
  }
  
  neg(self) -> Point {
    Point(-self.x, -self.y)
  }
}
```

**Nock Compilation:**
- Battery contains method formulas
- Sample contains state (x, y)
- Method call = slot access + slam

**Acceptance Criteria:**
- [ ] `class` syntax parses with methods
- [ ] Methods compile to battery arms
- [ ] `self` parameter works correctly
- [ ] Method calls resolve via subject walk
- [ ] Name collision detection works

### Task 2.3: Method Resolution
**Location:** Compiler type checker

**Algorithm:**
1. Walk subject tree (depth-first)
2. Find arm named `method` where declaring type matches target
3. Emit Nock: `[9 axis-of-arm [0 axis-of-subject]]`

**Edge Cases:**
- Name collisions: compile error in v1
- Type mismatches: compile error
- Missing methods: compile error

**Acceptance Criteria:**
- [ ] Method resolution algorithm implemented
- [ ] Correct Nock generated for method calls
- [ ] Type checking validates method exists
- [ ] Clear error messages for failures

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

### Priority 1: Get Development Environment Working
1. Clone repository
2. Build hoonc from nockchain
3. Build jockc and jockt
4. Run existing tests to verify setup
5. Read through existing Hoon code to understand structure

### Priority 2: Start Struct Implementation
1. Study existing type system in `/crates/jockc/hoon/lib/jock.hoon`
2. Add parser support for `struct` keyword
3. Extend AST to include struct nodes
4. Implement basic struct compilation (no methods yet)
5. Write tests for struct creation

### Priority 3: Document Current State
1. Inventory what's implemented vs. spec
2. Document known bugs/issues
3. Create task breakdown for remaining work
4. Set up project tracking (GitHub issues)

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

### Week 1-2 (Sprint 1)
- Structs parse and compile
- Can create struct, access fields
- Type checker validates struct usage
- 10+ tests passing

### Week 3-4 (Sprint 2)
- Traits defined and stored
- Impl blocks compile to cores
- Method calls work
- 25+ tests passing

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

**Status:** Ready for implementation
**Last Updated:** 2025-01-22
**Owner:** Claude Code + Senior Engineering Team
