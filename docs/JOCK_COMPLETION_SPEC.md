# Jock Language Completion Specification
## Mission: Make Nock Programming Accessible & Production-Ready

**Status:** Alpha → Beta → Production
**Target:** NockApp kernels, Urbit Gall agents, Nockchain applications
**Repository:** github.com/zorp-corp/jock-lang (fork: github.com/sigilante/jock-lang)

---

## Executive Summary

Jock is a subject-oriented, statically-typed functional language targeting Nock ISA. Current state: functional alpha with ad hoc type system. Goal: production-ready language with rigorous type system, full NockApp/Gall compatibility, and developer-friendly tooling.

**Critical Path:**
1. Type system overhaul (Beta spec → implementation)
2. NockApp kernel interface completion
3. Gall agent primitives
4. Compiler optimization (sKa, jet matching)
5. Developer tooling (LSP, debugger, package manager)

---

## Current State Assessment

### What Works (Alpha)
- Basic compiler pipeline: Jock → AST → Nock
- Core language features: functions, objects, control flow
- Hoon FFI (limited)
- Basic types: atoms, cells, lists, sets
- NockApp integration (via hoonc)
- Test framework (jockt)

### What's Broken/Missing
- **Type system**: ad hoc, no traits, weak inference
- **Standard library**: minimal, no Path/Wire native support
- **NockApp interface**: incomplete kernel primitives
- **Gall integration**: no agent support
- **Tooling**: no LSP, limited debugging, no package manager
- **Documentation**: incomplete, no design rationale docs
- **Performance**: naive compilation, no sKa optimization

---

## Phase 1: Type System Overhaul (Beta → Implementation)

### 1.1 Core Type System Components

#### Structs
```jock
// Product types with named fields
struct Point {
  x: Real
  y: Real
}

// Single-field newtypes (nominal wrappers)
struct UserId(Atom)  // opaque, requires explicit cast

// Transparent aliases
alias Path = List<Chars>  // no cast needed
```

**Implementation Requirements:**
- Parse struct definitions into AST nodes
- Generate Nock core with appropriate battery/sample layout
- Track field names and types in compilation environment
- Support structural equality checking
- Compile-time name resolution for fields

**Nock Compilation Strategy:**
- Struct → Door (core with sample)
- Fields → Sample slots at computed axes
- Methods → Battery arms
- Constructor → Gate that produces core instance

#### Traits
```jock
trait Arithmetic {
  add(self, other: Self) -> Self
  neg(self) -> Self
}

impl Arithmetic for Vec2 {
  add(self, other: Self) -> Self {
    Vec2(self.x + other.x, self.y + other.y)
  }
  neg(self) -> Self {
    Vec2(-self.x, -self.y)
  }
}
```

**Implementation Requirements:**
- Trait definition parsing and validation
- Impl block compilation to Nock cores
- Method resolution via subject tree walking
- Trait bounds checking at compile time
- Monomorphization (no dynamic dispatch)

**Critical Design Decision:**
Use `class` keyword instead of `impl` to manage subject scope:
```jock
class Point(List<Chars>) {
  head(self) -> ?Chars { /* ... */ }
  tail(self) -> Path { /* ... */ }
  
  // Nested impl for specific traits
  concat impl List {
    /* ... */
  }
}
```

**Subject-Oriented Method Resolution:**
1. Walk subject tree (axis-by-axis)
2. Find arm named `method` where target type = `T`
3. Emit Nock: slot access + slam
4. Name collisions: compile error (v1), later add `^` skip syntax

#### Unions (Sum Types)
```jock
union Result {
  case ok(value: Atom)
  case err(code: Atom, msg: Chars)
}
```

**Implementation Requirements:**
- Head-tagged cells: `[%ok value]`, `[%err code msg]`
- Pattern matching via `switch`/`match` (following `?+` pattern)
- Exhaustiveness checking
- No generics on unions for v1

#### Generics
```jock
func first<T>(xs: List<T>) -> ?T {
  switch xs {
    [] -> ~
    [head, ..tail] -> [~ head]
  }
}

let x = first([1 2 3])  // T = Atom inferred
let y = first([] as List<Atom>)  // T = Atom explicit
```

**Implementation Requirements:**
- Type parameter binding at call site
- Monomorphization (generate separate Nock for each concrete type)
- Empty collection annotation requirement
- Forward inference in function bodies
- No runtime polymorphism

### 1.2 Advanced Type Features

#### Option Chaining
```jock
e: T       → e.f: U
e: ?T      → e?.f: ?U
e: ??T     → e?.f: ???U  // no flattening
e: ?T, d:T → e ?? d: T   // default
e: ?T      → e!: T       // unwrap-or-crash
```

**Implementation Strategy:**
- Compile-time tracking of option depth
- Nock compilation: test for `~`, branch accordingly
- `!` operator: crash if null (Nock `[0 0]`)
- `??` operator: test left, return left if non-null, else right

#### Casting
| Syntax | Compile-time | Runtime | Use |
|--------|-------------|---------|-----|
| `as` | structural check | no | same-shape nominal conversion |
| `as?` | target known | mold check | returns `?T`, safe narrowing |
| `as!` | target known | mold check | returns `T`, crash on fail |

**Implementation Requirements:**
- Structural cast: ignore field names, check shape
- `as?`: runtime mold check (Hoon `;;` semantics), wrap in unit
- `as!`: runtime mold check, crash if fail
- All casts compile to Nock with appropriate type assertions

### 1.3 Type Inference Rules
| Context | Inference |
|---------|-----------|
| Function params | Explicit required |
| Function return | Explicit required |
| Lambda params | Explicit required |
| Lambda return | Explicit required |
| `let` binding | Inferred from RHS, or explicit |
| Generic type params | Inferred from arguments at call site |
| Empty collections | Explicit annotation required |
| Mixed numeric literals | Unify to supertype |
| Binary ops across types | Determined by operator's trait impl |

**Implementation Strategy:**
- Hindley-Milner-style inference for `let` bindings
- Explicit annotations everywhere else (pragmatic approach)
- Type errors: clear messages with suggested fixes

---

## Phase 2: NockApp Kernel Interface

### 2.1 Kernel Structure Requirements

**Standard Kernel Arms (Fixed Axes):**
- `+4` / `+load`: Load/upgrade kernel state
- `+10` / `+wish`: Evaluate Hoon expressions (optional)
- `+22` / `+peek`: Read-only state access (scry)
- `+23` / `+poke`: State-altering requests

**Jock Implementation:**
```jock
class Kernel(state: AppState) {
  // +load: upgrade handler
  load(old: Noun) -> AppState {
    // migration logic
    old as! AppState
  }
  
  // +wish: Hoon eval (can crash if not needed)
  wish(expr: Noun) -> Noun {
    crash("wish not implemented")
  }
  
  // +peek: read-only queries
  peek(path: Path) -> ?(?(Noun)) {
    switch path {
      /state/version -> [~ ~ version]
      /state/data -> [~ ~ state.data]
      _ -> [~ ~]  // not found
    }
  }
  
  // +poke: state mutations
  poke(cause: Noun) -> (List<Effect>, AppState) {
    let (effects, new_state) = process_cause(state, cause);
    (effects, new_state)
  }
}
```

**Compilation Strategy:**
- Generate door with sample = state
- Battery arms at correct axes (use Hoon `++set` ordering)
- Compile each arm to Nock formula
- Ensure type-correct returns

### 2.2 Essential NockApp Types

From Beta spec, implement these natively:
```jock
alias Tang = List<Chars>
alias Term = Chars

struct Goof {
  mote: Term
  tang: Tang
}

alias Wire = Path

struct Input {
  eny: Uint      // entropy
  our: Hex       // ship identity
  now: Date      // current time
  cause: Noun    // arbitrary cause data
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

**Path Native Syntax (Already Implemented in Beta):**
```jock
let p = /foo/bar/(segment)/baz
let q = /
let r = /users/(user-id as Chars)/profile
```

**Implementation Requirements:**
- Parser support for `/foo/bar` syntax → `List<Chars>`
- Compile to standard Hoon path representation
- Interpolation support: `/(variable)` embeds value
- Type checking: ensure interpolated values are `Chars`-compatible

---

## Phase 3: Urbit Gall Integration

### 3.1 Gall Agent Primitives

**Agent Arms (Beyond Kernel):**
```jock
class GallAgent(state: AgentState) {
  // Kernel interface
  load(old: Noun) -> AgentState { /* ... */ }
  peek(path: Path) -> ?(?(Noun)) { /* ... */ }
  poke(cause: Noun) -> (List<Effect>, AgentState) { /* ... */ }
  
  // Gall-specific
  on_init() -> (List<Effect>, AgentState) {
    // agent initialization
    ([/* cards */], initial_state)
  }
  
  on_watch(path: Path) -> (List<Effect>, AgentState) {
    // subscription handling
    ([/* initial facts */], state)
  }
  
  on_leave(path: Path) -> (List<Effect>, AgentState) {
    // unsubscription handling
    ([], state)
  }
  
  on_agent(wire: Wire, sign: Sign) -> (List<Effect>, AgentState) {
    // agent communication
    match sign {
      poke_ack -> ([], state)
      watch_ack -> ([], state)
      kick -> ([], state)
      fact -> {
        // process fact
        ([], new_state)
      }
    }
  }
  
  on_arvo(wire: Wire, sign: ArvoSign) -> (List<Effect>, AgentState) {
    // Arvo vane interaction
    ([], state)
  }
  
  on_fail(term: Term, tang: Tang) -> (List<Effect>, AgentState) {
    // error handling
    ([], state)
  }
}
```

### 3.2 Effect/Card System

**Basic Card Types:**
```jock
union Card {
  case poke(ship: Ship, agent: Term, mark: Mark, noun: Noun)
  case watch(ship: Ship, agent: Term, path: Path)
  case leave(ship: Ship, agent: Term)
  case give(path: Path, mark: Mark, noun: Noun)
  case pass(wire: Wire, note: Note)
}

union Note {
  case behn(BehnNote)  // timer
  case eyre(EyreNote)  // HTTP
  case gall(GallNote)  // agent
  case clay(ClayNote)  // filesystem
}
```

**Implementation Strategy:**
- Cards compile to standard Urbit card format
- Type checking ensures correct structure
- Helper functions for common patterns

---

## Phase 4: Compiler Optimization

### 4.1 Subject Knowledge Analysis (sKa)

**Problem:** Naive compilation produces verbose Nock with excessive cell allocation.

**Solution:** Track known subject structure to optimize slot access.

**Implementation:**
1. Build subject type during compilation
2. Compute axes statically whenever possible
3. Eliminate redundant subject operations
4. Fold constant expressions

**Example Optimization:**
```jock
let x = 42;
let y = x + 1;
y * 2
```

Naive:
```nock
[8 [1 42] 8 [7 [0 2] 4 0 1] 7 [0 2] [4 4 0 1]]
```

Optimized (with sKa):
```nock
[1 86]  // constant fold: (42 + 1) * 2 = 86
```

### 4.2 Jet Matching

**Problem:** Arithmetic operations beyond increment are slow in Nock.

**Solution:** Emit Nock patterns that match standard jets.

**Standard Jets to Target:**
- `add`, `sub`, `mul`, `div`, `mod` (arithmetic)
- `lent`, `snag`, `weld` (lists)
- `turn`, `roll`, `fold` (higher-order)
- String operations

**Implementation Strategy:**
1. Maintain jet hint database
2. Recognize common patterns in AST
3. Emit Nock with jet hints (opcode 11)
4. Fallback to pure Nock if jet unavailable

---

## Phase 5: Developer Tooling

### 5.1 Language Server Protocol (LSP)

**Essential Features:**
- Syntax highlighting
- Error diagnostics (inline)
- Go-to-definition
- Auto-completion (context-aware)
- Hover documentation
- Rename refactoring

**Implementation Strategy:**
- Separate LSP server binary
- Reuse parser/type checker from jockc
- Incremental compilation for responsiveness
- VSCode extension as reference implementation

### 5.2 Debugger

**Features:**
- Breakpoints in Jock code
- Step through execution
- Inspect subject structure
- View Nock trace
- Time-travel debugging (replay)

**Implementation Strategy:**
- Instrument compiled Nock with debug hints
- Build debugger on top of NockVM
- Interactive REPL with inspection
- Integration with jockc

### 5.3 Package Manager

**Goals:**
- Distribute Jock libraries
- Dependency management
- Version resolution
- Integration with Urbit %yard desks

**Design:**
```
jock.toml:
  [package]
  name = "my-app"
  version = "0.1.0"
  
  [dependencies]
  stdlib = "1.0"
  json = "0.5"

Command:
  jock build
  jock install <package>
  jock publish
```

---

## Phase 6: Standard Library

### 6.1 Core Modules

**collections:**
- `List<T>`: standard list operations
- `Set<T>`: ordered sets
- `Dict<K, V>`: maps/dictionaries
- `Vector<T>`: contiguous arrays (Lagoon ndray)

**string:**
- `Chars` operations: concat, split, trim
- `String` operations: convert to/from list
- Unicode support
- Parsing helpers

**math:**
- Arithmetic traits implementation
- Trig functions (via jets)
- Random number generation (from entropy)

**time:**
- `Date` operations
- `Span` (duration) arithmetic
- Formatting/parsing

**io:**
- HTTP client/server helpers
- File system access (via Clay)
- JSON serialization

**crypto:**
- Hashing (SHA, Blake)
- Signing/verification
- Encryption (AES, ChaCha)

### 6.2 Gall Helpers

**agent-utils:**
- Standard agent template
- Card builders
- Subscription management
- State persistence patterns

**scry:**
- Type-safe scry interface
- Common scry patterns
- Cache management

---

## Phase 7: Testing & Documentation

### 7.1 Test Framework Expansion

**Unit Testing:**
```jock
test "arithmetic" {
  assert 1 + 1 == 2
  assert 5 - 3 == 2
  assert 4 * 3 == 12
}

test "list operations" {
  let xs = [1, 2, 3];
  assert xs.length() == 3
  assert xs.first() == [~ 1]
}
```

**Property Testing:**
```jock
property "addition commutative" {
  forall (a: Atom, b: Atom) {
    a + b == b + a
  }
}
```

**Integration Testing:**
- Full NockApp kernel tests
- Gall agent lifecycle tests
- Network interaction tests

### 7.2 Documentation

**Required Docs:**
- Language reference (complete)
- Standard library API docs
- NockApp guide
- Gall agent tutorial
- Compiler internals (design docs)
- Nock compilation strategy
- Migration guide (Hoon → Jock)

**Doc Generation:**
- Extract from source comments
- Generate markdown/HTML
- Host on docs.jock.org
- Searchable with examples

---

## Implementation Priorities

### P0 (Critical Path - 3 months)
1. Type system overhaul (structs, traits, unions, generics)
2. Path syntax completion
3. NockApp kernel interface
4. Basic standard library (collections, string, math)

### P1 (Production Ready - 3 months)
5. Gall agent primitives
6. Compiler optimization (sKa, basic jet matching)
7. LSP server (basic features)
8. Comprehensive test suite

### P2 (Developer Experience - 3 months)
9. Debugger
10. Package manager
11. Full standard library
12. Complete documentation

### P3 (Nice to Have - 6 months)
13. Advanced optimizations
14. Property testing framework
15. Formal verification tools
16. Visual debugging tools

---

## Technical Constraints & Design Decisions

### Hard Constraints
1. **Subject-oriented compilation:** Every operation must work with Nock's subject model
2. **Binary tree addressing:** All data access via axis notation
3. **Functional purity:** No mutable state at Nock level
4. **Homoiconicity:** Code and data unified as nouns

### Design Principles
1. **Pragmatism over elegance:** Choose solutions that work in production
2. **Explicit over implicit:** Require type annotations where inference is complex
3. **Safety with escape hatches:** Type system enforced, but allow `Noun` escape
4. **Hoon compatibility:** FFI should be seamless and bidirectional
5. **Performance awareness:** Naive compilation acceptable, but provide optimization path

### Known Trade-offs
1. **Monomorphization vs. code size:** Accept code duplication for performance
2. **Explicit typing vs. ergonomics:** Reduce bugs at cost of verbosity
3. **Nock fidelity vs. abstractions:** Stay close to metal, add sugar carefully
4. **Innovation vs. stability:** Beta breaking changes acceptable, then stabilize

---

## Success Criteria

### Beta Release (6 months)
- [ ] Type system complete (structs, traits, unions, generics)
- [ ] NockApp kernel interface working
- [ ] Path syntax implemented
- [ ] Basic standard library
- [ ] 100+ passing tests
- [ ] Documentation 80% complete

### 1.0 Release (12 months)
- [ ] Gall agent support
- [ ] Compiler optimization (sKa)
- [ ] LSP server (basic)
- [ ] Full standard library
- [ ] 500+ passing tests
- [ ] Production apps deployed

### 2.0 Release (18 months)
- [ ] Debugger
- [ ] Package manager
- [ ] Advanced optimizations
- [ ] Property testing
- [ ] Enterprise adoption

---

## Migration Strategy (Hoon → Jock)

### Automated Translation
**Feasible:**
- Basic arithmetic, logic
- Function definitions
- Struct/core definitions
- Simple control flow

**Requires Manual Work:**
- Irregular Hoon syntax (`?:`, `?@`, etc.)
- Complex macros (`=<`, `=^`, etc.)
- Type system edge cases
- Idiomatic patterns

### Translation Tool
```bash
hoon2jock input.hoon > output.jock
```

**Strategy:**
1. Parse Hoon AST (using Hoon parser)
2. Map to Jock AST (semantic translation)
3. Generate Jock source
4. Manual review + cleanup

---

## Risk Mitigation

### Technical Risks
1. **Type system complexity:** Mitigate with staged rollout, extensive testing
2. **Compiler bugs:** Mitigate with property testing, fuzzing, formal methods
3. **Performance issues:** Mitigate with benchmarking, profiling, jet matching
4. **NockApp incompatibility:** Mitigate with integration tests, real-world apps

### Adoption Risks
1. **Learning curve:** Mitigate with tutorials, examples, migration guide
2. **Hoon ecosystem lock-in:** Mitigate with excellent FFI, gradual migration
3. **Tooling gaps:** Mitigate with LSP early, prioritize developer experience
4. **Documentation debt:** Mitigate with docs-first approach, examples in tests

---

## Appendix A: Nock Compilation Patterns

### Function Calls
```jock
func add(a: Atom, b: Atom) -> Atom {
  a + b
}
add(3, 5)
```

Compiles to:
```nock
// Gate construction
[8 [1 0] [1 [4 4 0 1] 0 1] 0 1]
// Slam: [[3 5] gate] -> 8
[9 2 10 [6 7 [0 3] 1 3 5] 0 1]
```

### Recursion
```jock
func factorial(n: Atom) -> Atom {
  if n == 0 {
    1
  } else {
    n * $(n - 1)
  }
}
```

Compiles to:
```nock
// Use $ as recursion point (Nock 9 with axis 2)
[8 [1 n] 
  6 [5 [0 2] 1 0]
    [1 1]
    [4 4 [0 2] [9 2 10 [6 [4 0 6] 0 2] 0 1]]
  0 1]
```

### Loop Constructs
```jock
let a = 43;
let b = 0;
loop;
if a == +(b) {
  b
} else {
  b = +(b);
  recur
}
```

Compiles to:
```nock
[8 [1 43]
 8 [1 0]
 8 [1 0]
 6 [5 [0 6] [4 0 14]]
   [0 14]
   [7 [10 [14 1] 0 1] 9 2 10 [6 1 0] 0 1]
 0 1]
```

---

## Appendix B: Subject Layout Examples

### Simple Function Subject
```jock
let x = 5;
let y = 10;
func add_xy(z: Atom) -> Atom {
  x + y + z
}
```

Subject structure:
```
[battery payload]
  battery: [[add_xy-formula] context]
  payload: [z [y [x prior-subject]]]

Axes:
  +2: battery
  +3: payload (entire)
  +6: z
  +7: [y [x prior-subject]]
  +14: y
  +15: [x prior-subject]
  +30: x
```

### Class Subject
```jock
class Counter(value: Atom) {
  increment(self) -> Counter {
    Counter(self.value + 1)
  }
  
  get(self) -> Atom {
    self.value
  }
}
```

Subject structure:
```
[battery sample]
  battery: [[increment get] ...]
  sample: value (Atom)

Method resolution:
  - Walk to find arm by name
  - Slam with sample
```

---

## Appendix C: Recommended Reading

### Nock & Urbit Fundamentals
- [Nock Definition](https://docs.urbit.org/language/nock/reference/definition)
- [~timluc-miptev: Nock for Everyday Coders](https://blog.timlucmiptev.space/part1.html)
- [Hoon School](https://docs.urbit.org/courses/hoon-school)

### Type Systems
- *Types and Programming Languages* (Pierce)
- *Advanced Topics in Types and Programming Languages* (Pierce)
- Rust documentation (trait system reference)
- Swift documentation (protocol-oriented programming)

### Compiler Design
- *Compilers: Principles, Techniques, and Tools* (Dragon Book)
- *Engineering a Compiler* (Cooper & Torczon)
- LLVM documentation (optimization passes)

### Language Design
- *Structure and Interpretation of Computer Programs* (Abelson & Sussman)
- *Practical Foundations for Programming Languages* (Harper)
- *The Implementation of Functional Programming Languages* (Peyton Jones)

---

## Appendix D: Community & Resources

### Communication Channels
- GitHub Issues: Bug reports, feature requests
- Urbit Groups: Developer discussions
- Twitter/X: @JockNockISA
- Discord: Nockchain community

### Contributing Guidelines
1. Read PHILOSOPHY.md and ROADMAP.md
2. Check existing issues/PRs
3. Small PRs preferred
4. Tests required for new features
5. Documentation required for new syntax

### Code Review Standards
- Compiles without warnings
- Passes all tests
- Maintains type safety
- Follows naming conventions
- Includes documentation
- Performance considerations noted

---

## Conclusion

This spec provides a comprehensive roadmap for completing Jock. The type system overhaul is the critical path, followed by NockApp/Gall integration. With focused effort, Jock can become the practical, production-ready language for Nock development within 12-18 months.

The cypherpunk vision: deterministic computation, formally verifiable code, sovereign infrastructure. Jock is a key enabler.

Let's build something that survives contact with reality.

---

**Document Status:** Living specification, last updated 2025-01-22
**Next Review:** After Beta type system implementation
**Maintainer:** Senior engineering team, community input welcome
