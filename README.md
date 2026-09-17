# SML (Stack-Map-Loglang) 📐

**[English](#english) | [中文](#中文)**

---

<a id="english"></a>
# SML (English)

> An experimental formal semantic deduction engine and logical language (Loglang) based on a 7-stack, 5-mapping, 1-counter concatenative state machine.

> [!NOTE]
> **STATUS: SPECIFICATION & WORKING PROTOTYPE (v0.5)**  
> SML addresses the rigid fixed-place structures ($x_1, x_2, \dots$) and scope-leakage issues common in loglangs like Lojban. It enables first-order restricted quantification, localized spatiotemporal scoping, and higher-order modifier recursion purely via linear stack reductions and associative maps without syntactic tree overhead.

---

## 🚀 Overview

Traditional formal semantics (e.g., Montague Grammar) relies heavily on compositional syntax trees and rigid lambda-calculus $\beta$-reductions. Similarly, classical loglangs (such as Lojban) encode predicate argument places as rigid, predetermined tuple slots ($x_1, x_2, \dots, x_n$), requiring elidable terminators, conversion particles, or awkward relative clauses for local modifications.

**SML (Stack-Map-Loglang)** replaces syntactic trees and fixed place structures with a **7-Stack + 5-Mapping + 1-Counter linear automaton**.

By unifying all content concepts into unary sets (`:S`) and decomposing all predicates into **Neo-Davidsonian binary relations (`:R`)**, SML achieves a strict algebraic conservation law: **every relational modifier $R$ consumes exactly one entity $S$**. Combined with an integrated **Relation Stack (`RL`)** and an automatic **Debt Counter (`Count`)**, SML permits dynamic attachment of arbitrary adjuncts (time, space, degree) to individual terms without terminator tokens, argument position confusion, or cross-clause scope leakage.

---

## ✨ Key Features & Concepts

*   **7-Stack + 5-Mapping + 1-Counter State Machine:**  
    Decouples variable generation, active predicate cursors, quantifier scopes, modifier delays, relational frames, and nominal domain constraints into specialized linear stacks and key-value maps.
*   **No Fixed Place Structures (Universal Binary Decomposition):**  
    Predicates are reified into event entities (`Ω(e)`), with arguments attached via universal deep semantic relations (`Subject:R`, `Object:R`, `Theme:R`, etc.). Users do not memorize predicate-specific argument indices.
*   **Terminator-Free Modifiers via $\Delta R = \Delta S$ Conservation:**  
    Every relational link (`Add`) increments `Count`, signaling open relational debt. Core entities (`Deter`) decrement `Count`. This arithmetic balancing allows ad-hoc prepositional and adjectival attachments without closing delimiters (`ku`, `vau`, etc.).
*   **Clean Spatiotemporal Scoping & Fine-Grained Negation:**  
    Spatiotemporal modifiers (e.g., "yesterday", "in the west") attach directly to their host entity's local filter (`Fmap`). The `Judge` primitive distinguishes between whole-proposition negation and constituent/relation negation without scope drift.
*   **Restricted Quantifier Construction (`build` Primitive):**  
    Quantifiers are constructed on demand via:
    ```text
    build(Q, a, b, S, F, D) ≜ Q a ∈ {b ∈ S | F} (D)
    ```
    This cleanly isolates quantifier force (`Qmap`), base domain (`Smap`), and dynamic filter restrictions (`Fmap`).
*   **Higher-Order Modifier Calculus (`MD` Stack):**  
    *   **Adjectives (`Modify`):** Dynamically restrict nominal domains in `Fmap`.
    *   **Adverbs (`For` / `Modify`):** Recursively scale degree dimensions and event properties.
    *   **Composition & Distribution (`Combine`):** Merges modifiers via higher-order $\lambda$-abstractions and distributes modifiers across conjoined predicates.
*   **Dynamic Anaphora & Discourse Coreference:**  
    Registers `Upload` and `Download` interact with the environment map (`Emap`), allowing multi-clause pronouns and donkey-sentence coreferences to resolve cleanly.
*   **Native Capture-Free Fresh Variable Stream:**  
    An infinite supply of unique variables (`v1, v2, ...`) in the Upper Stack eliminates variable naming overhead and alpha-renaming collisions.

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

*   **`Count` (Integer):** Tracks unfulfilled relational obligations. Relation macros invoke `Add` (`Count++`), while entity macros invoke `Deter` (`Count--` if active, else push to `RL`). This eliminates the need for closing brackets around modifiers.

### 3. The 5 Associative Mappings (Keys are Variables)

| Mapping | Name | Default / Miss Behavior | Purpose |
| :--- | :--- | :--- | :--- |
| **Emap** | Environment Map | Throws Error | Stores dynamic variable registers for coreference (`Upload`/`Download`). |
| **Qmap** | Quantifier Map | Returns ∃ (`Exist`) | Maps bound variables to quantifier force ($\forall, \exists$). |
| **Smap** | Set Map | Throws Error | Maps domain variables to base set categories (e.g., `Farmer`, `Book`, `Eat`). |
| **Fmap** | Formula/Filter Map | Throws Error | Accumulates domain restrictions, local spatiotemporal relations, and degree filters. |
| **Amap** | Association Map | Throws Error | Pairs quantified instance variables (`a`) with domain restriction variables (`b`). |

---

## 💡 Showcase Examples

### 1. Localized Spatiotemporal Scoping (Solving Scope Leakage)
> *"The red team that was in the west yesterday attacks the blue team that is in the east today."*

```text
Input:
End Attack_Macro RedTeam_Macro Yesterday_Macro At_Macro West_Macro At_Macro BlueTeam_Macro Today_Macro At_Macro East_Macro At_Macro

Evaluated Logical Output:
Ω(v15) ∧ (Exist v1∈East (Exist v3∈Today (Exist v5∈BlueTeam (Exist v7∈West (Exist v9∈Yesterday (Exist v11∈RedTeam (Exist v13∈Attack
    At(v5,v3) ∧ At(v5,v1) ∧
    At(v11,v9) ∧ At(v11,v7) ∧
    Subject(v13,v11) ∧ Object(v13,v5) ∧ Predicate(v15,v13)))))))) v15
```
*Note: Time and location are bound strictly to their respective team entities without polluting the outer matrix predicate or each other.*

### 2. Complex Donkey Sentence / Dynamic Anaphora
> *"If a farmer gives a child a book, the child will read it."*

```text
Input:
End Then:C Read_Macro Exist Download child Download book Give_Macro Exist Farmer_Macro All Upload child Child_Macro All Upload book Book_Macro All

Evaluated Logical Output:
Ω(v13) ∧ (All v1∈Book (All v3∈Child (All v5∈Farmer (Exist v7∈Give (Exist v10∈Read
    Then_consequent(v13,v12) ∧ Then_antecedent(v13,v9) ∧
    Subject(v10,v3) ∧ Object(v10,v1) ∧ Predicate(v12,v10) ∧
    Subject(v7,v5) ∧ Object(v7,v3) ∧ Theme(v7,v1) ∧ Predicate(v9,v7)))))) v13
```

### 3. Multi-Level Recursive Degree Modifiers
> *"A very, very old person."*

```text
Input:
Person:S Old_Macro Very_Macro Very_Macro

Evaluated Domain Filter (Fmap for v13):
Ω(v17) ∧ (Exist v14∈{v7∈Large_Age |
    Ω(v11) ∧ (Exist v8∈{v2∈Large_Degree |
        Ω(v6) ∧ (Exist v3∈Large_Degree (Exist v4∈Degree_Is Subject(v4,v2) ∧ Object(v4,v3) ∧ Predicate(v6,v4)))}
        (Exist v9∈Degree_Is Subject(v9,v7) ∧ Object(v9,v8) ∧ Predicate(v11,v9)))}
    (Exist v15∈Age_Is Subject(v15,v13) ∧ Object(v15,v14) ∧ Predicate(v17,v15)))
```

### 4. Coordinate Adjectives with Shared Entity
> *"A person who is both tall and heavy."*

```text
Input:
Person:S Tall_Macro Heavy_Macro

Evaluated Domain Filter (Fmap for v5):
And_consequent(v14,v13) ∧ And_antecedent(v14,v9) ∧
Ω(v13) ∧ (Exist v10∈Large_Weight (Exist v11∈Weight_Is Subject(v11,v5) ∧ Object(v11,v10) ∧ Predicate(v13,v11))) ∧
Ω(v9)  ∧ (Exist v6∈Large_Height  (Exist v7∈Height_Is  Subject(v7,v5)  ∧ Object(v7,v6)  ∧ Predicate(v9,v7)))
```

### 5. Argument Scrambling & Constituent Negation
> *"Old cats quickly do something that is not eating to heavy things that are not fish (under a certain quantification)."*

```text
Input:
End Swap Eat_Macro Not Exist Fast_Macro Cat_Macro All Old_Macro Fish_Macro Not All Heavy_Macro

Evaluated Logical Output:
Ω(v22) ∧ (All v2∈{v3∈Fish | ...} (Exist v16∈{v17∈Eat | ...} (All v9∈{v10∈Cat | ...}
    Subject(v16,v9) ∧ Not Object(v16,v2) ∧ Not Predicate(v22,v16)))) v22
```

---

## 💻 REPL Commands

*   `:r` — Reset automaton state, stacks, and maps (macro definitions are preserved).
*   `:q` — Exit the deduction engine.
*   `// <expr>` — Step-by-step trace mode (prints state transitions across all 7 stacks and 5 maps).
*   `define <Name> := <Expr>` — Define a reusable macro expansion.

---

## 📝 Design & Architecture Notes

The formal semantic rules, the 7-Stack 5-Map 1-Counter state machine, and the relational reduction calculus of SML were conceived and mathematically designed by **the author**. The reference Haskell implementation (`Main.hs`) serves as an executable proof of the reduction rules and verification of zero-leakage scoping.

---

<a id="中文"></a>
# SML (中文)

> 基于“七栈五映射一计数器”（7-Stack 5-Map 1-Counter）串接式状态机的形式语义推导引擎与逻辑语言（Loglang）原型。

> [!NOTE]
> **当前状态：形式规范与可用原型 (v0.5)**  
> SML 彻底攻克了传统逻辑语（如 Lojban）饱受诟病的**固定位点结构（$x_1, x_2, \dots$ 位点记忆负担）**与**时空修饰语全局泄漏**难题。系统无需句法树，仅依靠线性多栈状态转移、代数计数平衡与关联映射，即可完成一阶受限量词、局部时空界定、高阶修饰递归与动态驴子句照应的无歧义形式化推导。

---

## 🚀 简介

经典形式语义学（如蒙太格语法）高度依赖复杂的句法语义树递归与类型驱动的 $\lambda$ 规约；而传统逻辑语（如 Lojban）则将多元谓词绑定为固定的位点结构（如 $x_1$ 到 $x_5$），导致实词记忆负担极重，且为单个论元添加局部时空修饰时语法冗长繁琐。

**SML (Stack-Map-Loglang)** 提出了全新的**七栈五映射一计数器（7-Stack + 5-Map + 1-Counter）自动机模型**。

系统将全语言的概念统一为单目集合（`:S`），将所有多元谓词拆解为**新大卫森二元关系（`:R`）**。由此建立了一条严密的数学守恒律：**每一个二元修饰关系 $R$ 在拓扑上必然且唯一地要求消费一个实体集合 $S$（$\Delta R = \Delta S$）**。配合新引入的**关系栈（`RL`）**与**债务计数器（`Count`）**，SML 允许自由、动态地为主句论元挂载任意时空与属性修饰，既无需手动书写闭合括号/终止子（Terminator-Free），也彻底杜绝了时空修饰语跨层级污染的问题。

---

## ✨ 核心概念与特性

*   **七栈五映射一计数器（7-Stack 5-Map 1-Counter）架构:**  
    将变量流、极性游标、量词闭包、输出命题、修饰语计算、关系格框以及修饰债务完全解耦。
*   **彻底消灭固定位点（全二元关系降维）:**  
    动作与谓词通过 `Event` 算子实体化为事件个体（`Ω(e)`），题元角色（`主语:R`, `宾语:R`, `传递物:R` 等）作为全局通用的二元关系自由挂载，使用者无需记忆每个动词私有的位点列表。
*   **零终止子的修饰吸收律（$\Delta R = \Delta S$ 计数平衡）:**  
    任何关系修饰（`Add`）都会让 `Count++`（登记语法债务）；而核心实体宏的 `Deter` 会在有债务时代替压栈执行 `Count--`（结清债务）。这使得论元修饰语可以随写随走，不再需要 Lojban 中冗余的闭合词（如 `ku`, `vau`, `ge'u`）。
*   **严格隔离的局部时空范围与细粒度成分否定:**  
    时空修饰语（如“昨天”、“西边”）作为局部约束直接沉淀进宿主名词的 `Fmap` 中。`Judge` 操作支持对具体成分与关系边的局部极性翻转，完美区分“命题全局否定”与“局部成分否定”。
*   **受限量词构建原语 (`build` Primitive):**  
    统一使用受限量词模板进行语义闭包：
    ```text
    build(Q, a, b, S, F, D) ≜ Q a ∈ {b ∈ S | F} (D)
    ```
    解耦量词力量（`Qmap`）、基底集合（`Smap`）与修饰过滤式（`Fmap`）。
*   **高阶修饰语演算 (`MD` 栈):**  
    *   **形容词（`Modify`）:** 动态收缩名词在 `Fmap` 中的受限集合内涵。
    *   **副词（`For` / `Modify`）:** 对程度标尺与事件属性进行高阶函数抽象与连续修饰。
    *   **合并（`Combine`）:** 借助高阶 $\lambda$-演算合并多个修饰语，并支持向并列项自动分配。
*   **跨从句动态指代与代词照应:**  
    通过 `Upload` 与 `Download` 指令存取环境映射（`Emap`），以图（DAG）的形式优雅解决跨子句论元复用与经典驴子句照应。
*   **原生无冲突变量流:**  
    变量上栈（VU）内置无穷新鲜变量源（`v1, v2, ...`），从机制上彻底免除变量命名负担与变量捕获冲突。

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

*   **`Count` (整数):** 实时追踪当前悬挂的二元修饰关系债务。遇到关系宏执行 `Add`（`Count++`）；遇到实体宏执行 `Deter`（若 `Count > 0` 则消费债务 `Count--`，否则正常压入关系隔离屏障）。

### 3. 五个关联映射（键均为变量名）

| 映射表 | 对应全称 | 缺省行为 (Lookup Miss) | 用途说明 |
| :--- | :--- | :--- | :--- |
| **Emap** | 环境映射 (Environment) | 报错 (Error) | 记录动态变量别名，用于代词照应（`Upload`/`Download`）。 |
| **Qmap** | 量化映射 (Quantifier) | 缺省为 ∃ (`Exist`) | 绑定量化变量的量词属性（$\forall, \exists$）。 |
| **Smap** | 集合映射 (Set) | 报错 (Error) | 记录变量所属的基底类别（如 `农夫`, `书`, `吃`）。 |
| **Fmap** | 表达式映射 (Filter) | 报错 (Error) | 累积形容词收缩条件、局部时空约束与从句逻辑。 |
| **Amap** | 关联变量映射 (Association)| 报错 (Error) | 将量化实体变量（`a`）与其定义域限制变量（`b`）关联。 |

---

## 💡 典型例句推导展示

### 1. 局部时空精准界定（解决作用域泄漏）
> *“在昨天的在西边的红队攻击在今天的在东边的蓝队”*

```text
输入 (Input):
End 攻击宏 红队宏 昨天宏 在宏 西边宏 在宏 蓝队宏 今天宏 在宏 东边宏 在宏

推导逻辑输出 (Output):
Ω(v15) ∧ (Exist v1∈东边 (Exist v3∈今天 (Exist v5∈蓝队 (Exist v7∈西边 (Exist v9∈昨天 (Exist v11∈红队 (Exist v13∈攻击
    在(v5,v3) ∧ 在(v5,v1) ∧
    在(v11,v9) ∧ 在(v11,v7) ∧
    主语(v13,v11) ∧ 宾语(v13,v5) ∧ 谓语(v15,v13)))))))) v15
```
*注：时间和空间关系严格被各自修饰的实体变量（`v11` 与 `v5`）吸纳，主句谓词“攻击”不受任何时空污染。*

### 2. 动态代词照应 / 经典驴子句
> *“农民给小孩书，小孩就会读它。”*

```text
输入 (Input):
End 就:C 读宏 Exist Download child Download book 给宏 Exist 农夫宏 All Upload child 小孩宏 All Upload book 书宏 All

推导逻辑输出 (Output):
Ω(v13) ∧ (All v1∈书 (All v3∈小孩 (All v5∈农夫 (Exist v7∈给 (Exist v10∈读
    就_consequent(v13,v12) ∧ 就_antecedent(v13,v9) ∧
    主语(v10,v3) ∧ 宾语(v10,v1) ∧ 谓语(v12,v10) ∧
    主语(v7,v5) ∧ 宾语(v7,v3) ∧ 传递物(v7,v1) ∧ 谓语(v9,v7)))))) v13
```

### 3. 多重程度修饰语递归嵌套
> *“非常非常老的人”*

```text
输入 (Input):
人:S 老的宏 非常的宏 非常的宏

推导集合内涵输出 (Fmap 对应 v13):
Ω(v17) ∧ (Exist v14∈{v7∈较大的年龄 |
    Ω(v11) ∧ (Exist v8∈{v2∈较大的程度 |
        Ω(v6) ∧ (Exist v3∈较大的程度 (Exist v4∈程度为 主语(v4,v2) ∧ 宾语(v4,v3) ∧ 谓语(v6,v4)))}
        (Exist v9∈程度为 主语(v9,v7) ∧ 宾语(v9,v8) ∧ 谓语(v11,v9)))}
    (Exist v15∈年龄为 主语(v15,v13) ∧ 宾语(v15,v14) ∧ 谓语(v17,v15)))
```

### 4. 并列形容词与实体修饰
> *“又高又重的人”*

```text
输入 (Input):
人:S 高的宏 重的宏

推导集合内涵输出 (Fmap 对应 v5):
And_consequent(v14,v13) ∧ And_antecedent(v14,v9) ∧
Ω(v13) ∧ (Exist v10∈较大的重量 (Exist v11∈重量为 主语(v11,v5) ∧ 宾语(v11,v10) ∧ 谓语(v13,v11))) ∧
Ω(v9)  ∧ (Exist v6∈较大的高度  (Exist v7∈高度为  主语(v7,v5)  ∧ 宾语(v7,v6)  ∧ 谓语(v9,v7)))
```

### 5. 非线性论元排列与成分否定
> *“老的猫快地对重的不是鱼的什么做了不是吃的什么（在某种量化下）”*

```text
输入 (Input):
End Swap 吃宏 Not Exist 快的宏 猫宏 All 老的宏 鱼宏 Not All 重的宏

推导逻辑输出 (Output):
Ω(v22) ∧ (All v2∈{v3∈鱼 | ...} (Exist v16∈{v17∈吃 | ...} (All v9∈{v10∈猫 | ...}
    主语(v16,v9) ∧ Not 宾语(v16,v2) ∧ Not 谓语(v22,v16)))) v22
```

---

## 💻 交互式环境 (REPL)

*   `:r` — 重置自动机状态、栈与映射（保留已加载的宏）。
*   `:q` — 退出推导引擎。
*   `// <表达式>` — 单步跟踪模式（逐步打印全系统 7 栈 5 映射的状态流转）。
*   `define <名称> := <表达式>` — 注册全局宏定义。

---

## 📝 关于设计与实现

SML 的形式语义规则体系、七栈五映射一计数器自动机架构以及关系消解演算均由**作者本人**独立构思并完成数学化定义。当前的 Haskell 参考实现（`Main.hs`）作为可执行的语义虚拟机，验证了所有规约规则的正确性与局部无泄漏修饰的数学可行性。
