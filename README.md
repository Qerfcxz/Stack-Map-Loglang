# SML (Stack-Map-Loglang) 📐

**[English](#english) | [中文](#中文)**

---

<a id="english"></a>
# SML (English)

> An experimental formal semantic deduction engine and logical language (Loglang) architecture based on a 6-Stack, 1-Stream, 1-Register, and 8-Map concatenative state machine.

> [!NOTE]
> **STATUS: EXPERIMENTAL SPECIFICATION & PROTOTYPE (v1.0)**  
> This project is currently an experimental formal specification and prototype. The core reduction engine has been validated against a preliminary suite of 8 representative benchmark cases (covering deeply nested relative clauses, generalized quantifiers, donkey sentences, scale semantics, dynamic permutation pipelines, and dual-track negation). It remains an exploratory design and awaits broader corpus testing, formal verification, and automated stress testing.

---

## 🚀 Overview

Traditional formal semantics (e.g., Montague Grammar) typically relies on compositional syntactic trees, type-driven functional application, and Quantifier Raising (QR). Conversely, classical logical languages (such as Lojban) encode predicates as rigid, predetermined tuple slots (`x₁, ..., xₙ`), which often introduces substantial lexical memorization burdens and necessitates elidable terminators (`ku`, `vau`, `kei`, etc.) to resolve structural ambiguities.

**SML (Stack-Map-Loglang) v1.0** explores an alternative, tree-free operational model: **a linear concatenative abstract machine with relational graph construction and quantifier closure**.

By treating all lexical content as unary base sets (`:S`), dynamic event reification (`Ω`), and binary relations (`:R`), SML establishes an incremental state-transition system. Coupled with higher-order continuation closures on a Wait Stack (`WT`), a dual-track restrictor/nuclear scope mapping (`Imap` / `Omap`), and a permutation pipeline (`PR`), SML aims to resolve complex quantifier scopings, nested and coordinate relative clauses, and constituent/propositional negations without syntax trees or structural closing delimiters.

---

## 🏗️ Abstract Machine Model (v1.0)

```text
State = ⟨ IP, NM, QN, WT, CM, PR, OP, ⟨F⟩, Imap, Omap, Qmap, Smap, Mmap, Fmap, Emap, Map ⟩
```

### 1. The 6 Stacks + 1 Stream + 1 Scalar Register (Right end is Top)

| Component | Identifier | Description |
| :--- | :--- | :--- |
| **Input Stack** | **IP** | Queue of tokens, instruction blocks, and unpacked macros awaiting execution. |
| **Number Stream** | **NM** | Infinite generator of fresh, monotonically increasing integer IDs (`1, 2, 3, ...`). |
| **Quantifier Queue** | **QN** | Queue storing entity IDs awaiting quantifier closure (`Build !`). |
| **Wait Stack** | **WT** | Staging area for higher-order continuation closures (`λa. B`), intermediate entities, and modifier polarities. |
| **Component Stack**| **CM** | Storage for active arguments and their truth polarities (`Polarity Entity`). |
| **Permutation Stack**| **PR** | Buffer and pipeline for permutation operations and dynamic combinator adjustments. |
| **Output Stack** | **OP** | Immediate working memory for atomic reductions, boolean logic, and relation triggers. |
| **Focus Register** | **`⟨F⟩`** | Scalar integer register tracking the core host entity currently undergoing clause closure. |

### 2. The 8 Associative Maps (Keys are Entity IDs)

| Map | Identifier | Function |
| :--- | :--- | :--- |
| **Restrictor Map** | **Imap** | Accumulates nominal restrictions and relative clause formulas inside `{α_i ∈ S_i \| Imap[i]}`. |
| **Nuclear Scope Map** | **Omap** | Accumulates asserted predicate propositions. |
| **Quantifier Map** | **Qmap** | Maps entity variables to generalized quantifier forces (default: `Exist` / ∃). |
| **Base Set Map** | **Smap** | Maps entity IDs to base category names or event domains (e.g., `"Cat"`, `"Ω"`). |
| **Mode Map** | **Mmap** | Polarity mode: `True` writes relations to `Imap` (Inner), `False` writes to `Omap` (Outer). |
| **Focus Flag Map** | **Fmap** | Identifies whether an entity is a protected host of an active relative clause. |
| **Environment Map**| **Emap** | Dynamic variable alias registry for cross-clause pronoun coreference (`Upload` / `Download`). |
| **Lexical Macro Map**| **Map** | Global dictionary mapping lexical set strings to their predicate frame macros. |

---

## 💡 Key Architectural Evolutions (v1.0 vs v0.99)

*   **Noun-Verb Parity**:  
    Verbs and nouns are unified as unary sets (`:S`). Verbal predicate frames are dynamically unpacked via `Map`, allowing verbs to natively host relative clauses and higher-order adjuncts just like nouns.
*   **Currying Continuation Closures on `WT`**:  
    Pre-modifiers and relation builders are staged on `WT` as `λ`-closures, resolving surface word-order mismatches through post-order beta-substitutions without syntax trees.
*   **Generalized Quantifier Duality (`Imap` vs `Omap`)**:  
    Quantification cleanly separates restrictors from nuclear scopes, naturally accommodating Generalized Quantifiers (such as proportional quantifiers, e.g., *More Than Half*).
*   **Single Scalar Focus Register with Invariant Restoration**:  
    Replacing the dedicated clause stack with `⟨F⟩` and atomic `Release` macros allows both nested and coordinate relative clauses to evaluate with automatic host reset.
*   **Permutation Pipeline (`PR`) and Church-Peano Recursion**:  
    High-arity quantifiers and permutation adjustments are driven by a dynamic permutation stack and list-peeling recursion, preventing fixed-arity macro combinatorial explosion.

---

## 🌐 Linguistic Philosophy: The Relational "Annotation" Model

Rather than hardcoding rigid metaphysical assumptions into the grammar (e.g., prescribing a specific tense logic, or baking in a fixed Kripkean possible-world modal frame), SML treats language as an **open topological graph construction and quantifier closure process**:

*   **Grammar as an Agnostic Canvas**:  
    The core abstract machine enforces only topological conservation and generalized quantifier closure. It does not dictate how speakers must conceptualize time, space, or probability.
*   **Semantics as Progressive Annotation**:  
    Complex linguistic phenomena are represented as iterative binary relations (`R`) attached to entities (`S`) or events (`Ω`):
    *   *Tense & Aspect*: Modeled via relational spatiotemporal coordinates attached to event entities (e.g., `Occurred_At(e, t)`).
    *   *Modality & Probability*: Modeled as graded attributes (e.g., `Probability(e, 0.5)` or `Evidence_Source(e, Direct_Sight)`) rather than rigid modal operators.
    *   *Degree Semantics*: Gradable adjectives and adverbs are treated as measurement relations over normalized scale sets (e.g., `0 ~ 1`).
    *   *Questions*: Represented via named placeholder variables (holes) awaiting contextual resolution.
*   **Arbitrary Tree and DAG Topologies**:  
    Because postfix chains can construct arbitrary nested relational trees (`S S R S S R R R`), and dynamic anaphora (`Upload` / `Download`) enables cross-branch reference, the system naturally expresses arbitrary Directed Acyclic Graphs (DAGs).

*(Note: A detailed philosophical and technical exposition of the Relational Annotation Model is documented in `English/OtherNotes.txt` / `中文/其他说明.txt`.)*

---

## 📂 Repository Structure

```text
.
├── English/
│   ├── OriginalDraft.txt    # Complete formal reduction rules (v1.0), macro library, and 8 benchmark traces
│   └── OtherNotes.txt       # Conceptual notes, linguistic rationale, and theoretical expansions
├── 中文/
│   ├── 原始草稿.txt          # v1.0 形式规约规则集、全套核心宏模板与 8 个基准测试推导记录
│   └── 其他说明.txt          # 架构设计思想、关系批注模型与语言学功能构想说明
├── src/
│   └── Main.hs              # Reference implementation (Haskell prototype)
└── README.md                # Project documentation (Bilingual)
```

> **Detailed Formal Rules & Examples**:  
> For the complete specification of the 29 reduction rules, all macro definitions (connectives, scale modifiers, donkey macros, combinators), and full execution trace states for the 8 benchmark sentences, please refer directly to:
> *   `English/OriginalDraft.txt` (English)
> *   `中文/原始草稿.txt` (Chinese)

---

<a id="中文"></a>
# SML (中文)

> 基于“六栈一流水一标量寄存器八映射”（6-Stack 1-Stream 1-Register 8-Map）串接式状态机的形式语义推导引擎与逻辑语言（Loglang）架构。

> [!NOTE]
> **当前状态：试验性形式规范与原型系统 (v1.0)**  
> 本项目目前处于试验性形式规范与原型机探索阶段。核心状态机规约引擎已在 8 个具有代表性的典型基准用例（涵盖多层嵌套动词定语从句、广义受限量词、经典驴子句、标度语义学、置换栈动态流水线以及双轨否定）上完成了推导自洽性验证。系统目前仅进行了有限用例的初步验证，仍有待更广泛的语料测试、自动化模糊测试（Fuzzing）与严格形式化证明。

---

## 🚀 项目概述

经典形式语义学（如蒙太格语法）高度依赖句法树递归、类型驱动的应用与量词提升（QR）；而传统人造逻辑语（如 Lojban）则普遍将谓词固定为刚性的位点结构（`x₁, ..., xₙ`），这不仅带来了沉重的词汇位点记忆负担，还需要依靠庞杂的括号终止符（`ku`, `vau`, `kei` 等）来消除句法歧义。

**SML (Stack-Map-Loglang) v1.0** 探索了一种**去语法树化的串接式线性状态机**路径。

系统将语言中的实词统一抽象为单目基底集合（`:S`），动作统一本体化为一阶事件个体（`Ω`），多元关系统一分解为二元谓词（`:R`）。通过等待栈（`WT`）上的高阶延续闭包、限制域与核域的双轨映射（`Imap` / `Omap`）、焦点单值寄存器（`⟨F⟩`）与排列流水线栈（`PR`），SML 旨在不构建显式句法树、不书写闭合括号的前提下，线性求解复杂量词辖域、深层嵌套与并列定语从句，以及细粒度题元否定。

---

## 🏗️ 抽象机模型 (v1.0)

```text
State = ⟨ IP, NM, QN, WT, CM, PR, OP, ⟨F⟩, Imap, Omap, Qmap, Smap, Mmap, Fmap, Emap, Map ⟩
```

### 1. 六个线性栈 + 一个自然数流 + 一个标量寄存器（均以右端为栈顶）

| 组件名称 | 缩写标识 | 功能说明 |
| :--- | :--- | :--- |
| **输入栈** | **IP** | 待执行的指令块、Token 流与解包后的宏指令序列。 |
| **数字流** | **NM** | 预置无限递增自然数生成器（`1, 2, 3, ...`），为新实体分配全局唯一数值标号。 |
| **量化栈** | **QN** | 论元实体排队栈，维护等待执行受限量词闭包（`Build !`）的实体队列。 |
| **等待栈** | **WT** | 暂存区，维护高阶柯里化延续闭包（`λa. B`）、实体中间态及修饰语极性。 |
| **成分栈** | **CM** | 规约完毕的论元实体及真值极性游标栈（格式为 `Polarity Entity`）。 |
| **排列栈** | **PR** | 置换群操作流水线，用于动态调整量化置换元组与执行顺序。 |
| **输出栈** | **OP** | 即时运算与规约工作台，执行原子规约、布尔逻辑及关系连接触发。 |
| **焦点寄存器** | **`⟨F⟩`** | 标量整数寄存器，记录当前正在执行闭包的核心宿主实体标号。 |

### 2. 八个关联映射表（键均为实体数字标号）

| 映射表 | 缩写标识 | 用途说明 |
| :--- | :--- | :--- |
| **限制域映射** | **Imap** | 累积名词内涵修饰与定语从句条件（`{α_i ∈ S_i \| Imap[i]}`）。 |
| **核域映射** | **Omap** | 累积主谓陈述命题。 |
| **量化映射** | **Qmap** | 记录实体的广义量词类型（缺省为 `Exist` / ∃）。 |
| **集合映射** | **Smap** | 记录实体所属的基底类别名称或事件空间（如 `"猫"`, `"Ω"`）。 |
| **模式映射** | **Mmap** | 写入模式布尔值：`True` 表示内模式（写入 `Imap`），`False` 表示外模式（写入 `Omap`）。 |
| **焦点标记** | **Fmap** | 标记该实体是否为当前定语从句受保护的宿主。 |
| **环境映射** | **Emap** | 动态变量别名映射，用于跨子句代词照应与驴子句消解（`Upload` / `Download`）。 |
| **全局宏映射** | **Map** | 全局词汇字典，建立从集合名称字符串到对应格框宏代码的映射。 |

---

## 💡 v1.0 核心设计演进

*   **名谓词本体平权（Noun-Verb Parity）**：  
    动词不再拥有特殊的固定语法位点，而是作为普通的集合词（`:S`）进入成分栈。在遇到执行触发时，通过全局字典 `Map` 动态解构出二元题元格框与主事件 `Ω`，使动词天然能像名词一样接受定语从句修饰。
*   **WT 栈柯里化延续闭包（Currying Continuation）**：  
    将关系修饰与延迟装配抽象为驻留在 `WT` 栈上的高阶 `λ` 闭包，当宿主实体就位时自动触发代换求值，消除了串接式语言逆波兰序与人类前置修饰语习惯的冲突。
*   **广义量词双轨切分（`Imap` 与 `Omap` 对偶）**：  
    严格划分限制域与核域，配合模式翻转，原生支持蒙太格广义量词理论（GQ Theory，如“多于一半”等比例量词）。
*   **标量焦点寄存器 `⟨F⟩` 与宿主原位复位**：  
    通过 `释放宏`（探测 `Fmap` 并按需引渡）与原子复位机制，彻底废除了旧版的专用从句栈，且对称统一了嵌套从句与并列从句。
*   **排列栈流水线与皮亚诺列表递归**：  
    引入置换群生成元思想与列表剥离递归（Church-Peano 计数），消除了传统固定元数量化宏的阶乘爆炸问题。

---

## 🌐 语言学哲学：开放的“关系批注模型”

SML 在语言哲学上**放弃了在语法底层硬编码特定形而上学或物理学模型的做法**（不预设特定的绝对时空观，也不在语法中硬编码固定的克里普克可能世界集合）：

*   **语法作为不可知论拓扑画布**：  
    底层抽象机仅保障拓扑守恒（`ΔR = ΔS`）与广义受限量词闭包的严密性，把世界观的解释权彻底交还给说话者。
*   **语言即批注（Annotative Model）**：  
    浩瀚的语言学范畴被统一为向核心实体或事件追加的二元修饰边（`R`）：
    *   *时态与体貌*：作为事件变元的二元时空坐标挂载（如 `发生于(e, t)`、`参考系(e, 地表)`）；
    *   *情态与可能性*：作为渐进的程度与证据批注（如 `可能性(e, 0.5)`、`证据源(e, 亲眼所见)`）；
    *   *标度语义学*：形容词与副词被视作在规范化度量区间（如 `0 ~ 1`）上的二元测度关系与量化变换；
    *   *疑问句*：视为保留未封闭占位符变元（Named Holes）的开放模板查询。
*   **从树状修饰到有向无环图（DAG）**：  
    串接操作能够通过 `S S R S S R R R` 构造出任意复杂的嵌套修饰树；配合代词照应机制（`Upload` / `Download`），各分支节点可跨作用域建立有向边，使语言表达力自然覆盖任意有向无环图（DAG）。

*(注：关于“关系批注模型”的详细理论探讨与语言学构想，请参见 `中文/其他说明.txt` / `English/OtherNotes.txt`。)*

---

## 📂 仓库目录结构

```text
.
├── English/
│   ├── OriginalDraft.txt    # v1.0 英文版完整形式规约规则、核心宏库与 8 个测试例句运行追踪
│   └── OtherNotes.txt       # 英文版理论构想、语言学功能分析与扩展说明
├── 中文/
│   ├── 原始草稿.txt          # v1.0 中文版形式规约规则集、核心宏模板与 8 个测试例句状态输出
│   └── 其他说明.txt          # 中文版架构设计哲学、关系批注模型与后续扩展规划
├── src/
│   └── Main.hs              # 规约状态机参考实现代码（Haskell 原型）
└── README.md                # 双语项目主文档
```

> **具体规则集与推导例句查阅说明**：  
> 本 README 旨在阐述系统架构模型与设计思想，不罗列具体推导过程。关于完整的 29 条规约规则定义、全套核心宏模板代码，以及 8 个基准测试例句的完整机器状态追踪（Machine State Trace），请直接查阅：
> *   `中文/原始草稿.txt`（中文完整规约）
> *   `English/OriginalDraft.txt`（英文完整规约）
