# SML (Stack-Map-Loglang) 📐

**[English](#english) | [中文](#中文)**

---

<a id="english"></a>
# SML (English)

> An experimental formal semantic deduction engine and logical language (Loglang) based on an 8-stack, 5-mapping, 1-counter concatenative state machine.

> [!NOTE]
> **STATUS: SPECIFICATION & WORKING PROTOTYPE (v0.99)**  
> SML eliminates the rigid fixed-place structures (`x₁, x₂, ...`) and scope-leakage issues common in loglangs like Lojban. It natively supports **First-Order Restricted Quantification**, **Universal Event Reification (`e ∈ Ω`)**, **Linear Relative Clauses**, **Clausal Event Nominalization**, **Higher-Order Modifier Distribution**, and **Dynamic Donkey-Sentence Anaphora** purely via linear stack reductions and associative maps—completely free of syntactic tree overhead.

---

## 🚀 Overview

Traditional formal semantics (e.g., Montague Grammar) relies heavily on compositional syntax trees and higher-order lambda-calculus λ-reductions. Similarly, classical loglangs (such as Lojban) encode predicate argument places as rigid, predetermined tuple slots (`x₁, x₂, ..., xₙ`), requiring elidable terminators, conversion particles, or awkward relative clauses for local modifications.

**SML (Stack-Map-Loglang)** replaces syntactic trees and fixed place structures with an **8-Stack + 5-Mapping + 1-Counter linear automaton**.

By unifying all nominal concepts into unary sets (`:S`), reifying all actions into first-class events (`e ∈ Ω`), and decomposing all predicates into **Neo-Davidsonian binary relations (`:R`)**, SML establishes a strict algebraic conservation law: **every relational modifier R consumes exactly one entity S (ΔR = ΔS)**. Combined with an integrated **Relation Stack (`RL`)**, a dedicated **Clause Stack (`CL`)**, and an automatic **Debt Counter (`Count`)**, SML enables seamless attachment of arbitrary adjuncts, nested relative clauses, and nominalized propositions without closing delimiters or cross-clause scope leakage.

---

## ✨ Key Features & Concepts (v0.99)

*   **8-Stack + 5-Mapping + 1-Counter State Machine:**  
    Decouples variable generation, active polarity cursors, quantifier scopes, modifier delays, relational frames, relative clause traces, nominal domain constraints, and syntactic debts into specialized linear stacks and key-value maps.
*   **Universal Event Reification (`e ∈ Ω`) & Zero Fixed Places:**  
    Actions are unified as first-class entities in the universe of events (`Ω`). Thematic roles (`Subject:R`, `Object:R`, `Theme:R`, etc.) are attached as universal binary relations, freeing users from memorizing predicate-specific argument indices.
*   **Linear Relative Clauses without Syntax Trees (`CL` & `That`):**  
    Relative clauses (定语从句) are resolved linearly using the Clause Stack (`CL`) and the `That` / `Clause` operators. Host entity variables are safely passed across scope boundaries and substituted into relative clauses without syntactic tree traversals or variable capture.
*   **Clausal Event Nominalization (`Noun` Operator):**  
    Complete propositions and complex event descriptions can be dynamically reified into first-class entity variables typed as `Ω` in `Smap`, allowing entire clauses to serve directly as subjects, objects, or hosts for adjectival modification.
*   **Terminator-Free Modifiers via ΔR = ΔS Conservation:**  
    Every relational link (`Add`) increments `Count` (logging open syntactic debt); core entities (`Deter`) decrement `Count`. This arithmetic balancing allows ad-hoc prepositional and adjectival attachments without closing delimiters (`ku`, `vau`, etc.).
*   **Dual-Track Negation (Propositional vs. Constituent):**  
    *   **Whole-Proposition Negation (`Negation`):** Inverts entire closed relational propositions at the outer matrix level.
    *   **Constituent / Thematic Negation (`Not` + `Judge`):** Flips truth polarity on the active variable cursor (`CM`), negating specific relational edges without scope drift.
*   **Higher-Order Modifier Calculus & Distributive Exchange (`Exchange`):**  
    *   **Adjectives (`Modify`):** Dynamically restrict nominal domains in `Fmap`.
    *   **Adverbs (`For` / `Modify`):** Recursively scale degree dimensions and event properties.
    *   **Composition & Combinators (`Combine` / `Cancel`):** Merges modifiers via higher-order λ-abstractions.
    *   **Distributive Law (`Exchange`):** Realizes `A → (B ∧ C) ≡ (A → B) ∧ (A → C)`, distributing a single adverb across coordinate adjectives.
*   **In-Situ Morphological Derivation (`:F` Transform Words):**  
    Directly transforms base set categories at the map level (e.g., `"Old$"` applied to `Person:S` yields `Old_Person`), providing native morphological derivation without external preprocessors.
*   **Restricted Quantifier Construction (`build` Primitive):**  
    Quantifiers are constructed on demand via:
    $$\text{build}(Q, a, b, S, F, D) \triangleq Q a \in \{b \in S \mid F\} (D)$$
    This cleanly isolates quantifier force (`Qmap`), base domain (`Smap`), and dynamic filter restrictions (`Fmap`).
*   **Dynamic Anaphora & Donkey Sentences:**  
    Registers `Upload` and `Download` interact with the environment map (`Emap`), allowing multi-clause pronouns and donkey-sentence coreferences to resolve cleanly.
*   **Emergent Surface Syntax (Chunking):**  
    While the underlying engine executes right-to-left via LIFO stacks, the surface grammar follows a natural **VSO Head-Initial + Incremental Post-Modification** template:
    $$\mathbf{Chunk} = [\text{Entity:S}] \ + \ [\text{Not}] \ + \ [\text{Quantifier:Q}] \ + \ [\text{Modifiers}\dots]$$

---

## 🏗️ The 8-Stack 5-Map 1-Counter Model

$$\text{State} = \langle \mathbf{IP}, \mathbf{VR}, \mathbf{CM}, \mathbf{QN}, \mathbf{MD}, \mathbf{RL}, \mathbf{CL}, \mathbf{OP}, \text{Count}, \mathbf{Emap}, \mathbf{Qmap}, \mathbf{Smap}, \mathbf{Fmap}, \mathbf{Amap} \rangle$$

### 1. The 8 Stacks (Right end is Top)

| Stack | Identifier | Preset / Initial Top | Description |
| :--- | :--- | :--- | :--- |
| **Input Stack** | **IP** | (User tokens) | Instruction queue holding tokens, macros, and operators awaiting reduction. |
| **Var Stack** | **VR** | `v1 v2 v3 ...` (Infinite) | Infinite stream of fresh, mutually distinct variables. |
| **Component Stack** | **CM** | `Empty` | Active component cursor stack for truth polarities and active variables (`True`, `False`, `v_i`). |
| **Quant Stack** | **QN** | `None` | Active entity queue awaiting quantifier closure (`Build`/`End`). Supports arbitrary permutation `(i_n, ..., i_1)`. |
| **Modifier Stack** | **MD** | `Stop` | Specialized stack for higher-order modifiers, adjectival/adverbial scopes, and delayed composition. |
| **Relation Stack** | **RL** | `Deter` | Manages open thematic roles and predicate barriers (`Deter`, `Absorb`, `Join`). |
| **Clause Stack** | **CL** | `Empty` | Trace memory storing host entity variables for relative clause binding (`That`/`Clause`). |
| **Output Stack** | **OP** | `Empty` | Working memory accumulating derived logical propositions, relations, and AST subtrees. |

### 2. The Syntactic Debt Counter

*   **`Count` (Integer, initial 0):** Tracks unfulfilled relational obligations. Relation macros invoke `Add` (`Count++`), while entity macros invoke `Deter` (`Count--` if active, else push `Deter` barrier to `RL`). This eliminates the need for closing brackets around modifiers.

### 3. The 5 Associative Mappings (Keys are Variables)

| Mapping | Name | Default / Miss Behavior | Purpose |
| :--- | :--- | :--- | :--- |
| **Emap** | Environment Map | Throws Error | Stores dynamic variable registers for coreference (`Upload`/`Download`). |
| **Qmap** | Quantifier Map | Returns ∃ (`Exist`) | Maps bound variables to quantifier force (∀, ∃). |
| **Smap** | Set Map | Throws Error | Maps domain variables to base set categories (e.g., `Farmer`, `Book`, `Ω`). |
| **Fmap** | Formula/Filter Map | Throws Error | Accumulates domain restrictions, relative clause formulas, and degree filters. |
| **Amap** | Association Map | Throws Error | Pairs quantified instance variables (`a`) with domain restriction variables (`b`). |

---

## 💡 Showcase Examples (v0.99 Verified)

### 1. Relative Clauses & Multi-Constraint Nominal Restriction
> *"The old cat that was not given to the child by the farmer and does not like catnip eats fish."*

```text
Input:
End Eat_Macro Binary_Identity_Perm_Clause_Closing_Macro Negation Like_Macro That Ternary_Identity_Perm_Clause_Closing_Macro Negation Give_Macro Farmer_Macro Child_Macro That Cat_Macro Old_Macro Catnip_Macro Fish_Macro

Evaluated Logical Output:
v26∈Ω ∧ (Exist v1∈Fish (Exist v6∈{v7∈Cat |
    v13∈Ω ∧ (Exist v5∈Large_Age (Exist v11∈Age_Is Subject(v11,v7) ∧ Object(v11,v5) ∧ Predicate(v13,v11))) ∧
    v20∈Ω ∧ (Exist v14∈Child (Exist v16∈Farmer (Exist v18∈Give Not(Subject(v18,v16) ∧ Object(v18,v14) ∧ Theme(v18,v7) ∧ Predicate(v20,v18))))) ∧
    v23∈Ω ∧ (Exist v3∈Catnip (Exist v21∈Like Not(Subject(v21,v7) ∧ Object(v21,v3) ∧ Predicate(v23,v21))))}
    (Exist v24∈Eat Subject(v24,v6) ∧ Object(v24,v1) ∧ Predicate(v26,v24)))) v26
```
*Note: `That` pushes the cat variable `v7` onto `CL`, allowing multiple independent relative clauses to safely capture it as their theme/subject.*

### 2. Clausal Event Nominalization & Propositional Objects
> *"There exists an event where the predicate is not discover, the subject is not the child, and the object is not the interesting event of the cat not liking catnip."*

```text
Input:
End Discover_Macro Not Child_Macro Not Ternary_Identity_Perm_Nominalization_Closing_Macro Not Interesting_Macro Negation Like_Macro Cat_Macro Catnip_Macro

Evaluated Logical Output:
v20∈Ω ∧ (Exist v7∈{v9∈Ω |
    (Exist v1∈Catnip (Exist v3∈Cat (Exist v5∈Like Not(Subject(v5,v3) ∧ Object(v5,v1) ∧ Predicate(v9,v5))))) ∧
    v15∈Ω ∧ (Exist v8∈Large_Interest (Exist v13∈Interest_Is Subject(v13,v9) ∧ Object(v13,v8) ∧ Predicate(v15,v13)))}
    (Exist v16∈Child (Exist v18∈Discover Not Subject(v18,v16) ∧ Not Object(v18,v7) ∧ Not Predicate(v20,v18)))) v20
```
*Note: The clausal proposition "the cat does not like catnip" is nominalized into an entity `v7` of type Ω, modified by the adjective "interesting", and consumed as the object of "discover".*

### 3. Higher-Order Adverb Distribution across Coordinate Adjectives
> *"An A-and-very-ly heavy, B-and-very-ly tall person."*

```text
Input:
Person:S Exchange Very_Macro Tall_Macro Adv_B_Macro Heavy_Macro Adv_A_Macro

Evaluated Domain Filter (Fmap for v26):
And_consequent(v39,v38) ∧ And_antecedent(v39,v32) ∧
v38∈Ω ∧ (Exist v2∈Large_Weight (Exist v36∈Weight_Is Subject(v36,v26) ∧ Object(v36,v2) ∧ Predicate(v38,v36))) ∧
v32∈Ω ∧ (Exist v10∈Large_Height (Exist v30∈Height_Is Subject(v30,v26) ∧ Object(v30,v10) ∧ Predicate(v32,v30)))
```

### 4. Localized Spatiotemporal Scoping & Fine-Grained Role Negation
> *"The red team that was not in the west yesterday attacks the blue team that is not in the east today."*

```text
Input:
End Attack_Macro RedTeam_Macro Yesterday_Macro Not At_Macro West_Macro Not At_Macro BlueTeam_Macro Today_Macro Not At_Macro East_Macro Not At_Macro

Evaluated Logical Output:
v15∈Ω ∧ (Exist v1∈East (Exist v3∈Today (Exist v5∈BlueTeam (Exist v7∈West (Exist v9∈Yesterday (Exist v11∈RedTeam (Exist v13∈Attack
    Not At(v5,v3) ∧ Not At(v5,v1) ∧
    Not At(v11,v9) ∧ Not At(v11,v7) ∧
    Subject(v13,v11) ∧ Object(v13,v5) ∧ Predicate(v15,v13)))))))) v15
```

### 5. Dynamic Anaphora & Donkey Sentence with Negation
> *"If a farmer does not give a child a book, the child will not read it."*

```text
Input:
End Then:C Negation Read_Macro Exist Download child Download book Negation Give_Macro Exist Farmer_Macro All Upload child Child_Macro All Upload book Book_Macro All

Evaluated Logical Output:
v13∈Ω ∧ (All v1∈Book (All v3∈Child (All v5∈Farmer (Exist v7∈Give (Exist v10∈Read
    Then_consequent(v13,v12) ∧ Then_antecedent(v13,v9) ∧
    Not(Subject(v10,v3) ∧ Object(v10,v1) ∧ Predicate(v12,v10)) ∧
    Not(Subject(v7,v5) ∧ Object(v7,v3) ∧ Theme(v7,v1) ∧ Predicate(v9,v7))))))) v13
```

### 6. In-Situ Lexical Derivation
> *"Old person (Elder)."*

```text
Input:
"Old$" Person:S

Evaluated State:
Smap (Sets): [("v2", "Old_Person")]
```

---

## 💻 REPL Commands

*   `:r` — Reset automaton state, stacks, and maps (macro definitions are preserved).
*   `:q` — Exit the deduction engine.
*   `// <expr>` — Step-by-step trace mode (prints state transitions across all 8 stacks and 5 maps).
*   `define <Name> := <Expr>` — Define a reusable macro expansion.

---

## 📝 Design & Architecture Notes

The theoretical foundations, formal semantic rules, 8-Stack 5-Map 1-Counter automaton architecture, event reification algebra, and relational reduction calculus of SML were conceived and mathematically designed entirely by **the author**.

The reference implementation was generated with AI assistance based strictly on the author's formal reduction rules, serving as an executable proof of the deduction rules and empirical verification of zero-leakage scoping.

---

<a id="中文"></a>
# SML (中文)

> 基于“八栈五映射一计数器”（8-Stack 5-Map 1-Counter）串接式状态机的形式语义推导引擎与逻辑语言（Loglang）原型。

> [!NOTE]
> **当前状态：形式规范与可用原型 (v0.99)**  
> SML 彻底攻克了传统逻辑语（如 Lojban）饱受诟病的**固定位点结构（`x₁, x₂, ...` 位点记忆负担）**与**修饰语作用域全局泄漏**难题。系统无需句法树，仅依靠线性多栈状态转移、代数计数平衡与关联映射，即可完备支持**一阶受限量词**、**全事件集合本体化（`e ∈ Ω`）**、**定语从句（关系从句）线性绑定**、**主宾语从句（事件名词化）**、**高阶修饰分配递归**、**词法派生**与**动态驴子句照应**。

---

## 🚀 简介

经典形式语义学（如蒙太格语法）高度依赖复杂的句法语义树递归与高阶 λ 规约；而传统逻辑语（如 Lojban）则将多元谓词绑定为固定的位点结构（如 x₁ 到 x₅），导致实词记忆负担极重，且为单个论元添加局部时空修饰或嵌套定语从句时语法繁琐。

**SML (Stack-Map-Loglang)** 提出了全新的**八栈五映射一计数器（8-Stack + 5-Map + 1-Counter）自动机模型**。

系统将全语言的概念统一为单目集合（`:S`），将所有动作统一实体化为事件集合（`Ω`）中的一阶个体（`e ∈ Ω`），并将所有多元谓词拆解为**新大卫森二元关系（`:R`）**。由此建立了一条严密的数学守恒律：**每一个二元修饰关系 R 在拓扑上必然且唯一地要求消费一个实体集合 S（ΔR = ΔS）**。配合**关系栈（`RL`）**、**从句栈（`CL`）**与**债务计数器（`Count`）**，SML 允许自由挂载任意时空修饰、定语从句与主宾语从句，既无需手动书写闭合括号/终止子（Terminator-Free），也彻底杜绝了跨层级作用域污染。

---

## ✨ 核心概念与特性 (v0.99)

*   **八栈五映射一计数器（8-Stack 5-Map 1-Counter）架构:**  
    将变量源、极性游标、量词闭包、输出命题、修饰语计算、关系格框、从句穿透记忆以及修饰债务完全解耦。
*   **全事件集合本体化（`e ∈ Ω`）与消灭固定位点:**  
    事件作为基底集合 `Ω` 中的一阶个体，与普通实体具有同等数学地位。题元角色（`主语:R`, `宾语:R`, `传递物:R` 等）作为全局通用的二元关系自由挂载，使用者无需记忆谓词特有的位点列表。
*   **无需句法树的定语从句线性求解（`CL` 与 `That`）:**  
    通过从句栈 `CL` 与 `That` / `Clause` 算子，被修饰名词的变量可在栈间穿透，并在从句推导完成后通过 `Substitute` 精准代入从句的“空缺位（Trace）”，实现零 AST 开销的定语从句绑定。
*   **事件名词化与从句充当论元（`Noun` 算子）:**  
    完整命题（如“猫不喜欢猫薄荷”）可通过 `Noun` 算子直接降维打包为类型为 `Ω` 的一阶实体变量，直接充当主句的主语、宾语，或接受形容词修饰。
*   **零终止子的修饰吸收律（ΔR = ΔS 计数平衡）:**  
    任何关系修饰（`Add`）都会让 `Count++`（登记语法债务）；而核心实体宏的 `Deter` 会在有债务时代替压栈执行 `Count--`（结清债务），彻底杜绝 Lojban 式的冗余闭合词（如 `ku`, `vau`）。
*   **双轨否定系统（命题全局否定 vs. 题元成分否定）:**  
    *   **命题全局否定（`Negation`）:** 直接对已闭合的关系命题外层取反。
    *   **题元成分否定（`Not` + `Judge`）:** 通过 `CM` 游标翻转局部极性，精准实现具体关系边（如 ¬在(x, y)）的否定，作用域绝不漂移。
*   **高阶修饰语演算与分配律（`Exchange`）:**  
    *   **形容词（`Modify`）:** 动态收缩名词在 `Fmap` 中的受限集合内涵。
    *   **副词（`For` / `Modify`）:** 对程度标尺与事件属性进行高阶函数抽象与连续修饰。
    *   **合并与组合子（`Combine` / `Cancel`）:** 借助高阶 λ-演算合并多个修饰语。
    *   **分配律（`Exchange`）:** 完美实现 `A → (B ∧ C) ≡ (A → B) ∧ (A → C)`，让单个副词自动向并列形容词分支分配。
*   **原位词法派生（`:F` 变换词）:**  
    支持直接在映射层变换基底集合（如 `"老$"` 作用于 `人:S` 得到 `老人`），使语言原生具备词根派生能力。
*   **受限量词构建原语 (`build` Primitive):**  
    统一使用受限量词模板进行语义闭包：
    $$\text{build}(Q, a, b, S, F, D) \triangleq Q a \in \{b \in S \mid F\} (D)$$
    解耦量词力量（`Qmap`）、基底集合（`Smap`）与修饰过滤式（`Fmap`）。
*   **跨从句动态指代与代词照应:**  
    通过 `Upload` 与 `Download` 指令存取环境映射（`Emap`），以图（DAG）的形式优雅解决跨子句论元复用与经典驴子句照应。
*   **高度模块化的人性表层语法（Chunking）:**  
    虽然底层是逆向消费的 LIFO 栈式抽象机，但表层语言呈现出极其自然的 **VSO 动词前置 + 后置渐进限定** 模式：
    $$\mathbf{Chunk} = [\text{实体宏:S}] \ + \ [\text{Not}] \ + \ [\text{量词:Q}] \ + \ [\text{修饰语/从句}\dots]$$

---

## 🏗️ 八栈五映射一计数器自动机模型

$$\text{State} = \langle \mathbf{IP}, \mathbf{VR}, \mathbf{CM}, \mathbf{QN}, \mathbf{MD}, \mathbf{RL}, \mathbf{CL}, \mathbf{OP}, \text{Count}, \mathbf{Emap}, \mathbf{Qmap}, \mathbf{Smap}, \mathbf{Fmap}, \mathbf{Amap} \rangle$$

### 1. 八个线性栈（均以右端为栈顶）

| 栈名称 | 缩写 | 预置栈顶 | 功能说明 |
| :--- | :--- | :--- | :--- |
| **输入栈** | **IP** | (用户输入) | 待处理的 Token 流、宏指令与操作符队列。 |
| **变量栈** | **VR** | `v1 v2 v3 ...` (无穷) | 预置的无穷新鲜变量源。 |
| **成分栈** | **CM** | `空` | 当前活跃成分的真值极性与变量游标栈（`True`, `False`, `v_i`）。 |
| **量化栈** | **QN** | `None` | 论元变量排队栈，暂存等待参与量词闭包（`Build`/`End`）的变量。支持任意置换 `(i_n, ..., i_1)`。 |
| **修饰栈** | **MD** | `Stop` | 专用的修饰语暂存区，维护形容词、副词的作用域与延迟合成。 |
| **关系栈** | **RL** | `Deter` | 维护当前未闭合的题元角色与关系定界屏障（`Deter`, `Absorb`, `Join`）。 |
| **从句栈** | **CL** | `空` | 专用于关系从句（定语从句）的宿主实体变量追踪栈（`That`/`Clause`）。 |
| **输出栈** | **OP** | `空` | 逻辑命题工作区，累加推导中的中间关系项与最终逻辑公式。 |

### 2. 语法债务计数器

*   **`Count` (整数，初值 0):** 实时追踪当前悬挂的二元修饰关系债务。遇到关系宏执行 `Add`（`Count++`）；遇到实体宏执行 `Deter`（若 `Count > 0` 则消费债务 `Count--`，否则正常压入 `Deter` 隔离屏障）。

### 3. 五个关联映射（键均为变量名）

| 映射表 | 对应全称 | 缺省行为 (Lookup Miss) | 用途说明 |
| :--- | :--- | :--- | :--- |
| **Emap** | 环境映射 (Environment) | 报错 (Error) | 记录动态变量别名，用于代词照应（`Upload`/`Download`）。 |
| **Qmap** | 量化映射 (Quantifier) | 缺省为 ∃ (`Exist`) | 绑定量化变量的量词属性（∀, ∃）。 |
| **Smap** | 集合映射 (Set) | 报错 (Error) | 记录变量所属的基底类别（如 `农夫`, `书`, `Ω`）。 |
| **Fmap** | 表达式映射 (Filter) | 报错 (Error) | 累积形容词收缩条件、定语从句约束与程度过滤器。 |
| **Amap** | 关联变量映射 (Association)| 报错 (Error) | 将量化实体变量 (a) 与其定义域限制变量 (b) 关联。 |

---

## 💡 典型例句推导展示 (v0.99 核实)

### 1. 多重定语从句与复合名词内涵收缩
> *“不是农夫给小孩的、不喜欢猫薄荷的老猫吃鱼”*

```text
输入 (Input):
End 吃宏 二元恒等排列从句结语宏 Negation 喜欢宏 That 三元恒等排列从句结语宏 Negation 给宏 农夫宏 小孩宏 That 猫宏 老的宏 猫薄荷宏 鱼宏

推导逻辑输出 (Output):
v26∈Ω ∧ (Exist v1∈鱼 (Exist v6∈{v7∈猫 |
    v13∈Ω ∧ (Exist v5∈较大的年龄 (Exist v11∈年龄为 主语(v11,v7) ∧ 宾语(v11,v5) ∧ 谓语(v13,v11))) ∧
    v20∈Ω ∧ (Exist v14∈小孩 (Exist v16∈农夫 (Exist v18∈给 Not(主语(v18,v16) ∧ 宾语(v18,v14) ∧ 传递物(v18,v7) ∧ 谓语(v20,v18))))) ∧
    v23∈Ω ∧ (Exist v3∈猫薄荷 (Exist v21∈喜欢 Not(主语(v21,v7) ∧ 宾语(v21,v3) ∧ 谓语(v23,v21))))}
    (Exist v24∈吃 主语(v24,v6) ∧ 宾语(v24,v1) ∧ 谓语(v26,v24)))) v26
```
*注：`That` 算子将被修饰词“猫”的变量 `v7` 压入 `CL` 栈，使两个独立的否定定语从句能够精准将其捕获为传递物与主语。*

### 2. 完整事件名词化（主/宾语从句具象化）
> *“存在事件，谓语不是发现，主语不是小孩，宾语不是‘猫不喜欢猫薄荷’这件有趣的事”*

```text
输入 (Input):
End 发现宏 Not 小孩宏 Not 三元恒等排列名词化结语宏 Not 有趣的宏 Negation 喜欢宏 猫宏 猫薄荷宏

推导逻辑输出 (Output):
v20∈Ω ∧ (Exist v7∈{v9∈Ω |
    (Exist v1∈猫薄荷 (Exist v3∈猫 (Exist v5∈喜欢 Not(主语(v5,v3) ∧ 宾语(v5,v1) ∧ 谓语(v9,v5))))) ∧
    v15∈Ω ∧ (Exist v8∈较大的趣味 (Exist v13∈趣味为 主语(v13,v9) ∧ 宾语(v13,v8) ∧ 谓语(v15,v13)))}
    (Exist v16∈小孩 (Exist v18∈发现 Not 主语(v18,v16) ∧ Not 宾语(v18,v7) ∧ Not 谓语(v20,v18)))) v20
```
*注：命题“猫不喜欢猫薄荷”被 `Noun` 算子实体化为类型为 Ω 的变量 `v7`，进而接受形容词“有趣的”修饰，并作为“发现”的宾语。*

### 3. 并列形容词的高阶副词分配律
> *“A且非常地重的、B且非常地高的人”*

```text
输入 (Input):
人:S Exchange 非常的宏 高的宏 B副词宏 重的宏 A副词宏

推导集合内涵输出 (Fmap 对应 v26):
And_consequent(v39,v38) ∧ And_antecedent(v39,v32) ∧
v38∈Ω ∧ (Exist v2∈较大的重量 (Exist v36∈重量为 主语(v36,v26) ∧ 宾语(v36,v2) ∧ 谓语(v38,v36))) ∧
v32∈Ω ∧ (Exist v10∈较大的高度 (Exist v30∈高度为 主语(v30,v26) ∧ 宾语(v30,v10) ∧ 谓语(v32,v30)))
```

### 4. 局部时空精准界定与细粒度题元否定
> *“不在昨天的不在西边的红队攻击不在今天的不在东边的蓝队”*

```text
输入 (Input):
End 攻击宏 红队宏 昨天宏 Not 在宏 西边宏 Not 在宏 蓝队宏 今天宏 Not 在宏 东边宏 Not 在宏

推导逻辑输出 (Output):
v15∈Ω ∧ (Exist v1∈东边 (Exist v3∈今天 (Exist v5∈蓝队 (Exist v7∈西边 (Exist v9∈昨天 (Exist v11∈红队 (Exist v13∈攻击
    Not 在(v5,v3) ∧ Not 在(v5,v1) ∧
    Not 在(v11,v9) ∧ Not 在(v11,v7) ∧
    主语(v13,v11) ∧ 宾语(v13,v5) ∧ 谓语(v15,v13)))))))) v15
```

### 5. 动态代词照应与带否定的经典驴子句
> *“农民不给小孩书，小孩就不会读它。”*

```text
输入 (Input):
End 就:C Negation 读宏 Exist Download child Download book Negation 给宏 Exist 农夫宏 All Upload child 小孩宏 All Upload book 书宏 All

推导逻辑输出 (Output):
v13∈Ω ∧ (All v1∈书 (All v3∈小孩 (All v5∈农夫 (Exist v7∈给 (Exist v10∈读
    就_consequent(v13,v12) ∧ 就_antecedent(v13,v9) ∧
    Not(主语(v10,v3) ∧ 宾语(v10,v1) ∧ 谓语(v12,v10)) ∧
    Not(主语(v7,v5) ∧ 宾语(v7,v3) ∧ 传递物(v7,v1) ∧ 谓语(v9,v7))))))) v13
```

### 6. 原位词法派生
> *“老人”*

```text
输入 (Input):
"老$" 人:S

推导状态输出 (Smap):
Smap (Sets): [("v2", "老人")]
```

---

## 💻 交互式环境 (REPL)

*   `:r` — 重置自动机状态、栈与映射（保留已加载的宏）。
*   `:q` — 退出推导引擎。
*   `// <expr>` — 单步跟踪模式（逐步打印全系统 8 栈 5 映射的状态流转）。
*   `define <名称> := <表达式>` — 注册全局宏定义。

---

## 📝 关于设计与实现

SML 的理论基石、形式语义规则体系、“八栈五映射一计数器”自动机架构、事件实体化代数以及关系消解演算均由**作者本人**独立构思并完成严格的数学化定义。

参考代码由作者提供精确的状态转移规范并借助 AI 辅助生成，作为可执行的语义虚拟机，验证了所有规约规则的自洽性与无泄漏修饰的工程可行性。
