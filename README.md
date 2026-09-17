# SML (Stack-Map-Loglang) 📐

**[English](#english) | [中文](#中文)**

---

<a id="english"></a>
# SML (English)

> An experimental formal semantic deduction engine and logical language (Loglang) based on a 6-stack, 5-mapping concatenative state machine.

> [!WARNING]
> **STATUS: EXPERIMENTAL PROTOTYPE (v0.2)**  
> **SML is a formal semantic proof-of-concept.** It explores a non-syntactic-tree approach to natural language semantics, deducing first-order restricted quantification, higher-order modifier recursion, and dynamic anaphora purely via linear stack reductions and associative maps.

---

## 🚀 Overview

Traditional formal semantics (e.g., Montague Grammar) relies heavily on compositional syntax trees and rigid lambda-calculus beta-reductions. **SML (Stack-Map-Loglang)** replaces syntactic trees with a **6-Stack + 5-Mapping linear automaton**.

By combining **Neo-Davidsonian event reification (`Ω`)**, **binary relational decomposition**, an **explicit Modifier Stack (`MD`)**, and **associative scope maps**, SML decouples quantifier scopes, nominal domain restrictions, thematic role bindings, and modifier attachments. Complex semantic phenomena—such as multi-layer degree adverb nesting, coordinate modifier distribution (`A → (B ∧ C) ≡ (A → B) ∧ (A → C)`), restricted generalized quantifiers, and cross-clausal donkey anaphora—are solved within a lightweight, capture-free state machine.

---

## ✨ Key Features & Concepts

*   **6-Stack + 5-Mapping State Machine:**  
    Decouples variable generation, active predicate cursors, quantifier scopes, modifier delays, and nominal domain constraints into separate linear stacks and dynamic key-value maps.
*   **Restricted Quantifier Construction (`build` Primitive):**  
    Quantifiers are constructed on demand via:
    ```text
    build(Q, a, b, S, F, D) ≜ Q a ∈ {b ∈ S | F} (D)
    ```
    This cleanly separates quantifier force (`Q ∈ Qmap`), base sets (`S ∈ Smap`), and dynamic filter conditions (`F ∈ Fmap`).
*   **Neo-Davidsonian Event Semantics:**  
    Verbs, actions, and states are reified into event instances (`Ω(e)`) via the `Event` operator. Thematic roles (`Subject`, `Object`, `Theme`, `Predicate`) are incrementally attached via binary relations (`:R`).
*   **Higher-Order Modifier Calculus (`MD` Stack):**  
    *   **Adjectives (`Modify`):** Dynamically restrict nominal domains in `Fmap`.
    *   **Adverbs (`For` / `Modify`):** Recursively scale degree dimensions and event properties.
    *   **Composition & Distribution (`Combine` / `Exchange`):** Merges modifiers via higher-order λ-abstractions and correctly distributes parent adverbs across conjoined adjectives using variable substitution.
*   **Dynamic Anaphora & Coreference:**  
    Registers `Upload` and `Download` interact with the environment map (`Emap`), allowing pronouns and multi-clause coreferences to be resolved cleanly across sentences.
*   **Native Capture-Free Variable Stream:**  
    An infinite stream of unique variables (`v1`, `v2`, ...) in the Upper Stack eliminates variable capture by design.

---

## 🏗️ The 6-Stack 5-Map Automaton Model

$$\text{State} = \langle \mathbf{IP}, \mathbf{VU}, \mathbf{VM}, \mathbf{VL}, \mathbf{OP}, \mathbf{MD}, \mathbf{Emap}, \mathbf{Qmap}, \mathbf{Smap}, \mathbf{Fmap}, \mathbf{Amap} \rangle$$

### 1. The 6 Stacks (Right end is Top)

| Stack | Identifier | Description |
| :--- | :--- | :--- |
| **Input Stack** | **IP** | Instruction queue holding tokens, macros, and operators awaiting reduction. |
| **Var Upper Stack** | **VU** | Infinite stream of fresh variables (`v1, v2, v3, ...`). |
| **Var Middle Stack** | **VM** | Active variable cursor stack for judgments and truth polarities (`Judge`, `True`, `False`). |
| **Var Lower Stack** | **VL** | Scope queue recording active entities/arguments for relational binding and quantifier closure (`Build`/`End`). Supports arbitrary permutation `(i_n, ..., i_1)`. |
| **Output Stack** | **OP** | Working memory accumulating derived logical propositions, relations, and AST subtrees. |
| **Modifier Stack** | **MD** | Specialized stack for higher-order modifiers, adjectival/adverbial scopes, and delayed composition. |

### 2. The 5 Associative Mappings (Keys are Variables)

| Mapping | Name | Default / Miss Behavior | Purpose |
| :--- | :--- | :--- | :--- |
| **Emap** | Environment Map | Throws Error | Stores dynamic variable registers for coreference (`Upload`/`Download`). |
| **Qmap** | Quantifier Map | Returns ∃ (`Exist`) | Maps bound variables to their quantifier force (∀, ∃). |
| **Smap** | Set Map | Throws Error | Maps domain variables to base set categories (e.g., `Farmer`, `Book`, `Eat`). |
| **Fmap** | Formula/Filter Map | Throws Error | Accumulates domain restrictions, degree modifiers, and relative clauses. |
| **Amap** | Association Map | Throws Error | Pairs quantified instance variables (`a`) with domain restriction variables (`b`). |

---

## 💡 Showcase Examples

### 1. Complex Donkey Sentence / Dynamic Anaphora
> *"If a farmer gives a child a book, the child will read it."*

```text
Input:
End Then:C Read_Macro Exist Download child Download book Give_Macro Exist Farmer:S All Upload child Child:S All Upload book Book:S All

Evaluated Logical Output:
Ω(v13) ∧ (All v1∈Book (All v3∈Child (All v5∈Farmer (Exist v7∈Give (Exist v10∈Read
    Then_consequent(v13,v12) ∧ Then_antecedent(v13,v9) ∧
    Subject(v10,v3) ∧ Object(v10,v1) ∧ Predicate(v12,v10) ∧
    Subject(v7,v5) ∧ Object(v7,v3) ∧ Theme(v7,v1) ∧ Predicate(v9,v7)))))) v13
```

### 2. Multi-Level Recursive Degree Modifiers
> *"A very, very old person."*

```text
Input:
Person:S Old_Macro Very_Macro Very_Macro

Evaluated Domain Filter (Fmap for v13):
Ω(v17) ∧ (Exist v14∈{v7∈Greater_Age |
    Ω(v11) ∧ (Exist v8∈{v2∈Greater_Degree |
        Ω(v6) ∧ (Exist v3∈Greater_Degree (Exist v4∈Degree_Is Subject(v4,v2) ∧ Object(v4,v3) ∧ Predicate(v6,v4)))}
        (Exist v9∈Degree_Is Subject(v9,v7) ∧ Object(v9,v8) ∧ Predicate(v11,v9)))}
    (Exist v15∈Age_Is Subject(v15,v13) ∧ Object(v15,v14) ∧ Predicate(v17,v15)))
```

### 3. Coordinate Adjectives with Shared Entity
> *"A person who is both tall and heavy."*

```text
Input:
Person:S Tall_Macro Heavy_Macro

Evaluated Domain Filter (Fmap for v5):
And_consequent(v14,v13) ∧ And_antecedent(v14,v9) ∧
Ω(v13) ∧ (Exist v10∈Greater_Weight (Exist v11∈Weight_Is Subject(v11,v5) ∧ Object(v11,v10) ∧ Predicate(v13,v11))) ∧
Ω(v9)  ∧ (Exist v6∈Greater_Height  (Exist v7∈Height_Is  Subject(v7,v5)  ∧ Object(v7,v6)  ∧ Predicate(v9,v7)))
```

### 4. Non-linear Argument Scrambling and Negation
> *"Old cats quickly do something that is not eating to heavy things that are not fish (under a certain quantification)."*

```text
Input:
End Swap Eat_Macro Not Exist Fast_Macro Cat:S All Old_Macro Fish:S Not All Heavy_Macro

Evaluated Logical Output:
Ω(v22) ∧ (All v2∈{v3∈Fish | ...} (Exist v16∈{v17∈Eat | ...} (All v9∈{v10∈Cat | ...}
    Subject(v16,v9) ∧ Not Object(v16,v2) ∧ Not Predicate(v22,v16)))) v22
```

---

## 💻 REPL Commands

*   `:r` — Reset automaton state, stacks, and maps (macro definitions are preserved).
*   `:q` — Exit the REPL.
*   `// <expr>` — Step-by-step trace mode (prints state transitions, stacks, and maps at every step).
*   `define <Name> := <Expr>` — Define a reusable macro shortcut.

---

## 📝 Design & Architecture Notes

The formal semantic rules, the 6-Stack 5-Map state machine, and the operational reduction calculus of SML were conceived and mathematically designed by **the author**. To test and iterate on the theoretical model, the reference Haskell implementation (`Main.hs`) was implemented with AI assistance, with the author reviewing, debugging, and verifying that the runtime behavior faithfully matches the intended formal specification.

---

<a id="中文"></a>
# SML (中文)

> 一个基于“六栈五映射”（6-Stack 5-Map）串接式状态机的形式语义推导引擎与逻辑语言（Loglang）原型。

> [!WARNING]
> **当前状态：实验性原型 (v0.2)**  
> **SML 是一项探索性的形式语义概念验证项目。** 本项目摒弃传统的句法树生成范式，尝试仅依靠线性的多栈状态转移与关联映射表，完成一阶受限量词作用域、新大卫森事件语义、高阶递归程度修饰语以及跨从句动态代词照应的形式化语义推导。

---

## 🚀 简介

经典形式语义学（如蒙太格语法）高度依赖复杂的句法语义树递归与类型驱动的 λ 规约。**SML (Stack-Map-Loglang)** 提出了一种全新的**六栈五映射（6-Stack + 5-Map）自动机模型**。

系统深度融合了**新大卫森事件实体化 (`Ω`)**、**二元关系降维分解**、**专用修饰栈 (`MD`)** 与**受限范围映射**机制，将量词辖域、集合约束、题元角色挂载与修饰语应用完全解耦。诸如多层程度副词嵌套、并列修饰语向内分配（`A → (B ∧ C) ≡ (A → B) ∧ (A → C)`）、受限广义量词包裹、以及跨子句的复杂驴子句照应，均可在统一且无变量捕获的状态机中以极低冗余度完成线性推导。

---

## ✨ 核心概念与特性

*   **六栈五映射（6-Stack 5-Map）架构:**  
    将新鲜变量生成、论元游标、量词排队、中间命题累积、修饰语延迟作用域及名词内涵约束完全分离在 6 个专用栈与 5 个哈希映射中。
*   **受限量词构建原语 (`build` Primitive):**  
    统一使用受限量词模板进行语义闭包：
    ```text
    build(Q, a, b, S, F, D) ≜ Q a ∈ {b ∈ S | F} (D)
    ```
    清晰解耦量词力量（`Q ∈ Qmap`）、基底集合（`S ∈ Smap`）与修饰过滤条件（`F ∈ Fmap`）。
*   **新大卫森事件本体 (`Ω`):**  
    谓词与动作被抽象为独立的事件个体（通过 `Event` 算子引入 `Ω(e)`），主语、宾语、传递物等题元角色均通过统一的二元谓词关系挂载，天然支持动词配价变化。
*   **高阶程度与修饰演算 (`MD` 栈):**  
    *   **形容词（`Modify`）:** 动态收缩名词在 `Fmap` 中的受限集合内涵。
    *   **副词（`For` / `Modify`）:** 对程度标尺与事件属性进行高阶函数抽象与连续修饰。
    *   **合并与分配律（`Combine` / `Exchange`）:** 通过高阶 λ 函数封装并列修饰语，并借助变量代换原语（`Substitute`）精确实现副词向并列形容词的向下分配。
*   **跨从句动态指代与代词照应:**  
    通过 `Upload` 与 `Download` 指令存取环境映射（`Emap`），以图（DAG）的形式优雅解决跨子句论元复用与经典驴子句照应问题。
*   **原生无冲突变量流:**  
    变量上栈内置无穷独立变量流（`v1`, `v2`, ...），从机制上杜绝命名冲突与变量捕获。

---

## 🏗️ 六栈五映射自动机模型

$$\text{State} = \langle \mathbf{IP}, \mathbf{VU}, \mathbf{VM}, \mathbf{VL}, \mathbf{OP}, \mathbf{MD}, \mathbf{Emap}, \mathbf{Qmap}, \mathbf{Smap}, \mathbf{Fmap}, \mathbf{Amap} \rangle$$

### 1. 六个线性栈（均以右端为栈顶）

| 栈名称 | 缩写 | 功能说明 |
| :--- | :--- | :--- |
| **输入栈** | **IP** | 待处理的 Token 流、宏指令与操作符队列。 |
| **变量上栈** | **VU** | 预置的无穷新鲜变量源（`v1, v2, v3, ...`）。 |
| **变量中栈** | **VM** | 当前活跃的判断值与极性游标栈（`Judge`, `True`, `False`）。 |
| **变量下栈** | **VL** | 论元变量排队栈，暂存等待参与关系挂载或量词闭包（`Build`/`End`）的变量。支持任意论元置换 `(i_n, ..., i_1)`。 |
| **输出栈** | **OP** | 逻辑命题工作区，累加推导中的关系项与最终 AST 逻辑公式。 |
| **修饰栈** | **MD** | 专用的修饰语暂存区，维护形容词、副词的作用域与延迟合成。 |

### 2. 五个关联映射（键均为变量名）

| 映射表 | 对应全称 | 缺省行为 (Lookup Miss) | 用途说明 |
| :--- | :--- | :--- | :--- |
| **Emap** | 环境映射 (Environment) | 报错 (Error) | 记录动态变量别名，用于代词照应（`Upload`/`Download`）。 |
| **Qmap** | 量化映射 (Quantifier) | 缺省为 ∃ (`Exist`) | 绑定量化变量的量词属性（∀, ∃ 等）。 |
| **Smap** | 集合映射 (Set) | 报错 (Error) | 记录变量所属的基底类别（如 `人`, `书`, `吃`）。 |
| **Fmap** | 表达式映射 (Filter) | 报错 (Error) | 累积形容词收缩条件、程度属性过滤式及关系从句。 |
| **Amap** | 关联变量映射 (Association)| 报错 (Error) | 将量化实体变量（`a`）与其定义域限制变量（`b`）关联。 |

---

## 💡 典型例句推导展示

### 1. 动态代词照应 / 经典驴子句
> *“农民给小孩书，小孩就会读它。”*

```text
输入 (Input):
End 就:C 读宏 Exist Download child Download book 给宏 Exist 农夫:S All Upload child 小孩:S All Upload book 书:S All

推导逻辑输出 (Output):
Ω(v13) ∧ (All v1∈书 (All v3∈小孩 (All v5∈农夫 (Exist v7∈给 (Exist v10∈读
    就_consequent(v13,v12) ∧ 就_antecedent(v13,v9) ∧
    主语(v10,v3) ∧ 宾语(v10,v1) ∧ 谓语(v12,v10) ∧
    主语(v7,v5) ∧ 宾语(v7,v3) ∧ 传递物(v7,v1) ∧ 谓语(v9,v7)))))) v13
```

### 2. 多重程度修饰语递归嵌套
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

### 3. 并列形容词与实体修饰
> *“又高又重的人”*

```text
输入 (Input):
人:S 高的宏 重的宏

推导集合内涵输出 (Fmap 对应 v5):
And_consequent(v14,v13) ∧ And_antecedent(v14,v9) ∧
Ω(v13) ∧ (Exist v10∈较大的重量 (Exist v11∈重量为 主语(v11,v5) ∧ 宾语(v11,v10) ∧ 谓语(v13,v11))) ∧
Ω(v9)  ∧ (Exist v6∈较大的高度  (Exist v7∈高度为  主语(v7,v5)  ∧ 宾语(v7,v6)  ∧ 谓语(v9,v7)))
```

### 4. 非线性论元排列与事件否定
> *“老的猫快地对重的不是鱼的什么做了不是吃的什么（在某种量化下）”*

```text
输入 (Input):
End Swap 吃宏 Not Exist 快的宏 猫:S All 老的宏 鱼:S Not All 重的宏

推导逻辑输出 (Output):
Ω(v22) ∧ (All v2∈{v3∈鱼 | ...} (Exist v16∈{v17∈吃 | ...} (All v9∈{v10∈猫 | ...}
    主语(v16,v9) ∧ Not 宾语(v16,v2) ∧ Not 谓语(v22,v16)))) v22
```

---

## 💻 交互式环境 (REPL)

*   `:r` — 重置自动机状态与栈数据（保留已定义的宏）。
*   `:q` — 退出 REPL。
*   `// <表达式>` — 单步跟踪模式（打印每一步六栈与五映射的状态转移）。
*   `define <名称> := <表达式>` — 注册全局宏定义。

---

## 📝 关于设计与实现

SML 的形式语义规则体系、六栈五映射自动机结构以及规约演算原语均由**作者本人**独立构思并完成数学化定义。为了更快地验证理论模型的可行性，目前的 Haskell 参考实现（`Main.hs`）在 AI 工具的辅助下完成代码构建，作者负责整体调试排查，并严格确保运行行为与形式化规范完全一致。
