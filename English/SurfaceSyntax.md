# SML (Stack-Map-Loglang) Surface Syntax and Macro Behavior Specification (Macro-Stack Semantics Edition)

> **Design Note**:  
> SML departs from traditional Context-Free Grammars (CFG) and explicit parse trees, adopting a **linear concatenative abstract state machine based on stacks and associative maps**.  
> Evaluation and token scanning strictly follow Reverse Polish Notation (from right to left: **the right end contains base/early inputs, while the left end contains outer/closing directives**).  
> At the surface syntax level, we abstract away underlying λ-expansion details and model each macro as a **macro-level state transition operator** acting deterministically upon the **four core stacks (QN, WT, CM, PR), the scalar focus register (`⟨F⟩`), and entity attribute maps (Maps)**.

---

## Table of Contents
1. [Core Virtual Components and Dataflow Topology](#1-core-virtual-components-and-dataflow-topology)
2. [Entity Generation, Modifier Binding, and Inter-Stack Dynamics (Core Dynamics)](#2-entity-generation-modifier-binding-and-inter-stack-dynamics-core-dynamics)
3. [Mode Control and Generalized Quantifier System (GQ Theory)](#3-mode-control-and-generalized-quantifier-system-gq-theory)
4. [Predicate Frames, Event Reification (Ω), and Relative Clause Penetration](#4-predicate-frames-event-reification-ω-and-relative-clause-penetration)
5. [Tri-Level Orthogonal Negation System](#5-tri-level-orthogonal-negation-system)
6. [Quantifier Closure, Permutation Pipeline, and Quantifier Mapping Macros](#6-quantifier-closure-permutation-pipeline-and-quantifier-mapping-macros)
7. [Cross-Clause Anaphora, Logical Connectives, and Donkey Sentences](#7-cross-clause-anaphora-logical-connectives-and-donkey-sentences)
8. [Scale Semantics (Adjective and Adverb Models)](#8-scale-semantics-adjective-and-adverb-models)
9. [Core Macro Definition Templates (Standard Library)](#9-core-macro-definition-templates-standard-library)

---

## 1. Core Virtual Components and Dataflow Topology

From the perspective of surface syntax, the runtime environment is governed by four core stacks, one monotonic stream, one scalar register, and eight associative property maps:

```text
                    ┌────────────────────────┐
                    │  NM (Number Generator) │
                    └───────────┬────────────┘
                                │ (Allocate fresh unique entity ID: x)
                                ▼
 ┌───────────────────────┐   ┌───────────────────────┐
 │  QN (Quantifier Stack)│   │    WT (Wait Stack)    │
 └───────────┬───────────┘   └───────────┬───────────┘
             │                           │ (Modifier chain exhausted, Rule 2b)
             │                           ▼
             │               ┌───────────────────────┐
             │               │  CM (Component Stack) │ <---> ⟨F⟩ (Focus Register)
             │               └───────────┬───────────┘
             │                           │ (Verb extracts arguments / connectives)
             ▼                           ▼
 ┌───────────────────────────────────────────────────┐
 │     PR (Permutation Stack) & Quantifier Closure    │
 └───────────────────────────────────────────────────┘
```

- **QN (Quantifier Stack / Queue)**: Stores entities that have been declared but **have not yet undergone restricted quantifier closure**. Entities queue here awaiting sequential folding by quantifier macros.
- **WT (Wait Stack)**: Staging buffer for modifier continuations and higher-order operators. Relation macros, quantifier macros, and mode macros reside on WT to form a "continuation chain", receiving entities to configure their attributes or append modifications.
- **CM (Component Stack)**: Holds fully modified entities ready to be consumed as thematic arguments by predicates or connectives, paired with their **thematic participation polarities** in the format `[Polarity, Entity]` (e.g., `True 10` or `False 10`).  
  *(Note: At the underlying physical machine layer, these are stored flat as two adjacent stack slots: the Entity ID on top, and its truth-polarity boolean immediately below it).*
- **PR (Permutation Stack)**: Manages permutation group operations (`Swap`, `Left`, `Right`, `Top`, `Bottom`, etc.), allowing composite quantifier macros to dynamically reorder quantifier closure scopes.
- **`⟨F⟩` (Scalar Focus Register)**: A scalar integer register tracking the entity ID currently undergoing clause closure or serving as the antecedent host of a relative clause (initialized to 0).
- **Property Maps (Maps)**: Each entity ID `x` is bound to an isolated set of attributes:
  - `Imap[x]` (Restrictor): Accumulates intensional modifications, nominal restrictions, and relative clause conditions;
  - `Omap[x]` (Nuclear Scope): Accumulates asserted main predicate propositions;
  - `Qmap[x]` (Quantifier Force): Records the generalized quantifier operator (default: `Exist` / ∃);
  - `Smap[x]` (Base Set): The ontological domain/category of the entity (e.g., `"Cat"`, `"0~1"`, `"Ω"`);
  - `Mmap[x]` (Mode Flag): Boolean value. `True` = Inner mode (writes to Imap), `False` = Outer mode (writes to Omap);
  - `Fmap[x]` (Focus Flag): `True` = Protected relative clause host, `False` = Ordinary argument;
  - `Emap` (Environment Map): Global key-value store for cross-clause pronoun coreference;
  - `Map` (Lexical Frame Dictionary): Global dictionary mapping set-name strings to their corresponding predicate frame macro implementations.

---

## 2. Entity Generation, Modifier Binding, and Inter-Stack Dynamics (Core Dynamics)

### 2.1 Set Macros (Nominal / Entity Bases)
- **Representative Forms**: `S_SetMacro`, `Farmer_SetMacro`, `Donkey_SetMacro`, `Beat_SetMacro`...
- **Macro Behavior**:
  1. Requests a fresh, globally unique entity identifier `x` from `NM`;
  2. Initializes attribute mappings: `Smap[x] ← S`, `Mmap[x] ← True` (default inner mode), `Qmap[x] ← Exist`, `Imap[x] ← #`, `Omap[x] ← #`, `Fmap[x] ← False`;
  3. Pushes `x` **simultaneously onto both QN and WT**;
  4. Once `x` enters WT, it immediately attempts to combine with unsatisfied macros positioned deeper on WT (see 2.3).

### 2.2 Relation Macros (Modifiers / Binary Relations)
- **Representative Forms**: `R_RelationMacro`, `R1_RelationMacro`...
- **Macro Behavior**:
  1. Pushed to the top of WT with an intrinsic boolean polarity parameter (default: `True`);
  2. Acts as a "binary waiting unit" that **must sequentially consume two entities** before triggering concrete actions:
     - **Consumes 1st entity (dependent/modifier y)**: Provided by the set macro written to its **left** (executed subsequently in reverse sequence);
     - **Consumes 2nd entity (head/host z)**: Provided by the host entity situated further to its **left**;
  3. **Injects Relational Formula**:
     Upon binding both entities, the relation is injected based on the host's mode flag `Mmap[z]`:
     - If `Mmap[z] == True` (Inner mode), conjunctively injects the relation into `Imap[z]`;
     - If `Mmap[z] == False` (Outer mode), conjunctively injects the relation into `Omap[z]`;
     - Whether the injected relation carries a negation operator is strictly determined by the relation macro's current boolean polarity (`True` injects `R(α_z, α_y)`, `False` injects `¬R(α_z, α_y)`);
  4. **Release after Binding**: The host entity `z` is pushed back onto WT to drive further potential combinations.

### 2.3 WT Chaining and the CM Return Law (Core Invariant)
The interaction of entities on WT and their eventual migration to CM is governed by two mutually exclusive rules:
- **Continuation Chaining**: If entity `z` at the top of WT finds unfulfilled combining units below it (such as unsaturated relation macros, mode macros, or quantifier macros), `z` is immediately consumed by that unit.
- **Automatic Migration to CM (Return Law)**: When **no further combinable macros remain on WT**, reduction Rule 2b fires. Entity `z` automatically leaves WT and is **pushed onto CM with positive polarity `[True, z]`**. At this point, the entity is officially promoted to an active argument ready to be consumed by predicates or logical connectives.

---

## 3. Mode Control and Generalized Quantifier System (GQ Theory)

SML natively implements Generalized Quantifier Theory (GQ Theory), strictly partitioning an entity's restrictor from its nuclear scope:

```text
Q α ∈ {α ∈ S | Imap}  Omap
```

### 3.1 Mode Control Macros
An entity's `Mmap` specifies whether subsequent relations flow into the restrictor or the nuclear scope:
- **`InnerModeMacro`**: Pushed to WT. Consumes entity `z` and sets `Mmap[z] ← True` (subsequent relations append to Imap).
- **`OuterModeMacro`**: Pushed to WT. Consumes entity `z` and sets `Mmap[z] ← False` (subsequent relations append to Omap).
- **`ModeToggleMacro`**: Pushed to WT. Consumes entity `z` and inverts `Mmap[z]` (`True` ↔ `False`).

### 3.2 Quantifier Macros (Quantifier Assignment & Automatic Mode Toggle)
- **Representative Forms**: `ExistentialMacro`, `UniversalMacro`, `MoreThanHalfMacro`...
- **Macro Behavior**:
  Pushed to WT. Upon combining with entity `z`, it atomically executes two operations:
  1. Updates the quantifier attribute of `z` to the designated generalized quantifier force (`Qmap[z] ← QQ`, e.g., `Exist`, `Forall`, or proportional quantifiers);
  2. **Automatically triggers `ModeToggleMacro`**, logically inverting `Mmap[z]`.
- **Pragmatic Logic**: In natural word order, a noun first absorbs restrictive modifiers under the restrictor (inner mode); the appearance of a quantifier macro not only assigns quantificational force but shifts the entity into outer mode (nuclear scope), routing all subsequent assertions into Omap.

---

## 4. Predicate Frames, Event Reification (Ω), and Relative Clause Penetration

### 4.1 Noun-Verb Parity and Event Reification
In SML, verbs and nouns are completely equalized as unary base set declarations (`:S`) (e.g., `Beat_SetMacro` declares an entity belonging to the concept of "beating"). The verb's thematic frame is dynamically unpacked from `Map` at runtime.  
Executing a full transitive verb predicate is macroscopically equivalent to: **Pure Binary Predicate Macro + Event Set Macro (`Ω:S`)**.

### 4.2 Pure Binary Predicate Macro Execution
When a predicate frame executes, the abstract machine performs the following sequence:
1. **Generates Event Variable**: Declares a fresh event token `e` (`Smap[e] = Ω`) and pushes it onto CM (as `True e`);
2. **Pops Arguments & Checks Release (Core Safety Invariant)**:
   Sequentially pops four arguments from CM (popping their polarity booleans and entity IDs from the physical stack):
   - 1st item: Event token (newly generated `e` and its polarity)
   - 2nd item: Verb concept entity (denoted `x` and its polarity)
   - 3rd item: Subject entity (denoted `v` and its polarity)
   - 4th item: Object entity (denoted `t` and its polarity)
   
   **Relative Clause Release Mechanism (`ReleaseMacro`)**: While popping each argument, the system inspects its `Fmap` flag:
   - **If an argument has `Fmap == True` (indicating it is a protected relative clause host): the system immediately resets `Fmap ← False` and pushes it back onto QN!**
3. **Focus Locking (`FocusMacro`)**:
   Reads the entity ID currently at the top of QN and writes it into the scalar focus register `⟨F⟩`:
   - If Step 2 released an antecedent host back to QN, that host sits at the top of QN, and `⟨F⟩` locks onto it;
   - If no antecedent was released, `⟨F⟩` defaults to locking the event variable `e`.
4. **Injects Thematic Binary Relations**:
   Based on the original polarities popped from CM, three binary relations are injected (injecting negated relations if polarity is `False`):  
   `Object(e, t) ∧ Subject(e, v) ∧ Predicate(e, x)`
5. **CM Focus Return**:
   Upon completing predicate assembly, the entity stored in `⟨F⟩` is **pushed back onto CM with positive polarity `[True, ⟨F⟩]`**.
6. **Thematic Valency Generalization**:
   The workflow above models a **transitive verb (binary predicate)**, consuming 4 items from CM (Event, Predicate Concept, Subject, Object). For an **intransitive verb**, the frame consumes only 3 items (Event, Predicate Concept, Subject) and pairs with a binary permutation mapping macro (such as `QuantMappingMacro_21`); for ditransitive predicates, it consumes 5 items and pairs with a quaternary mapping macro.

### 4.3 Relative Clause Macro and Antecedent Penetration Model
To allow an antecedent host to participate as an argument inside an embedded clause while preventing inner quantifier macros from prematurely closing it, the system uses an "evasion and penetration" cycle:

```text
Antecedent generated (enters QN and WT)
        │
        ▼
RelativeClauseMacro ──────► Sets antecedent Fmap to True, pops and drops it from QN (Evasion)
        │                   (Antecedent remains solely on CM, waiting to enter the embedded clause)
        │
        ▼
Clause Argument Assembly ─► Antecedent participates as a regular CM argument in clause predicate
        │
        ▼
Clause Predicate Runs ────► Triggers ReleaseMacro: detects Fmap == True,
        │                   resets Fmap to False, and pushes antecedent back onto QN!
        │
        ▼
Focus Capture & Return ───► FocusMacro records top of QN (the host) into ⟨F⟩,
                            and pushes ⟨F⟩ as [True, ⟨F⟩] back onto CM for outer clauses
```

- **`RelativeClauseMacro`**: Placed immediately after the antecedent noun. It marks `Fmap[host] ← True` and **forcibly pops and drops the entity from QN**. This shields the host from inner quantifier macros, preventing premature closure.
- **Penetration & Restoration**: After serving as subject or object inside the embedded clause, the host is caught by `ReleaseMacro`, restored to QN, and escorted back to CM via `⟨F⟩`. The antecedent retains its enriched restrictor conditions and resumes participation in the matrix clause.

---

## 5. Tri-Level Orthogonal Negation System

SML decomposes linguistic negation into three physically isolated operations across distinct architectural locations, completely preventing scope drift:

| Negation Type | Macro Identifier | Target Location | Operational Semantics |
| :--- | :--- | :--- | :--- |
| **Constituent Role Negation** | `IntraClauseNegationMacro` | **Top of CM** | Inverts the boolean participation polarity of the argument at the top of CM (`True` ↔ `False`). Negates the thematic relation connecting this argument to the verb (e.g., `¬Subject`, `¬Object`). |
| **Local Modifier Negation** | `LocalNegationMacro` | **Top of WT** | Inverts the intrinsic boolean polarity of the relation or adjective macro at the top of WT. Negates specific attribution relations (e.g., `¬R(z, y)` or `¬Degree_Height`). |
| **Propositional Negation** | `GlobalNegationMacro` | **Top of QN** | Depending on `Mmap` of the entity at the top of QN, applies global negation over its current Imap (in inner mode) or Omap (in outer mode) (`¬Proposition`). |

---

## 6. Quantifier Closure, Permutation Pipeline, and Quantifier Mapping Macros

### 6.1 Quantifier Closure Atomic Operation: `Build !`
The heart of variable closure is the binary variable-folding directive `Build !` (Rule 16):
- Sequentially extracts two entities from the top of QN: **Source Entity B (variable to close)** and **Host Entity A (absorbing domain)**;
- Encapsulates B's base set, restrictor, nuclear scope, and quantifier force into a standard restricted quantifier formula:

```text
Q_B α_B ∈ {α_B ∈ S_B | Imap[B]}  (Omap[B] ∧ ...)
```

- Injects this formula conjunctively into A's Imap or Omap depending on `Mmap[A]`, then **completely deletes all property mappings for Entity B**;
- Entity B leaves QN; its scope is bound strictly within the jurisdiction of Host A.

### 6.2 Permutation Suffixes and Shifted Permutation (`Bottom` Transformation)
In macros such as `QuantMacro_321` or `QuantMappingMacro_321`, the suffix numbers (e.g., `321`) follow a rigorous index-shifting algebra:

1. **Surface Intuition**:  
   The surface permutation tuple `(i_k, ..., i_1)` indicates the relative reordering applied to the **k-th, ..., 1st argument variables located below the top element of QN**;
2. **Underlying Shift Mechanism (`Bottom` Transformation)**:  
   During macro execution, the system applies the `Bottom` instruction (Rule 29) to transform the surface tuple:

```text
Bottom(i_k, ..., i_1) = (1+i_k, ..., 1+i_1, 1)
```

   - The appended trailing `1` ensures that the **newly created host entity (such as event e) is anchored at the top of QN (index 1)**;
   - All other argument indices are shifted by +1. Thus, surface `(3, 2, 1)` dynamically maps to `(4, 3, 2, 1)`, operating across the three arguments and the single host event;
3. **Cascaded Counting Closures**:  
   The number of elements in the suffix corresponds to the nesting depth of Church-Peano lists (e.g., `321` corresponds to `[[[[]]]]`, depth 3), driving the abstract machine to perform 3 consecutive `Build !` closures, sequentially folding the arguments into the host event.

### 6.3 `QuantMacro` vs `QuantMappingMacro`
- **`QuantMacro` (Stationed on WT)**:  
  Resides on WT. Combines with an entity, then directly applies the designated permutation and sequential `Build !` closures to arguments on QN (frequently used for internal closures inside complex noun phrases).
- **`QuantMappingMacro` (Acts on CM Top, Central Bus Operator)**:  
  Triggers directly on the verbal predicate entity currently at the top of CM:
  1. **Unpacks Verb Frame**: Queries `Map` (Rule 17) to execute the predicate macro mapped to that verb (generating event Ω and assembling arguments);
  2. **Consumes PR Pipeline**: If PR contains pre-staged permutation directives (e.g., `SideEffectTopPermMacro`, `SwapPermMacro`), `QuantMappingMacro` **consumes PR first to rewrite the default permutation tuple and counting depth**;
  3. **Cascaded Quantifier Closure**: Applies the final permutation tuple and executes consecutive `Build !` operations to close the clause.

---

## 7. Cross-Clause Anaphora, Logical Connectives, and Donkey Sentences

### 7.1 Cross-Clause Pronoun Anaphora (Upload / Download)
To achieve precise cross-clause pronoun coreference in a linear stream without syntax trees, the system uses `Emap`:
- **`UploadMacro [alias]`**: Reads the entity ID at the **top of CM** and binds it to an alias in `Emap`;
- **`PositiveDownloadMacro [alias]`**: Retrieves that entity ID from `Emap` and pushes it onto CM with positive polarity `[True, ID]`;
- **`NegativeDownloadMacro [alias]`**: Retrieves that entity ID from `Emap` and pushes it onto CM with negative polarity `[False, ID]`.

### 7.2 Logical and Causal Connective Macros
- **`ForwardConnectiveMacro` / `ReverseConnectiveMacro`**:  
  Pulls two locally closed sub-events from CM, declares an overarching connective event Ω, writes connective antecedent/consequent relations, and **automatically executes internal `Build !` closures on both sub-events**.
- **`BareConnectiveMacro` (Deferred Closure)**:  
  **Completely removes internal `Build !` closures**. It solely attaches antecedent and consequent relations between the overarching event and the two sub-events, leaving quantifier closure to be handled externally.

### 7.3 Donkey Sentences Resolution
In classic donkey sentences (*"If every farmer owns a donkey, he beats it"*), closing "donkey" existentially inside the antecedent clause prevents anaphoric binding in the consequent. SML resolves this via **`BareConnectiveMacro` + External Scoping**:
1. **Antecedent Generation**: "Donkey" and "Farmer" are registered with aliases via `UploadMacro`;
2. **Consequent Reference**: The matrix clause reuses both entities via `PositiveDownloadMacro` to assemble the "beat" event;
3. **`BareConnectiveMacro` Attachment**: Links the "own" event and "beat" event as antecedent and consequent of the main event **without triggering local quantifier folding**;
4. **Outer Unified Closure**: Because the entities remain unclosed on QN, outer universal quantifier macros bind both covariants in a unified, overarching restrictor scope.

---

## 8. Scale Semantics (Adjective and Adverb Models)

SML standardizes adjectives and adverbs as binary measurement relations over normalized continuous intervals:

### 8.1 Adjective Macros (Composite Measurement Units)
- **Representative Forms**: `Tall_Macro`, `Heavy_Macro`...
- **Macro Behavior**:  
  An adjective macro is a pre-packaged measurement unit (containing the scale set `0~1:S` and a binary measurement relation `HeightMeasure:R`).  
  When combining with a target entity, it instantiates an internal scale variable `d ∈ 0~1`, establishes the measurement relation, and folds the scale variable into the host's domain.  
  **Self-Closing Property**: Unlike plain `R_RelationMacro`, adjective macros contain an internal `Build !` directive. Upon binding the host entity, the scale variable is folded locally into the host domain; therefore, **no external quantifier macro is needed** to close the scale.

### 8.2 Adverb Macros (Scale Modulators)
Adverb macros act directly on the measurement unit staged on WT:
- **`QuantifierAdverbMacro` (e.g., `UniversalAdverbMacro`)**: Modifies the quantifier force of the scale variable (e.g., to ∀), expressing extreme degree (e.g., "extremely heavy" maps to universal coverage over the scale interval);
- **`AdverbMacro` (e.g., `Adverb1Macro`)**: Applies a functional transformation (`Transform`) to the scale interval set (such as shifting or scaling intervals);
- **Paired with `LocalNegationMacro`**: Inverts the polarity of the measurement relation on WT, directly yielding scale negations (e.g., "not tall" / "not heavy").

---

## 9. Core Macro Definition Templates (Standard Library)

The core standard library macro definitions for SML are listed below (`{}` indicates slots for user-specified constants or lexical tokens):

```sml
Cond_Repeat_Macro:=[!,Apply,!,Apply,!,Apply,λx.λy.λz.[!,If,z,[!,Apply,!,Apply,!,Apply,x,x,y,!,Thaw,y],[]],λx.λy.λz.[!,If,z,[!,Apply,!,Apply,!,Apply,x,x,y,!,Thaw,y],[]]]
Count_Exec_Macro:=[!,Apply,λy.[[!,Apply,λz.[!,If,!,Equal,z,[],False,[True,!,Thaw,z,!,Thaw,y]]],True]]
Count_Repeat_Macro:=[!,Thaw,Cond_Repeat_Macro,!,Thaw,Count_Exec_Macro]
Set_Macro:=[!,Combine,!,{Set:S}]
Rel_Macro:=[!,Back,WT,λy.[!,Back,WT,λz.[!,Combine,!,Back,WT,!,{Rel:R},y,z,!,Lookup,Mmap,z,!,Get,WT]],!,Back,WT,True]
Discard_Macro:=[!,Apply,λz.[]]
Copy_Macro:=[!,Apply,λz.[z,z]]
Constituent_Neg_Macro:=[!,Back,CM,!,Back,CM,!,Not,!,Get,CM,!,Get,CM]
Local_Neg_Macro:=[!,Back,WT,!,Back,WT,!,Not,!,Get,WT,!,Get,WT]
Global_Neg_Macro:=[!,Back,QN,!,Apply,λz.[!,If,!,Lookup,Mmap,z,[!,Insert,Imap,!,Not,!,Lookup,Imap,z,z],[!,Insert,Omap,!,Not,!,Lookup,Omap,z,z]],!,Get,QN]
Upload_Macro:=[!,Upload]
Pos_Download_Macro:=[!,Download,!,Back,CM,True]
Neg_Download_Macro:=[!,Download,!,Back,CM,False]
Rel_Clause_Macro:=[!,Thaw,Discard_Macro,!,Insert,Fmap,True,!,Get,QN]
Inner_Mode_Macro:=[!,Back,WT,λz.[!,Combine,!,Back,WT,!,Insert,Mmap,True,z]]
Outer_Mode_Macro:=[!,Back,WT,λz.[!,Combine,!,Back,WT,!,Insert,Mmap,False,z]]
Toggle_Macro:=[!,Apply,λz.[!,Insert,z,!,Not,!,Lookup,z]]
Mode_Toggle_Macro:=[!,Back,WT,λz.[!,Combine,!,Back,WT,!,Thaw,Toggle_Macro,Mmap,z,z]]
Quant_Macro:=[!,Back,WT,λz.[!,Combine,!,Back,WT,!,Quantify,{Quant:QQ},z],!,Thaw,Mode_Toggle_Macro]
Focus_Macro:=[!,Back,QN,!,Assign,!,Thaw,Copy_Macro,!,Get,QN]
Release_Macro:=[!,Apply,λz.[!,Insert,Fmap,False,z,!,If,!,Lookup,Fmap,z,[!,Back,QN,z],[]]]
Pred_Rel_Macro:=[!,Apply,!,Apply,!,Apply,!,Apply,λw.λx.λy.λz.[!,x,y,z,!,And,!,Equal,!,Use,z,!,Lookup,Mmap,z,w]]
Binary_Pred_Macro:=[!,Back,CM,!,Use,!,Back,CM,True,!,Thaw,Discard_Macro,!,Apply,!,Apply,!,Apply,!,Apply,!,Apply,!,Apply,!,Apply,!,Apply,λs.λt.λu.λv.λw.λx.λy.λz.[!,Thaw,Pred_Rel_Macro,w,{Predicate:R},!,Thaw,Pred_Rel_Macro,u,{Subject:R},v,!,Thaw,Pred_Rel_Macro,s,{Object:R},t,x,z],!,Thaw,Focus_Macro,!,Get,CM,!,Thaw,Release_Macro,!,Get,CM,!,Get,CM,!,Thaw,Release_Macro,!,Get,CM,!,Get,CM,!,Thaw,Release_Macro,!,Get,CM,!,Get,CM,!,Thaw,Release_Macro,!,Get,CM,!,Combine,!,Ω:S]
Quant_Macro:=[!,Back,WT,λw.[!,Combine,!,Back,WT,w,!,Apply,!,Apply,λy.λz.[!,Thaw,Count_Repeat_Macro,[!,Build],z,!,Permute,!,Bottom,y],{Perm},{Count}]]
Quant_Mapping_Macro:=[!,Apply,!,Apply,λy.λz.[!,Thaw,Count_Repeat_Macro,[!,Build],z,!,Permute,!,Bottom,y],!,Traverse,{Perm},{Count},!,Mapping]
Forward_Causal_Macro:=[!,Apply,!,Apply,λy.λz.[!,Thaw,Count_Repeat_Macro,[!,Build],z,!,Permute,!,Bottom,y],!,Traverse,(2,1),[[[]]],!,Back,CM,!,Use,!,Back,CM,True,!,Thaw,Discard_Macro,!,Apply,!,Apply,!,Apply,!,Apply,!,Apply,!,Apply,λu.λv.λw.λx.λy.λz.[!,Thaw,Pred_Rel_Macro,w,{Causal_Antecedent:R},x,!,Thaw,Pred_Rel_Macro,u,{Causal_Consequent:R},v,z],!,Thaw,Focus_Macro,!,Get,CM,!,Thaw,Release_Macro,!,Get,CM,!,Get,CM,!,Thaw,Release_Macro,!,Get,CM,!,Get,CM,!,Thaw,Release_Macro,!,Get,CM,!,Combine,!,Ω:S]
Reverse_Causal_Macro:=[!,Apply,!,Apply,λy.λz.[!,Thaw,Count_Repeat_Macro,[!,Build],z,!,Permute,!,Bottom,y],!,Traverse,(1,2),[[[]]],!,Back,CM,!,Use,!,Back,CM,True,!,Thaw,Discard_Macro,!,Apply,!,Apply,!,Apply,!,Apply,!,Apply,!,Apply,λu.λv.λw.λx.λy.λz.[!,Thaw,Pred_Rel_Macro,w,{Causal_Antecedent:R},x,!,Thaw,Pred_Rel_Macro,u,{Causal_Consequent:R},v,z],!,Thaw,Focus_Macro,!,Get,CM,!,Thaw,Release_Macro,!,Get,CM,!,Get,CM,!,Thaw,Release_Macro,!,Get,CM,!,Get,CM,!,Thaw,Release_Macro,!,Get,CM,!,Combine,!,Ω:S]
Bare_Causal_Macro:=[!,Back,CM,!,Use,!,Back,CM,True,!,Thaw,Discard_Macro,!,Apply,!,Apply,!,Apply,!,Apply,!,Apply,!,Apply,λu.λv.λw.λx.λy.λz.[!,Thaw,Pred_Rel_Macro,w,{Causal_Antecedent:R},x,!,Thaw,Pred_Rel_Macro,u,{Causal_Consequent:R},v,z],!,Thaw,Focus_Macro,!,Get,CM,!,Thaw,Release_Macro,!,Get,CM,!,Get,CM,!,Thaw,Release_Macro,!,Get,CM,!,Get,CM,!,Thaw,Release_Macro,!,Get,CM,!,Combine,!,Ω:S]
Adj_Macro:=[!,Back,WT,λw.[!,Combine,!,Back,WT,!,Build,!,Apply,!,Apply,!,Apply,λx.λy.λz.[!,x,y,w,!,Lookup,Mmap,w,z],!,Get,WT,!,Get,WT,!,Get,WT],!,Back,WT,True,!,{Scale_Set:S},!,Back,WT,{Scale_Rel:R}]
Adv_Macro:=[!,Back,WT,!,Back,WT,!,Back,WT,!,Transform,{Adv:SS},!,Get,WT,!,Get,WT,!,Get,WT]
Quant_Adv_Macro:=[!,Back,WT,!,Back,WT,!,Back,WT,!,Quantify,{Quant:QQ},!,Get,WT,!,Get,WT,!,Get,WT]
Swap_Perm_Macro:=[!,Back,PR,[!,Swap]]
Left_Perm_Macro:=[!,Back,PR,[!,Left]]
Right_Perm_Macro:=[!,Back,PR,[!,Right]]
Top_Perm_Macro:=[!,Back,PR,[!,Top]]
Bottom_Perm_Macro:=[!,Back,PR,[!,Bottom]]
SideEffect_Top_Perm_Macro:=[!,Back,PR,[!,Apply,!,Apply,λy.λz.[!,Top,y,[z]]]]
SideEffect_Bottom_Perm_Macro:=[!,Back,PR,[!,Apply,!,Apply,λy.λz.[!,Bottom,y,[z]]]]
```