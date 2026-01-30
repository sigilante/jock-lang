# Jock-to-Nock Compilation Quick Reference
## Patterns, Idioms, and Translation Strategies

---

## Fundamental Nock Opcodes

| Op | Name | Form | Meaning |
|----|------|------|---------|
| 0  | Slot | `[0 b]` | Tree address `b` of subject |
| 1  | Constant | `[1 b]` | Literal value `b` |
| 2  | Eval | `[2 b c]` | `*[*[a b] *[a c]]` |
| 3  | Cell? | `[3 b]` | 0 if `*[a b]` is cell, else 1 |
| 4  | Increment | `[4 b]` | `+(*[a b])` |
| 5  | Equal | `[5 b c]` | 0 if `*[a b]` = `*[a c]`, else 1 |
| 6  | If | `[6 b c d]` | `*[a c]` if `*[a b]` is 0, else `*[a d]` |
| 7  | Compose | `[7 b c]` | `*[*[a b] c]` |
| 8  | Push | `[8 b c]` | `*[[*[a b] a] c]` |
| 9  | Call | `[9 b c]` | `*[*[a c] [2 [0 1] [0 b]]]` |
| 10 | Edit | `[10 [b c] d]` | Replace axis `b` with `*[a c]` in `*[a d]` |
| 11 | Hint | `[11 b c]` | Jet hint, compute `*[a c]` |
| 12 | Scry | `[12 b c]` | Mock/scry (not used in JockApps) |

---

## Subject Structure & Axes

```
Tree:     [a b]
Subject:  [battery payload]

Axes:
  1 = entire subject
  2 = head (battery)
  3 = tail (payload)
  
  4 = head of head
  5 = tail of head
  6 = head of tail
  7 = tail of tail
  
  2^n     = nth left (head)
  2^n + 1 = nth right (tail)
```

**Computing Axes:**
- Left: `2 * axis`
- Right: `2 * axis + 1`
- Parent: `axis / 2` (integer division)

**Example Subject:**
```
[battery [arg1 [arg2 [arg3 prior-subject]]]]

+1: entire subject
+2: battery
+3: payload = [arg1 [arg2 [arg3 prior-subject]]]
+6: arg1
+7: [arg2 [arg3 prior-subject]]
+14: arg2
+15: [arg3 prior-subject]]
+30: arg3
+31: prior-subject
```

---

## Variable Binding (Nock 8)

### Simple Let
```jock
let x = 42;
x
```

Compiles to:
```nock
[8 [1 42] [0 2] 0 1]
// [8 b c] = *[[*[a b] a] c]
// b = [1 42] = constant 42
// c = [0 2] = slot 2 (head of extended subject)
// Subject becomes: [42 original-subject]
// +2 = x, +3 = original
```

### Multiple Let Bindings
```jock
let x = 5;
let y = 10;
x + y
```

Compiles to:
```nock
[8 [1 5]
  [8 [1 10]
    [4 4 [0 4] [0 2]]  // add(+4, +2) = add(x, y)
  0 1]
0 1]
// Subject: [10 [5 original]]
// +2 = y, +4 = x
```

---

## Function Definitions (Gates)

### Basic Function
```jock
func add(x: Atom, y: Atom) -> Atom {
  x + y
}
```

Compiles to gate (door with one arm):
```nock
[8 
  [1 0]              // Default sample [0 0]
  [1 
    [6               // Battery: [add-formula context]
      [5 [0 30] 0 31]     // if sample == [0 0] crash
      [0 0]               // then crash
      [4 4 [0 6] [0 7]]   // else add(+6, +7) = add(x, y)
    ]
    0
  ]
  0 1
]

// Gate structure: [battery sample]
// +2 = battery
// +3 = sample = [x y]
// +6 = x
// +7 = y
```

### Function Call (Slam)
```jock
add(3, 5)
```

Compiles to:
```nock
[9 2                    // Call arm at axis +2 (first arm)
  [0 1]                 // of subject (the gate)
  [7 [0 3] [1 3 5]]     // with sample replaced by [3 5]
]

// Full expansion:
[9 2 
  10 [6 [1 3 5] 0 1]    // Edit axis +6 (sample) to [3 5]
  0 1                    // In subject (the gate)
]
```

---

## Recursion ($ buc)

### Recursive Function
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
[8 [1 0]                 // Default sample
  [1 
    [6                   // if-then-else
      [5 [0 6] [1 0]]    // n == 0
      [1 1]              // then 1
      [4 4               // else n *
        [0 6]            // n
        [9 2             // recurse: call self
          10 [6          // with sample replaced
            [4 0 6]      // n - 1
            0 1
          ]
          0 1
        ]
      ]
    ]
    0
  ]
  0 1
]

// $ = "call myself at axis +2"
// Replace sample with new args
// Subject unchanged (gate structure maintained)
```

---

## Control Flow

### If-Then-Else
```jock
if condition {
  then_branch
} else {
  else_branch
}
```

Compiles to:
```nock
[6 
  [/* condition */]     // Test
  [/* then_branch */]   // True path
  [/* else_branch */]   // False path
]
```

### Loop
```jock
let i = 0;
loop;
if i == 10 {
  i
} else {
  i = i + 1;
  recur
}
```

Compiles to:
```nock
[8 [1 0]                // i = 0
  [8 [1 0]              // Loop marker (trap)
    [6                  // if-then-else
      [5 [0 6] [1 10]]  // i == 10
      [0 6]             // then i
      [7                // else
        [10 [6 [4 0 6] 0 1] 0 1]  // i = i + 1
        [9 2 0 1]       // recur (call trap at +2)
      ]
    ]
    0 1
  ]
  0 1
]
```

---

## Data Structures

### Lists
```jock
[1, 2, 3]
```

Compiles to right-nested cells with `~` (null) terminator:
```nock
[1 [2 [3 0]]]  // [1 [2 [3 ~]]]
// 0 represents ~ (null)
```

### List Operations
```jock
// Length
func length<T>(xs: List<T>) -> Atom {
  match xs {
    [] -> 0
    [_, ..tail] -> 1 + length(tail)
  }
}
```

Compiles to:
```nock
[8 [1 0]              // Default sample
  [1
    [6                // Pattern match = if-cell
      [3 [0 6]]       // is cell?
      [1 0]           // empty -> 0
      [4              // else 1 +
        [9 2          // recurse
          10 [6 [0 7] 0 1]  // with tail
          0 1
        ]
      ]
    ]
    0
  ]
  0 1
]
```

### Tuples/Cells
```jock
(1, 2, 3)
```

Compiles to left-nested cells:
```nock
[[1 2] 3]  // or [1 [2 3]], depends on association
```

### Structs
```jock
struct Point { x: Atom, y: Atom }
Point(3, 5)
```

Compiles to door instance:
```nock
[battery [3 5]]
// battery = [constructor field-getters ...]
// sample = [x y] = [3 5]
```

---

## Type System Compilation

### Newtype Wrapper
```jock
struct UserId(Atom)
let id = UserId(42);
```

Compiles to:
```nock
// Same as: [constructor-battery 42]
// Type distinction maintained at compile-time only
// Runtime: just the value in a door
```

### Trait Implementation
```jock
trait Show {
  show(self) -> Chars
}

impl Show for Point {
  show(self) -> Chars {
    "(" + self.x + ", " + self.y + ")"
  }
}
```

Compiles to:
```nock
// Add show arm to Point battery
// Subject structure:
[battery sample]
  battery = [[show-formula] [other-methods]]
  sample = [x y]

// Method call: p.show()
[9 axis-of-show        // Call show arm
  [0 axis-of-p]        // On p instance
]
```

---

## Pattern Matching (Unions)

### Union Definition
```jock
union Option<T> {
  case none
  case some(value: T)
}
```

Compiles to tagged cells:
```nock
// none: [%none ~] = [0x656e6f6e 0]
// some(x): [%some x] = [0x656d6f73 x]
```

### Pattern Match
```jock
match opt {
  none -> 0
  some(x) -> x
}
```

Compiles to:
```nock
[6                      // if-then-else
  [5                    // equality test
    [0 12]              // head of opt (tag)
    [1 %none]           // %none tag
  ]
  [1 0]                 // then 0
  [0 13]                // else tail of opt (value)
]
```

---

## Standard Library Patterns

### Option Chaining
```jock
e?.field
```

Compiles to:
```nock
[6                      // if-then-else
  [3 [0 /* e-axis */]]  // is e a cell? (not ~)
  [0 /* field-axis */]  // then access field
  [1 ~]                 // else ~
]
```

### Default Value
```jock
e ?? default
```

Compiles to:
```nock
[6                      // if-then-else
  [3 [0 /* e-axis */]]  // is e a cell?
  [0 /* e-axis */]      // then e
  [0 /* default-axis */] // else default
]
```

---

## Optimization Patterns

### Constant Folding
```jock
5 + 3
```

**Naive:**
```nock
[4 4 4 4 4 [1 5] [1 3]]  // Multiple increments
```

**Optimized:**
```nock
[1 8]  // Compile-time evaluation
```

### Subject Knowledge Analysis (sKa)
Track known subject structure to compute axes statically:

```jock
let x = 42;
let y = x;
y
```

**Naive:**
```nock
[8 [1 42]
  [8 [0 2]  // y = x (dynamic lookup)
    [0 2]   // return y
  0 1]
0 1]
```

**Optimized (with sKa):**
```nock
[1 42]  // Fold to constant, eliminate bindings
```

### Jet Hints (Nock 11)
```jock
x + y  // Should use addition jet
```

Compiles to:
```nock
[11                     // Hint
  [1 %add]              // Jet hint: use add jet
  [4 4 [0 6] [0 7]]     // Fallback: increment-based add
]
```

---

## NockApp Kernel Patterns

### Kernel Structure
```jock
class Kernel(state: State) {
  load(old: Noun) -> State { /* ... */ }   // +4
  wish(expr: Noun) -> Noun { /* ... */ }   // +10
  peek(path: Path) -> ?(?(Noun)) { /* ... */ }  // +22
  poke(cause: Noun) -> (List<Effect>, State) { /* ... */ }  // +23
}
```

Compiles to door with arms at specific axes:
```nock
[battery sample]
  battery:
    +2: all arms nested
    +4: load
    +10: wish
    +22: peek
    +23: poke
  sample: state
```

### Peek Implementation
```jock
peek(path: Path) -> ?(?(Noun)) {
  match path {
    /version -> [~ ~ version]
    /count -> [~ ~ state.count]
    _ -> [~ ~]  // not found
  }
}
```

Returns:
- `~` = block (not ready)
- `[~ ~]` = permanently not available
- `[~ ~ value]` = success

---

## Common Pitfalls & Solutions

### Pitfall: Incorrect Axis Calculation
**Problem:** Off-by-one in axis arithmetic
**Solution:** Draw subject tree, compute manually, verify

### Pitfall: Subject Loss After Push
**Problem:** After Nock 8, original subject at +3, not +1
**Solution:** Track subject changes carefully

### Pitfall: Recursion Without Sample Update
**Problem:** Infinite loop, same args passed
**Solution:** Use Nock 10 to replace sample before Nock 9

### Pitfall: Missing Crash on Invalid Input
**Problem:** Function continues with bad data
**Solution:** Add `[6 [5 sample default] [0 0] formula]` pattern

### Pitfall: Name Shadowing Confusion
**Problem:** Variable name reused, wrong axis accessed
**Solution:** Use unique names or track scopes explicitly

---

## Debugging Strategies

### 1. Inspect Compiled Nock
Print intermediate Nock before optimization:
```bash
./jockc --debug file.jock
```

### 2. Trace Execution
Use NockVM trace mode:
```bash
NOCK_TRACE=1 ./jockc file.jock
```

### 3. Verify Subject Structure
Add debug print statements that output subject:
```jock
print(this);  // Print entire subject
```

### 4. Test Small Pieces
Compile and test functions in isolation:
```jock
// test-function.jock
func add(x: Atom, y: Atom) -> Atom {
  x + y
}
add(3, 5)
```

### 5. Compare with Hoon
Compile equivalent Hoon, compare Nock:
```hoon
|=  [x=@ y=@]
(add x y)
```

---

## Reference Resources

### Nock Specification
- Official: https://docs.urbit.org/language/nock/reference/definition
- Tutorial: https://blog.timlucmiptev.space/part1.html

### Hoon Reference
- Docs: https://docs.urbit.org/language/hoon
- Guide: https://docs.urbit.org/courses/hoon-school

### Jock Specifics
- Docs: https://docs.jock.org
- Repo: https://github.com/zorp-corp/jock-lang
- Beta spec: See uploaded jock-beta.md

### Tools
- NockVM: https://github.com/zorp-corp/nockchain
- jockc: Jock compiler (build from repo)
- jockt: Test framework (build from repo)

---

## Quick Tips

1. **Always draw the subject tree** before computing axes
2. **Use Nock 8 sparingly** - each push adds complexity
3. **Fold constants aggressively** - don't emit `[1 x]` then `[4 [0 2]]`
4. **Match Hoon patterns** for jet compatibility
5. **Test edge cases**: 0, ~, single-element lists
6. **Read compiled Nock** - it teaches correct patterns
7. **Start simple** - get basic case working, then optimize
8. **Use type checker** - catch errors at compile time
9. **Profile before optimizing** - measure, don't guess
10. **When stuck, consult Hoon** - it's the reference implementation

---

**This is a living document. Update as patterns emerge.**

Last updated: 2025-01-22
