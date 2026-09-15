# SML (Stack-Map-Loglang) 📐

**[English](#english) | [中文](#中文)**

---

<a id="english"></a>
# SML (English)

> An experimental formal semantic deduction engine and logical language (Loglang) based on a 5-stack, 5-mapping concatenative state machine.

⚠️ **STATUS: EXPERIMENTAL PROTOTYPE (v0.1)** ⚠️
> **SML is a formal semantic proof-of-concept.** It explores a non-syntactic-tree approach to natural language semantics, deducing first-order restricted quantification, higher-order modifier recursion, and dynamic anaphora purely via linear stack reductions and associative maps.

---

## 🚀 Overview

Traditional formal semantics (e.g., Montague Grammar) relies heavily on compositional syntax trees and rigid lambda-calculus beta-reductions. **SML (Stack-Map-Loglang)** replaces syntactic trees with a **5-Stack + 5-Mapping linear automaton**.

By combining **Neo-Davidsonian event reification**, **binary relational decomposition**, and **associative scope maps**, SML decouples quantifier scopes, nominal domain restrictions, and relation attachments. Complex semantic phenomena—such as multi-layer degree adverb nesting, restricted generalized quantifiers, and cross-clausal donkey anaphora—are solved within a lightweight, capture-free state machine.

---

## ✨ Key Features & Concepts

*   **5-Stack + 5-Mapping State Machine:**
    Decouples variable generation, active predicate cursors, quantifier scopes, and nominal domain constraints into separate linear stacks and dynamic key-value maps.
*   **Restricted Quantifier Construction (`build` Primitive):**
    Quantifiers are constructed on demand via:
    $$\text{build}(Q, a, b, S, F, D) \triangleq Q a \in \{b \in S \mid F\} (D)$$
    This cleanly separates quantifier force ($Q \in \text{Qmap}$), base sets ($S \in \text{Smap}$), and dynamic filter conditions ($F \in \text{Fmap}$).
*   **Neo-Davidsonian Event Semantics:**
    Verbs and sentences are reified into event instances. Thematic roles (`Subject`, `Object`, `Theme`, `Predicate`) are attached incrementally via binary relation reductions (`Rule 5`).
*   **Recursive Degree & Adverbial Calculus:**
    *   **Adjectives (`Modify`):** Refine nominal domains in `Fmap`.
    *   **Adverbs (`Polish`):** Recursively scale degree dimensions using higher-order lambda abstractions.
    *   **Scope Barrier (`Empty Adverb`):** Uses dummy variable isolation `[z, #]` and algebraic `And` reductions to support coordinate adverbial branching (e.g., *"A-ly and B-ly C-ly heavy"*).
*   **Dynamic Anaphora & Coreference:**
    Registers `Upload` and `Download` interact with the environment map (`Emap`), allowing pronouns and multi-clause coreferences to be resolved cleanly across sentences.
*   **Fresh Variable Generation:**
    An infinite stream of unique variables ($v_1, v_2, \dots$) eliminates variable capture by design.

---

## 🏗️ The 5-Stack 5-Map Automaton Model

$$\text{State} = \langle \mathbf{IS}, \mathbf{VUS}, \mathbf{VMS}, \mathbf{VLS}, \mathbf{OS}, \mathbf{Emap}, \mathbf{Qmap}, \mathbf{Smap}, \mathbf{Fmap}, \mathbf{Amap} \rangle$$

### 1. The 5 Stacks (Right end is Top)

| Stack | Identifier | Description |
| :--- | :--- | :--- |
| **Input Stack** | **IS** | Input stream of lexical tokens, macros, and operators. |
| **Var Upper Stack** | **VUS** | Infinite stream of fresh variables ($v_1, v_2, v_3, \dots$). |
| **Var Middle Stack** | **VMS** | Active variable cursor stack for binding predicate thematic roles. |
| **Var Lower Stack** | **VLS** | Scope queue recording variables waiting for quantifier closure (`Apply`/`End`). |
| **Output Stack** | **OS** | Working memory accumulating derived logical propositions and relations. |

### 2. The 5 Associative Mappings (Keys are Variables)

| Mapping | Name | Default / Miss Behavior | Purpose |
| :--- | :--- | :--- | :--- |
| **Emap** | Environment Map | Returns `Empty` | Stores dynamic variable registers for coreference (`Upload`/`Download`). |
| **Qmap** | Quantifier Map | Returns $\exists$ (`Exist`) | Maps bound variables to their quantifier force ($\forall, \exists$). |
| **Smap** | Set Map | Returns Universal Set | Maps domain variables to base set categories (e.g., `Farmer`, `Book`). |
| **Fmap** | Filter/Formula Map | Returns `#` (Empty) | Accumulates property filters and degree modifier constraints. |
| **Amap** | Association Map | Throws Error | Pairs quantified instance variables ($a$) with domain variables ($b$). |

---

## 💡 Showcase Examples

### 1. Dynamic Anaphora / Complex Donkey Sentence
> *"If a farmer gives a child a book, the child will read it."*

```text
Input:
End Then:C Read_Macro Exist Download child Download book Give_Macro Exist Farmer:S All Upload child Child:S All Upload book Book:S All

Evaluated Logical Output:
v13 (All v1∈Book (All v3∈Child (All v5∈Farmer (Exist v7∈Give (Exist v10∈Read
    Subject(v10,v3) ∧ Object(v10,v1) ∧ Predicate(v12,v10) ∧
    Subject(v7,v5) ∧ Object(v7,v3) ∧ Transferred_Object(v7,v1) ∧ Predicate(v9,v7) ∧
    Then_antecedent(v13,v9) ∧ Then_consequent(v13,v12))))))
```

### 2. Multi-Level Recursive Degree Modifiers
> *"A very very old, very heavy, tall person."*

```text
Input:
Tall_Macro Heavy_Macro Very_Macro Old_Macro Very_Macro Very_Macro Person:S

Evaluated Domain Filter (Fmap for v2):
[("v2", "∃a∈{v5∈Large_Age | ∃a∈{v3∈Large_Degree | ∃a∈Large_Degree s.t. v3.deg=a} s.t. v5.deg=a} s.t. v2.age=a ∧
        ∃a∈{v6∈Large_Weight | ∃a∈Large_Degree s.t. v6.deg=a} s.t. v2.weight=a ∧
        ∃a∈Large_Height s.t. v2.height=a")]
```

### 3. Coordinate Adverbial Branching (Scope Barrier)
> *"An A-ly and B-ly C-ly heavy person."*

```text
Input:
Heavy_Macro C_Adverb_Macro And A_Adverb_Macro Empty_Adverb_Macro B_Adverb_Macro Person:S

Evaluated Domain Filter (Fmap for v2):
[("v2", "∃a∈{v6∈Large_Weight | ∃a∈{v5∈Large_C | ∃a∈Large_A s.t. v5.A=a ∧ ∃a∈Large_B s.t. v5.B=a} s.t. v6.C=a} s.t. v2.weight=a")]
```

---

## 💻 REPL Commands

*   `:r` — Reset automaton state and stacks (macro definitions are preserved).
*   `:q` — Exit the REPL.
*   `// <expr>` — Step-by-step trace mode (prints state transitions and maps at every cycle).
*   `define <Name> := <Expr>` — Define a reusable macro shortcut.

---

## 📝 Design & Architecture Notes

The formal semantic rules, the 5-Stack 5-Map state machine, and the operational reduction calculus of SML were conceived and mathematically designed by **the author**. To quickly test and iterate on the theoretical ideas, the reference Haskell implementation (`Main.hs`) was primarily generated by AI tools, with the author reviewing, debugging, and verifying that the runtime behavior faithfully matches the intended formal specification.

---

<a id="中文"></a>
# SML (中文)

> 一个基于“五栈五映射”（5-Stack 5-Map）串接式状态机的形式语义推导引擎与逻辑语言（Loglang）原型。

⚠️ **当前状态：实验性原型 (v0.1)** ⚠️
> **SML 是一项探索性的形式语义概念验证项目。** 本项目摒弃传统的句法树生成范式，尝试仅依靠线性的多栈状态转移与关联映射表，完成一阶受限量词作用域、高阶递归程度修饰语以及跨从句动态代词照应的形式化语义推导。

---

## 🚀 简介

经典形式语义学（如蒙太格语法）高度依赖复杂的句法语义树递归与类型驱动的 $\lambda$ 规约。**SML (Stack-Map-Loglang)** 提出了一种全新的**五栈五映射（5-Stack + 5-Map）自动机模型**。

系统深度融合了**新大卫森事件实体化**、**二元关系降维分解**与**受限范围映射**机制，将量词辖域、集合约束和题元角色完全解耦。诸如多层程度副词嵌套、受限广义量词包裹、以及跨子句的复杂驴子句照应，均可在统一且无变量捕获的状态机中以极低冗余度完成线性推导。

---

## ✨ 核心概念与特性

*   **五栈五映射（5-Stack 5-Map）架构:**
    将新鲜变量生成、论元游标、量词作用域排队、中间命题累积及名词内涵约束完全分离在 5 个专用栈与 5 个哈希映射中。
*   **受限量词构建原语 (`build` Primitive):**
    统一使用受限量词模板进行语义闭包：
    $$\text{build}(Q, a, b, S, F, D) \triangleq Q a \in \{b \in S \mid F\} (D)$$
    清晰解耦量词力量（$Q \in \text{Qmap}$）、基底集合（$S \in \text{Smap}$）与修饰过滤条件（$F \in \text{Fmap}$）。
*   **新大卫森事件本体:**
    谓词与动作被抽象为独立的事件个体，主语、宾语、传递物等题元角色均通过统一的二元谓词（`Rule 5`）挂载，无需固定谓词参数位数。
*   **高阶程度与副词修饰演算:**
    *   **形容词（`Modify`）:** 动态收缩名词在 `Fmap` 中的受限集合内涵。
    *   **副词（`Polish`）:** 对程度标尺进行高阶函数抽象与代换。
    *   **空副词隔离屏障:** 借助 `[z, #]` 占位符切断副词的连续嵌套，结合 `And` 规则实现并列修饰分支（如 *“A且B地C地重”*）。
*   **跨从句动态指代与代词照应:**
    通过 `Upload` 与 `Download` 指令存取环境映射（`Emap`），以图（DAG）的形式优雅解决跨子句论元复用与经典驴子句照应问题。
*   **原生无冲突变量流:**
    变量上栈内置无穷独立变量流（$v_1, v_2, \dots$），从机制上杜绝命名冲突与变量捕获。

---

## 🏗️ 五栈五映射自动机模型

$$\text{State} = \langle \mathbf{IS}, \mathbf{VUS}, \mathbf{VMS}, \mathbf{VLS}, \mathbf{OS}, \mathbf{Emap}, \mathbf{Qmap}, \mathbf{Smap}, \mathbf{Fmap}, \mathbf{Amap} \rangle$$

### 1. 五个线性栈（均以右端为栈顶）

| 栈名称 | 缩写 | 功能说明 |
| :--- | :--- | :--- |
| **输入栈** | **IS** | 待处理的 Token 流、宏指令与操作符。 |
| **变量上栈** | **VUS** | 预置的无穷新鲜变量源（$v_1, v_2, v_3, \dots$）。 |
| **变量中栈** | **VMS** | 当前活跃的论元变量游标栈，用于谓词角色的挂载。 |
| **变量下栈** | **VLS** | 量化排队栈，暂存等待 `Apply`/`End` 进行量词闭包的变量。 |
| **输出栈** | **OS** | 逻辑命题工作区，累加推导中的关系项与最终逻辑公式。 |

### 2. 五个关联映射（键均为变量名）

| 映射表 | 对应全称 | 缺省行为 (Lookup Miss) | 用途说明 |
| :--- | :--- | :--- | :--- |
| **Emap** | 环境映射 (Environment) | 返回空 (Empty) | 记录动态变量别名，用于代词照应（`Upload`/`Download`）。 |
| **Qmap** | 量化映射 (Quantifier) | 缺省为 $\exists$ (`Exist`) | 绑定量化变量的量词属性（$\forall, \exists$ 等）。 |
| **Smap** | 集合映射 (Set) | 缺省为全集 | 记录变量所属的基底类别（如 `农夫`, `书`, `吃`）。 |
| **Fmap** | 表达式映射 (Filter) | 缺省为 `#` (空表达式) | 累积形容词收缩条件与程度属性过滤式。 |
| **Amap** | 关联变量映射 (Association)| 报错 (Error) | 将量化实体变量（$a$）与其定义域限制变量（$b$）关联。 |

---

## 💡 典型例句推导展示

### 1. 动态代词照应 / 复合驴子句
> *“农民给小孩书，小孩就会读它。”*

```text
输入 (Input):
End 就:C 读宏 Exist Download child Download book 给宏 Exist 农夫:S All Upload child 小孩:S All Upload book 书:S All

推导逻辑输出 (Output):
v13 (All v1∈书 (All v3∈小孩 (All v5∈农夫 (Exist v7∈给 (Exist v10∈读
    主语(v10,v3) ∧ 宾语(v10,v1) ∧ 谓语(v12,v10) ∧
    主语(v7,v5) ∧ 宾语(v7,v3) ∧ 传递物(v7,v1) ∧ 谓语(v9,v7) ∧
    就_antecedent(v13,v9) ∧ 就_consequent(v13,v12))))))
```

### 2. 多重程度修饰语递归嵌套
> *“非常非常老、非常重的高人”*

```text
输入 (Input):
高的宏 重的宏 非常的宏 老的宏 非常的宏 非常的宏 人:S

推导集合内涵输出 (Fmap 对应 v2):
[("v2", "存在a∈{v5∈比较大的年龄 | 存在a∈{v3∈比较大的程度 | 存在a∈比较大的程度使得v3的程度为a}使得v5的程度为a}使得v2的年龄为a ∧
        存在a∈{v6∈比较大的重量 | 存在a∈比较大的程度使得v6的程度为a}使得v2的重量为a ∧
        存在a∈比较大的高度使得v2的高度为a")]
```

### 3. 并列副词修饰隔离（屏障机制）
> *“A且B地C地重的人”*

```text
输入 (Input):
重的宏 C副词宏 And A副词宏 空副词宏 B副词宏 人:S

推导集合内涵输出 (Fmap 对应 v2):
[("v2", "存在a∈{v6∈比较大的重量 | 存在a∈{v5∈比较大的C | 存在a∈比较大的A使得v5的A为a ∧ 存在a∈比较大的B使得v5的B为a}使得v6的C为a}使得v2的重量为a")]
```

---

## 💻 交互式环境 (REPL)

*   `:r` — 重置自动机状态与栈数据（保留已定义的宏）。
*   `:q` — 退出 REPL。
*   `// <表达式>` — 单步跟踪模式（打印每一步五栈与五映射的状态变化）。
*   `define <名称> := <表达式>` — 注册全局宏指令。

---

## 📝 关于设计与实现

SML 的形式语义规则体系、五栈五映射自动机结构以及规约演算原语均由**作者本人**独立构思并完成数学化定义。为了更快地验证这一想法的实际运行效果，目前的 Haskell 参考实现（`Main.hs`）主要由 AI 工具生成辅助代码，作者主要负责调试排查并确保程序实现完全符合预期的形式化设计。
