# SML (Stack-Map-Loglang) 📐

**[English](#english) | [中文](#中文)**

---

<a id="english"></a>
# SML (English)

> An experimental formal semantic deduction engine and logical language (Loglang) based on a 7-stack, 5-mapping, 1-counter concatenative state machine.

> [!NOTE]
> **STATUS: SPECIFICATION & WORKING PROTOTYPE (v0.9)**  
> SML eliminates the rigid fixed-place structures ($x_1, x_2, \dots$) and scope-leakage issues common in loglangs like Lojban. It enables first-order restricted quantification, localized spatiotemporal scoping, higher-order modifier distribution, and dynamic donkey-sentence anaphora purely via linear stack reductions and associative maps without syntactic tree overhead.

---

## 🚀 Overview

Traditional formal semantics (e.g., Montague Grammar) relies heavily on compositional syntax trees and rigid lambda-calculus $\beta$-reductions. Similarly, classical loglangs (such as Lojban) encode predicate argument places as rigid, predetermined tuple slots ($x_1, x_2, \dots, x_n$), requiring elidable terminators, conversion particles, or awkward relative clauses for local modifications.

**SML (Stack-Map-Loglang)** replaces syntactic trees and fixed place structures with a **7-Stack + 5-Mapping + 1-Counter linear automaton**.

By unifying all content concepts into unary sets (`:S`) and decomposing all predicates into **Neo-Davidsonian binary relations (`:R`)**, SML achieves a strict algebraic conservation law: **every relational modifier $R$ consumes exactly one entity $S$ ($\Delta R = \Delta S$)**. Combined with an integrated **Relation Stack (`RL`)** and an automatic **Debt Counter (`Count`)**, SML permits dynamic attachment of arbitrary adjuncts (time, space, degree) to individual terms without terminator tokens, argument position confusion, or cross-clause scope leakage.

---

## ✨ Key Features & Concepts (v0.9)

*   **7-Stack + 5-Mapping + 1-Counter State Machine:**  
    Decouples variable generation, active predicate cursors, quantifier scopes, modifier delays, relational frames, and nominal domain constraints into specialized linear stacks and key-value maps.
*   **No Fixed Place Structures (Universal Binary Decomposition):**  
    Predicates are reified into event entities ($\Omega(e)$), with arguments attached via universal deep semantic relations (`Subject:R`, `Object:R`, `Theme:R`, etc.). Users do not memorize predicate-specific argument indices.
*   **Terminator-Free Modifiers via $\Delta R = \Delta S$ Conservation:**  
    Every relational link (`Add`) increments `Count`, signaling open relational debt. Core entities (`Deter`) decrement `Count`. This arithmetic balancing allows ad-hoc prepositional and adjectival attachments without closing delimiters (`ku`, `vau`, etc.).
*   **Dual-Track Negation (Propositional vs. Constituent):**  
    *   **Whole-Proposition Negation (`Negation`):** Inverts entire closed relational propositions at the outer matrix level.
    *   **Constituent / Thematic Negation (`Not` + `Judge`):** Flips truth polarity on the active variable cursor (`VM`), negating specific relational edges without scope drift.
*   **Higher-Order Modifier Calculus & Distributive Exchange (`Exchange`):**  
    *   **Adjectives (`Modify`):** Dynamically restrict nominal domains in `Fmap`.
    *   **Adverbs (`For` / `Modify`):** Recursively scale degree dimensions and event properties.
    *   **Composition & Combinators (`Combine` / `Cancel`):** Merges modifiers via higher-order $\lambda$-abstractions.
    *   **Distributive Law (`Exchange`):** Realizes $A \to (B \wedge C) \equiv (A \to B) \wedge (A \to C)$, distributing a single adverb across coordinate adjectives.
*   **Restricted Quantifier Construction (`build` Primitive):**  
    Quantifiers are constructed on demand via:
    $$\text{build}(Q, a, b, S, F, D) \triangleq Q a \in \{b \in S \mid F\} (D)$$
    This cleanly isolates quantifier force (`Qmap`), base domain (`Smap`), and dynamic filter restrictions (`Fmap`).
*   **Dynamic Anaphora & Discourse Coreference:**  
    Registers `Upload` and `Download` interact with the environment map (`Emap`), allowing multi-clause pronouns and donkey-sentence coreferences to resolve cleanly.
*   **Emergent Human-Friendly Surface Syntax (Chunking):**  
    While the underlying engine executes right-to-left via LIFO stacks, the surface grammar follows a natural **VSO Head-Initial + Incremental Post-Modification** template:
    $$\mathbf{Chunk} = [\text{Entity:S}] \ + \ [\text{Not}] \ + \ [\text{Quantifier:Q}] \ + \ [\text{Modifiers}\dots]$$

---

## 🏗️ The 7-Stack 5-Map 1-Counter Model

$$\text{State} = \langle \mathbf{IP}, \mathbf{VU}, \mathbf{VM}, \mathbf{VL}, \mathbf{OP}, \mathbf{MD}, \mathbf{RL}, \text{Count}, \mathbf{Emap}, \mathbf{Qmap}, \mathbf{Smap}, \mathbf{Fmap}, \mathbf{Amap} \rangle$$

### 1. The 7 Stacks (Right end is Top)

| Stack | Identifier | Description |
| :--- | :--- | :--- |
| **Input Stack** | **IP** | Instruction queue holding tokens, macros, and operators awaiting reduction. |
| **Var Upper Stack** | **VU** | Infinite stream of fresh variables (`v1, v2, v3, ...`). |
| **Var Middle Stack** | **VM** | Active variable cursor stack for judgments and truth polarities (`Judge`, `True`, `False`). |
| **Var Lower Stack** | **VL** | Scope queue recording active entities for relational binding and quantifier closure (`Build`/`End`). Supports arbitrary permutation `(i_n, ..., i_1)`. |
| **Output Stack** | **OP** | Working memory accumulating derived logical propositions, relations, and AST subtrees. |
| **Modifier Stack** | **MD** | Specialized stack for higher-order modifiers, adjectival/adverbial scopes, and delayed composition. |
| **Relation Stack** | **RL** | Manages open thematic roles and predicate barriers (`Deter`, `Absorb`, `Join`). |

### 2. The Syntactic Debt Counter

*   **`Count` (Integer):** Tracks unfulfilled relational obligations. Relation macros invoke `Add` (`Count++`), while entity macros invoke `Deter` (`Count--` if active, else push `Deter` barrier to `RL`). This eliminates the need for closing brackets around modifiers.

### 3. The 5 Associative Mappings (Keys are Variables)

| Mapping | Name | Default / Miss Behavior | Purpose |
| :--- | :--- | :--- | :--- |
| **Emap** | Environment Map | Throws Error | Stores dynamic variable registers for coreference (`Upload`/`Download`). |
| **Qmap** | Quantifier Map | Returns ∃ (`Exist`) | Maps bound variables to quantifier force ($\forall, \exists$). |
| **Smap** | Set Map | Throws Error | Maps domain variables to base set categories (e.g., `Farmer`, `Book`, `Eat`). |
| **Fmap** | Formula/Filter Map | Throws Error | Accumulates domain restrictions, local spatiotemporal relations, and degree filters. |
| **Amap** | Association Map | Throws Error | Pairs quantified instance variables (`a`) with domain restriction variables (`b`). |

---

## 💡 Showcase Examples (v0.9 Verified)

### 1. Higher-Order Adverb Distribution across Coordinate Adjectives
> *"An A-and-very-ly heavy, B-and-very-ly tall person."*

```text
Input:
Person:S Exchange Very_Macro Tall_Macro Adv_B_Macro Heavy_Macro Adv_A_Macro

Evaluated Domain Filter (Fmap for v20):
And_consequent(v29,v28) ∧ And_antecedent(v29,v24) ∧
Ω(v28) ∧ (Exist v25∈{v2∈Large_Weight |
    Ω(v6) ∧ (Exist v3∈Adv_A_Set (Exist v4∈Adv_A_Predicate Subject(v4,v2) ∧ Object(v4,v3) ∧ Predicate(v6,v4))) ∧
    Ω(v18) ∧ (Exist v15∈Large_Degree (Exist v16∈Degree_Is Subject(v16,v2) ∧ Object(v16,v15) ∧ Predicate(v18,v16)))}
    (Exist v26∈Weight_Is Subject(v26,v20) ∧ Object(v26,v25) ∧ Predicate(v28,v26))) ∧
Ω(v24) ∧ (Exist v21∈{v8∈Large_Height |
    Ω(v12) ∧ (Exist v9∈Adv_B_Set (Exist v10∈Adv_B_Predicate Subject(v10,v8) ∧ Object(v10,v9) ∧ Predicate(v12,v10))) ∧
    Ω(v18) ∧ (Exist v15∈Large_Degree (Exist v16∈Degree_Is Subject(v16,v8) ∧ Object(v16,v15) ∧ Predicate(v18,v16)))}
    (Exist v22∈Height_Is Subject(v22,v20) ∧ Object(v22,v21) ∧ Predicate(v24,v22)))
```
*Note: A single `Very_Macro` with `Exchange` is automatically distributed to both `Heavy` and `Tall` sub-domains.*

### 2. Whole-Proposition Negation vs. Atomic Predication
> *"The cat does not eat the fish (under a certain quantification)."*

```text
Input:
End Negation Eat_Macro Cat_Macro Fish_Macro

Evaluated Logical Output:
Ω(v7) ∧ (Exist v1∈Fish (Exist v3∈Cat (Exist v5∈Eat
    Not(Subject(v5,v3) ∧ Object(v5,v1) ∧ Predicate(v7,v5))))) v7
```

### 3. Localized Spatiotemporal Scoping & Constituent Negation
> *"The red team that was not in the west yesterday attacks the blue team that is not in the east today."*

```text
Input:
End Attack_Macro RedTeam_Macro Yesterday_Macro Not At_Macro West_Macro Not At_Macro BlueTeam_Macro Today_Macro Not At_Macro East_Macro Not At_Macro

Evaluated Logical Output:
Ω(v15) ∧ (Exist v1∈East (Exist v3∈Today (Exist v5∈BlueTeam (Exist v7∈West (Exist v9∈Yesterday (Exist v11∈RedTeam (Exist v13∈Attack
    Not At(v5,v3) ∧ Not At(v5,v1) ∧
    Not At(v11,v9) ∧ Not At(v11,v7) ∧
    Subject(v13,v11) ∧ Object(v13,v5) ∧ Predicate(v15,v13)))))))) v15
```

### 4. Dynamic Anaphora & Donkey Sentence with Negation
> *"If a farmer does not give a child a book, the child will not read it."*

```text
Input:
End Then:C Negation Read_Macro Exist Download child Download book Negation Give_Macro Exist Farmer_Macro All Upload child Child_Macro All Upload book Book_Macro All

Evaluated Logical Output:
Ω(v13) ∧ (All v1∈Book (All v3∈Child (All v5∈Farmer (Exist v7∈Give (Exist v10∈Read
    Then_consequent(v13,v12) ∧ Then_antecedent(v13,v9) ∧
    Not(Subject(v10,v3) ∧ Object(v10,v1) ∧ Predicate(v12,v10)) ∧
    Not(Subject(v7,v5) ∧ Object(v7,v3) ∧ Theme(v7,v1) ∧ Predicate(v9,v7))))))) v13
```

### 5. Multi-Level Recursive Adverbs & Adverb Merging
> *"An A-and-E-ly B-ly, C-and-E-ly D-ly heavy person."*

```text
Input:
Person:S Heavy_Macro Adv_Exchange_Macro Adv_E_Macro Adv_Combine_Cancel_Macro Adv_D_Macro Adv_C_Macro Cancel Adv_B_Macro Adv_A_Macro

Evaluated Domain Filter (Fmap for v30):
Ω(v34) ∧ (Exist v31∈{v19∈Large_Weight |
    And_consequent(v28,v27) ∧ And_antecedent(v28,v23) ∧
    Ω(v27) ∧ (Exist v24∈{v2∈Adv_B_Set | ...} (Exist v25∈Adv_B_Predicate Subject(v25,v19) ∧ Object(v25,v24) ∧ Predicate(v27,v25))) ∧
    Ω(v23) ∧ (Exist v20∈{v8∈Adv_D_Set | ...} (Exist v21∈Adv_D_Predicate Subject(v21,v19) ∧ Object(v21,v20) ∧ Predicate(v23,v21)))}
    (Exist v32∈Weight_Is Subject(v32,v30) ∧ Object(v32,v31) ∧ Predicate(v34,v32)))
```

---

## 💻 REPL Commands

*   `:r` — Reset automaton state, stacks, and maps (macro definitions are preserved).
*   `:q` — Exit the deduction engine.
*   `// <expr>` — Step-by-step trace mode (prints state transitions across all 7 stacks and 5 maps).
*   `define <Name> := <Expr>` — Define a reusable macro expansion.

---

## 📝 Design & Architecture Notes

The theoretical foundations, formal semantic rules, 7-Stack 5-Map 1-Counter automaton architecture, and relational reduction calculus of SML were conceived and mathematically designed entirely by **the author**.

The reference Haskell implementation (`Main.hs`) was generated with AI assistance (specifically the token parser and state transition boilerplate) based strictly on the author's formal reduction rules, serving as an executable proof of the deduction rules and empirical verification of zero-leakage scoping.

---

<a id="中文"></a>
# SML (中文)

> 基于“七栈五映射一计数器”（7-Stack 5-Map 1-Counter）串接式状态机的形式语义推导引擎与逻辑语言（Loglang）原型。

> [!NOTE]
> **当前状态：形式规范与可用原型 (v0.9)**  
> SML 彻底攻克了传统逻辑语（如 Lojban）饱受诟病的**固定位点结构（$x_1, x_2, \dots$ 位点记忆负担）**与**时空修饰语全局泄漏**难题。系统无需句法树，仅依靠线性多栈状态转移、代数计数平衡与关联映射，即可完成一阶受限量词、局部时空界定、高阶修饰分配递归与动态驴子句照应的无歧义形式化推导。

---

## 🚀 简介

经典形式语义学（如蒙太格语法）高度依赖复杂的句法语义树递归与类型驱动的 $\lambda$ 规约；而传统逻辑语（如 Lojban）则将多元谓词绑定为固定的位点结构（如 $x_1$ 到 $x_5$），导致实词记忆负担极重，且为单个论元添加局部时空修饰时语法冗长繁琐。

**SML (Stack-Map-Loglang)** 提出了全新的**七栈五映射一计数器（7-Stack + 5-Map + 1-Counter）自动机模型**。

系统将全语言的概念统一为单目集合（`:S`），将所有多元谓词拆解为**新大卫森二元关系（`:R`）**。由此建立了一条严密的数学守恒律：**每一个二元修饰关系 $R$ 在拓扑上必然且唯一地要求消费一个实体集合 $S$（$\Delta R = \Delta S$）**。配合新引入的**关系栈（`RL`）**与**债务计数器（`Count`）**，SML 允许自由、动态地为主句论元挂载任意时空与属性修饰，既无需手动书写闭合括号/终止子（Terminator-Free），也彻底杜绝了时空修饰语跨层级污染的问题。

---

## ✨ 核心概念与特性 (v0.9)

*   **七栈五映射一计数器（7-Stack 5-Map 1-Counter）架构:**  
    将变量流、极性游标、量词闭包、输出命题、修饰语计算、关系格框以及修饰债务完全解耦。
*   **彻底消灭固定位点（全二元关系降维）:**  
    动作与谓词通过 `Event` 算子实体化为事件个体（$\Omega(e)$），题元角色（`主语:R`, `宾语:R`, `传递物:R` 等）作为全局通用的二元关系自由挂载，使用者无需记忆每个动词私有的位点列表。
*   **零终止子的修饰吸收律（$\Delta R = \Delta S$ 计数平衡）:**  
    任何关系修饰（`Add`）都会让 `Count++`（登记语法债务）；而核心实体宏的 `Deter` 会在有债务时代替压栈执行 `Count--`（结清债务）。这使得论元修饰语可以随写随走，不再需要 Lojban 中冗余的闭合词（如 `ku`, `vau`, `ge'u`）。
*   **双轨否定系统（命题全局否定 vs. 题元成分否定）:**  
    *   **命题全局否定（`Negation`）:** 直接对已闭合的关系命题外层取反（$\neg(\text{主语}\wedge\text{宾语}\wedge\text{谓语})$）。
    *   **题元成分否定（`Not` + `Judge`）:** 通过 `VM` 游标翻转局部极性，精准实现具体关系边（如 $\neg\text{在}(x, y)$）的否定，作用域绝不漂移。
*   **高阶修饰语演算与分配律（`Exchange`）:**  
    *   **形容词（`Modify`）:** 动态收缩名词在 `Fmap` 中的受限集合内涵。
    *   **副词（`For` / `Modify`）:** 对程度标尺与事件属性进行高阶函数抽象与连续修饰。
    *   **合并与组合子（`Combine` / `Cancel`）:** 借助高阶 $\lambda$-演算合并多个修饰语。
    *   **分配律（`Exchange`）:** 完美实现 $A \to (B \wedge C) \equiv (A \to B) \wedge (A \to C)$，让单个副词自动向并列形容词分支分配。
*   **受限量词构建原语 (`build` Primitive):**  
    统一使用受限量词模板进行语义闭包：
    $$\text{build}(Q, a, b, S, F, D) \triangleq Q a \in \{b \in S \mid F\} (D)$$
    解耦量词力量（`Qmap`）、基底集合（`Smap`）与修饰过滤式（`Fmap`）。
*   **跨从句动态指代与代词照应:**  
    通过 `Upload` 与 `Download` 指令存取环境映射（`Emap`），以图（DAG）的形式优雅解决跨子句论元复用与经典驴子句照应。
*   **高度模块化的人性表层语法（Chunking）:**  
    虽然底层是逆向消费的 LIFO 栈式抽象机，但表层语言呈现出极其自然的 **VSO 动词前置 + 后置渐进限定** 模式：
    $$\mathbf{Chunk} = [\text{实体宏:S}] \ + \ [\text{Not}] \ + \ [\text{量词:Q}] \ + \ [\text{形容词/副词修饰语}\dots]$$

---

## 🏗️ 七栈五映射一计数器自动机模型

$$\text{State} = \langle \mathbf{IP}, \mathbf{VU}, \mathbf{VM}, \mathbf{VL}, \mathbf{OP}, \mathbf{MD}, \mathbf{RL}, \text{Count}, \mathbf{Emap}, \mathbf{Qmap}, \mathbf{Smap}, \mathbf{Fmap}, \mathbf{Amap} \rangle$$

### 1. 七个线性栈（均以右端为栈顶）

| 栈名称 | 缩写 | 功能说明 |
| :--- | :--- | :--- |
| **输入栈** | **IP** | 待处理的 Token 流、宏指令与操作符队列。 |
| **变量上栈** | **VU** | 预置的无穷新鲜变量源（`v1, v2, v3, ...`）。 |
| **变量中栈** | **VM** | 当前活跃的判断值与极性游标栈（`Judge`, `True`, `False`）。 |
| **变量下栈** | **VL** | 论元变量排队栈，暂存等待参与量词闭包（`Build`/`End`）的变量。支持任意置换 `(i_n, ..., i_1)`。 |
| **输出栈** | **OP** | 逻辑命题工作区，累加推导中的中间关系项与最终逻辑公式。 |
| **修饰栈** | **MD** | 专用的修饰语暂存区，维护形容词、副词的作用域与延迟合成。 |
| **关系栈** | **RL** | 维护当前未闭合的题元角色与关系定界屏障（`Deter`, `Absorb`, `Join`）。 |

### 2. 语法债务计数器

*   **`Count` (整数):** 实时追踪当前悬挂的二元修饰关系债务。遇到关系宏执行 `Add`（`Count++`）；遇到实体宏执行 `Deter`（若 `Count > 0` 则消费债务 `Count--`，否则正常压入 `Deter` 隔离屏障）。

### 3. 五个关联映射（键均为变量名）

| 映射表 | 对应全称 | 缺省行为 (Lookup Miss) | 用途说明 |
| :--- | :--- | :--- | :--- |
| **Emap** | 环境映射 (Environment) | 报错 (Error) | 记录动态变量别名，用于代词照应（`Upload`/`Download`）。 |
| **Qmap** | 量化映射 (Quantifier) | 缺省为 ∃ (`Exist`) | 绑定量化变量的量词属性（$\forall, \exists$）。 |
| **Smap** | 集合映射 (Set) | 报错 (Error) | 记录变量所属的基底类别（如 `农夫`, `书`, `吃`）。 |
| **Fmap** | 表达式映射 (Filter) | 报错 (Error) | 累积形容词收缩条件、局部时空约束与从句逻辑。 |
| **Amap** | 关联变量映射 (Association)| 报错 (Error) | 将量化实体变量（`a`）与其定义域限制变量（`b`）关联。 |

---

## 💡 典型例句推导展示 (v0.9 核实)

### 1. 并列形容词的高阶副词分配律
> *“A且非常地重的、B且非常地高的人”*

```text
输入 (Input):
人:S Exchange 非常的宏 高的宏 B副词宏 重的宏 A副词宏

推导集合内涵输出 (Fmap 对应 v20):
And_consequent(v29,v28) ∧ And_antecedent(v29,v24) ∧
Ω(v28) ∧ (Exist v25∈{v2∈较大的重量 |
    Ω(v6) ∧ (Exist v3∈副词A对应的集合 (Exist v4∈副词A对应的谓词 主语(v4,v2) ∧ 宾语(v4,v3) ∧ 谓语(v6,v4))) ∧
    Ω(v18) ∧ (Exist v15∈较大的程度 (Exist v16∈程度为 主语(v16,v2) ∧ 宾语(v16,v15) ∧ 谓语(v18,v16)))}
    (Exist v26∈重量为 主语(v26,v20) ∧ 宾语(v26,v25) ∧ 谓语(v28,v26))) ∧
Ω(v24) ∧ (Exist v21∈{v8∈较大的高度 |
    Ω(v12) ∧ (Exist v9∈副词B对应的集合 (Exist v10∈副词B对应的谓词 主语(v10,v8) ∧ 宾语(v10,v9) ∧ 谓语(v12,v10))) ∧
    Ω(v18) ∧ (Exist v15∈较大的程度 (Exist v16∈程度为 主语(v16,v8) ∧ 宾语(v16,v15) ∧ 谓语(v18,v16)))}
    (Exist v22∈高度为 主语(v22,v20) ∧ 宾语(v22,v21) ∧ 谓语(v24,v22)))
```
*注：输入中仅出现一次的“非常的宏”，借助 `Exchange` 算子被自动分配复制到了“重量”与“高度”两个独立的子内涵中。*

### 2. 全命题否定 vs. 事件原子断言
> *“猫不吃鱼（在某种量化下）”*

```text
输入 (Input):
End Negation 吃宏 猫宏 鱼宏

推导逻辑输出 (Output):
Ω(v7) ∧ (Exist v1∈鱼 (Exist v3∈猫 (Exist v5∈吃
    Not(主语(v5,v3) ∧ 宾语(v5,v1) ∧ 谓语(v7,v5))))) v7
```

### 3. 局部时空精准界定与细粒度题元否定
> *“不在昨天的不在西边的红队攻击不在今天的不在东边的蓝队”*

```text
输入 (Input):
End 攻击宏 红队宏 昨天宏 Not 在宏 西边宏 Not 在宏 蓝队宏 今天宏 Not 在宏 东边宏 Not 在宏

推导逻辑输出 (Output):
Ω(v15) ∧ (Exist v1∈东边 (Exist v3∈今天 (Exist v5∈蓝队 (Exist v7∈西边 (Exist v9∈昨天 (Exist v11∈红队 (Exist v13∈攻击
    Not 在(v5,v3) ∧ Not 在(v5,v1) ∧
    Not 在(v11,v9) ∧ Not 在(v11,v7) ∧
    主语(v13,v11) ∧ 宾语(v13,v5) ∧ 谓语(v15,v13)))))))) v15
```

### 4. 动态代词照应与带否定的经典驴子句
> *“农民不给小孩书，小孩就不会读它。”*

```text
输入 (Input):
End 就:C Negation 读宏 Exist Download child Download book Negation 给宏 Exist 农夫宏 All Upload child 小孩宏 All Upload book 书宏 All

推导逻辑输出 (Output):
Ω(v13) ∧ (All v1∈书 (All v3∈小孩 (All v5∈农夫 (Exist v7∈给 (Exist v10∈读
    就_consequent(v13,v12) ∧ 就_antecedent(v13,v9) ∧
    Not(主语(v10,v3) ∧ 宾语(v10,v1) ∧ 谓语(v12,v10)) ∧
    Not(主语(v7,v5) ∧ 宾语(v7,v3) ∧ 传递物(v7,v1) ∧ 谓语(v9,v7))))))) v13
```

### 5. 多重递归副词合并与连续取消
> *“A且E地B地、C且E地D地重的人”*

```text
输入 (Input):
人:S 重的宏 副词交换宏 E副词宏 副词合并取消宏 D副词宏 C副词宏 Cancel B副词宏 A副词宏

推导集合内涵输出 (Fmap 对应 v30):
Ω(v34) ∧ (Exist v31∈{v19∈较大的重量 |
    And_consequent(v28,v27) ∧ And_antecedent(v28,v23) ∧
    Ω(v27) ∧ (Exist v24∈{v2∈副词B对应的集合 | ...} (Exist v25∈副词B对应的谓词 主语(v25,v19) ∧ 宾语(v25,v24) ∧ 谓语(v27,v25))) ∧
    Ω(v23) ∧ (Exist v20∈{v8∈Adv_D_Set | ...} (Exist v21∈Adv_D_Predicate 主语(v21,v19) ∧ 宾语(v21,v20) ∧ 谓语(v23,v21)))}
    (Exist v32∈重量为 主语(v32,v30) ∧ 宾语(v32,v31) ∧ 谓语(v34,v32)))
```

---

## 💻 交互式环境 (REPL)

*   `:r` — 重置自动机状态、栈与映射（保留已加载的宏）。
*   `:q` — 退出推导引擎。
*   `// <表达式>` — 单步跟踪模式（逐步打印全系统 7 栈 5 映射的状态流转）。
*   `define <名称> := <表达式>` — 注册全局宏定义。

---

## 📝 关于设计与实现

SML 的理论基石、形式语义规则体系、“七栈五映射一计数器”自动机架构以及关系消解演算均由**作者本人**独立构思并完成严格的数学化定义。

参考代码（`Main.hs`）中的 Haskell 实现由作者提供精确的状态转移规范并借助 AI 辅助生成（包括语法解析器 ReadP 与状态转移样板代码编写），作为可执行的语义虚拟机，验证了所有规约规则的自洽性与局部无泄漏修饰的工程可行性。
