# AGENTS.md

本文件为清华大学本科毕业论文《AIoT操作系统性能优化关键技术研究》提供项目上下文与AI编码代理工作指南。

## 项目概述

本论文使用 Typst 编写，采用 `tntt`（清华大学学位论文模板）。论文主题为面向 AIoT 场景的操作系统性能优化，聚焦于基于 ArceOS 构建的 Linux 兼容性内核 StarryOS。

## 编译指令

```bash
# 编译论文（需指定字体路径）
typst compile thesis.typ --font-path fonts

# 监听模式 - 文件变更时自动重编译
typst watch thesis.typ --font-path fonts

# 指定输出路径
typst compile thesis.typ output.pdf --font-path fonts

# 仅检查编译错误
typst compile thesis.typ --font-path fonts 2>&1 | head -50
```

## 项目结构

```
bachelor-thesis/
├── thesis.typ          # 主配置与文档入口
├── main.typ            # 章节文件汇总
├── imports.typ         # 第三方依赖包导入
├── template.typ        # 本地定制工具定义
├── ref.bib             # 参考文献（GB/T 7714-2015 格式）
├── fonts/              # 本地中文字体文件
├── chapters/           # 各章节
│   ├── 01-intro.typ           # 绪论
│   ├── 02-architecture.typ    # 系统背景与总体架构
│   ├── 03-subsystems.typ      # 核心子系统设计与实现
│   ├── 04-key-mechanisms.typ  # 关键机制与性能优化
│   ├── 05-ai-application.typ  # AI应用支持
│   ├── 06-evaluation.typ      # 实验评测
│   └── 07-conclusion.typ      # 总结与展望
└── .vscode/settings.json      # VSCode/Tinymist 字体路径配置
```

### 核心文件职责

| 文件 | 职责 | 内容 |
|------|------|------|
| `thesis.typ` | 文档入口 | 字体配置、模板参数、封面与摘要、章节引入 |
| `imports.typ` | 第三方依赖 | tntt、fletcher、lovelace、codly 等包的导入 |
| `template.typ` | 本地工具 | 自定义函数（如 `todo` 占位符） |
| `main.typ` | 章节汇总 | 按顺序 `#include` 各章节文件 |

章节文件可按需导入上述内容：

```typst
// 仅导入需要的工具
#import "../template.typ": todo

// 或 glob 导入全部（类似 thesis.typ 的做法）
#import "../imports.typ": *
#import "../template.typ": *
```

## 写作规范

### 语言

- 正文使用简体中文
- 技术术语首次出现时可采用"中文（English）"格式，或直接使用通用英文术语
- 代码、标识符、变量名等仅使用英文
- 图表标题使用中文

### 文件与标签命名

- 章节文件：`NN-topic.typ`，NN 为两位章节号
- 引用标签：使用前缀区分，如 `fig:`、`tab:`、`sec:`、`eq:`
- 参考文献键：`authorYYYYkeyword` 格式，如 `klabnik2023rust`

### 章节组织

每章文件应：
1. 按需导入 `imports.typ` 或 `template.typ` 中的内容
2. 以一级标题开头（`= 章节标题`）
3. 结尾包含"本章小结"节
4. 待完善内容使用 `#todo[...]`

### 占位符

使用 `todo` 函数标记待完善内容：

```typst
#todo[简述设计动机]

#todo[
  Point 1: description
  Point 2: description
]
```

### 参考文献

引用格式为 `@cite_key`，参考文献库 `ref.bib` 遵循 GB/T 7714-2015 标准：

```typst
// 正文引用
根据 @klabnik2023rust 的论述...

// 多引用
@panter2024rustylinux; @li2024rustlinux
```

```bib
@book{klabnik2023rust,
  author    = {Klabnik, Steve and Nichols, Carol},
  title     = {The Rust Programming Language},
  publisher = {No Starch Press},
  year      = {2023},
}
```

## AI代理任务

本论文内容已基本定稿，AI代理主要承担以下文字工作：

1. **撰写**：根据大纲或要求扩写指定章节段落，保持学术写作风格与逻辑连贯
2. **评审**：检查段落逻辑、术语一致性、引用规范性，指出表述不清或论证不足之处
3. **修改**：根据评审意见或用户反馈调整措辞、修正错误、优化表达

修改后应运行 `typst compile thesis.typ --font-path fonts` 验证编译无误。

## 工具使用注意事项

### 中文文件编辑问题

OpenCode 的 `edit` 工具对包含中文或其他多字节 Unicode 字符的文件存在已知 bug（相关 issue: #2904）。具体表现为：

- `edit` 工具无法精确匹配包含中文的文本片段，即使复制粘贴也无法找到匹配
- 错误信息：`Could not find exact match for edit` 或 `oldString not found in content`
- 根因：工具内部对 UTF-8 多字节字符的处理存在缺陷

**解决方案**：编辑中文 `.typ` 文件时，按以下优先级尝试：

1. 先用 `edit` 工具尝试小片段替换
2. 若失败，扩大范围尝试整段替换（以换行符为界）
3. 最后才用 `write` 工具重写整个文件

注意：git 仅能保护已提交的内容，未提交的更改丢失后无法恢复，因此修改前应确认当前内容状态。

### 写作风格检查

评审论文时应重点关注以下"AI味"特征：

- "根据设计文档"、"从代码形态看"等元叙述表述
- "对论文写作而言"等自我指涉语句
- 过度使用"从...角度看"等套话开头
- 逻辑跳跃或段落间缺乏自然过渡
- 口语化表达混入学术文本

## 依赖包

| 包名 | 版本 | 用途 |
|------|------|------|
| tntt | 0.5.0 | 清华学位论文模板 |
| fletcher | 0.5.8 | 流程图绘制 |
| lovelace | 0.3.1 | 格式扩展 |
| codly | 1.3.0 | 代码高亮 |
| codly-languages | 0.1.10 | 语言定义 |

## 字体配置

字体在 `thesis.typ` 中配置，包括宋体（正文）、黑体（标题）、楷体（摘要/引用）、仿宋（特殊段落）、等宽字体（代码）。VSCode Tinymist 扩展的字体路径已在 `.vscode/settings.json` 中设置。