#!/usr/bin/env -S typst c
#import "imports.typ": *
#import "template.typ": *

#import tntt: define-config, use-size

#show: codly-init.with()
#codly(
  languages: codly-languages,
)

/// 以下字体配置适用于安装了 Windows 10/11 字体及 Windows 10/11 简体中文字体扩展的设备，
/// 请勿修改 font-family 中定义的键值，除 Math 数学字体外，修改西文字体时请使用 `latin-in-cjk` 覆盖字体范围
///
/// 对于 MacOS 用户，可以使用 `Songti SC`、`Heiti SC`、`Kaiti SC`、`Fangsong SC` 和 `Menlo` 作为替代
///
/// 对于 Linux 用户，可以使用 `Source Han Serif`、`Source Han Sans`、`Source Han Mono` 或文泉驿字体等进行配置
#let font-family = (
  SongTi: ((name: "Times New Roman", covers: "latin-in-cjk"), "NSimSun"),
  HeiTi: ((name: "Arial", covers: "latin-in-cjk"), "SimHei"),
  KaiTi: ((name: "Times New Roman", covers: "latin-in-cjk"), "KaiTi"),
  FangSong: ((name: "Times New Roman", covers: "latin-in-cjk"), "FangSong"),
  Mono: ((name: "DejaVu Sans Mono", covers: "latin-in-cjk"), "SimHei"),
  Math: ("New Computer Modern Math", "KaiTi"),
)

#let (
  ..config,
  /// global utilities
  use-fonts,
  use-en-font,
  use-cjk-fonts,
  use-twoside,
  /// layouts
  meta,
  doc,
  front-matter,
  main-matter,
  back-matter,
  /// pages
  fonts-display,
  cover,
  cover-en,
  spine,
  committee,
  copyright,
  abstract,
  abstract-en,
  outline-wrapper,
  master-list,
  figure-table-list,
  figure-list,
  table-list,
  equation-list,
  notation,
  bilingual-bibliography,
  acknowledge,
  declaration,
  achievement,
  record-sheet,
  comments,
  resolution,
) = define-config(
  // 学位层级，可选值: bachelor, master, doctor, postdoc
  // 模板内容会根据学位自动调整，对于不需要的内容会自动忽略
  degree: "bachelor",
  degree-type: "academic",
  anonymous: false, // 盲审模式
  twoside: false, // 双面模式，会加入空白页，便于打印
  // 如下的信息会写入到 PDF 元数据中
  info: (
    title: "AIoT操作系统性能优化关键技术研究",
    // 等价于（如果你需要将标题用 content 表示，请用下面的写法）
    // title: ("清华大学学位论文 Typst 模板", "使用示例文档"),
    author: "王铮",
    // 论文提交日期，封面仅显示年月，但具体日期会写入到 PDF 元数据中
    date: datetime.today(),
    // 指定论文提交日期，可填写任意时间
    // date: datetime(year: 2026, month: 5, day: 30),
    // （并不建议）将日期具体到时分秒，需要自行换算到 UTC 时间
    // 如下设置日期为北京时间 2026 年 5 月 30 日 10:30 AM，对应 UTC 时间的 2:30 AM
    // date: datetime(year: 2026, month: 5, day: 30, hour: 2, minute: 30, second: 0),
  ),
  bibliography: read("ref.bib"), // 参考文献源
  fonts: font-family, // 应用字体配置
)

// 文稿设置，默认应用 LaTeX/i-figured 引用兼容模式（引用标签时可添加 `fig:` 等前缀）
#show: it => meta(it)
// 等价于如下写法
// #show: meta
// 但由于技术限制，该写法会导致 meta 的类型提示损坏，因而此处显式使用函数调用

// 字体展示测试页，在配置好字体后请注释或删除此项
// #fonts-display()

// 中文封面页
#cover(
  // 用于中文封面的额外信息
  info: (
    department: "计算机科学与技术系",
    major: "计算机科学与技术",
    // 学位名称，可按学术类型或是工程类型编写，对本科生无效
    degree-name: "学士",
    supervisor: ("陈渝", "副教授"),
  ),
)

/// ----------- ///
/// Doc Layouts ///
/// ----------- ///
#show: it => doc(it)

// 授权页
#copyright()

/// ------------ ///
/// Front Matter ///
/// ------------ ///
#show: it => front-matter(it)

// 中文摘要
// 默认情况下会将中文关键词和摘要内容嵌入到 PDF 中，设置 embeded 为 false 可禁用该行为
#abstract(keywords: ("AIoT", "操作系统", "性能优化", "ArceOS", "Starry"))[
  #todo[填写中文摘要]
]

// 英文摘要
#abstract-en(keywords: ("AIoT", "Operating System", "Performance Optimization", "ArceOS", "Starry"))[
  #todo[填写英文摘要]
]

// 目录
#outline-wrapper()

// 总清单
// #master-list()

// 插图和附表清单
// #figure-table-list()

// 插图清单
#figure-list()

// 附表清单
#table-list()

// 公式清单
// #equation-list()

// 符号表
// 建议按符号、希腊字母、缩略词等部分编制，每一部分按首字母顺序排序。
#notation[
  / AIoT: Artificial Intelligence of Things，人工智能物联网
  / OS: Operating System，操作系统
]

/// ----------- ///
/// Main Matter ///
/// ----------- ///
#show: it => main-matter(it)

#include "main.typ"

/// ----------- ///
/// Back Matter ///
/// ----------- ///
#show: it => back-matter(it)

// Typst 使用 CSL 样式来处理参考文献，但由于 CSL 样式自身约束性有限
// 因而模板对 gb-7714-2015-numeric 进行了一定的修改
// 中英双语参考文献，默认使用 gb-7714-2015-numeric 样式，设置 style 以切换样式
// #bilingual-bibliography(style: "gb-7714-2015-author-date")
// 除了内置的样式外，style 也接受 CSL 路径，相关内容请参考 Typst 的官方文档
#bilingual-bibliography()

= 外文资料的调研阅读报告（或书面翻译）

#align(center)[调研阅读报告题目（或书面翻译题目）]

写出至少 5000 外文印刷字符的调研阅读报告或者书面翻译 1-2 篇（不少于2 万外文印刷符）。

== #lorem(3)

=== #lorem(3)

#v(22pt)

#align(center)[参考文献（或书面翻译对应的原文索引）]

#{
  set text(size: use-size("五号"))

  set enum(
    body-indent: 20pt,
    numbering: "[1]",
    indent: 0pt,
  )

  [
    + 某某某. 信息技术与信息服务国际研讨会论文集: A 集［C］北京：中国社会科学出版社，1994.
  ]
}

= 其他附录内容

#todo[填写其他附录内容（如有）]

// 致谢
#acknowledge[
  #todo[填写致谢内容]
]

// 声明页
// 对于本科生和硕士生及以上会应用不同的样式，也可以自定义输入内容
#declaration()

// 论文训练记录表，仅适用于本科生的综合论文训练
#record-sheet(
  // 补充学生基本信息
  info: (
    student-id: "2022010862",
    class: "计26",
  ),
  // 主要内容以及进度安排
  content: [
    #v(2em)

    *主要内容*：

    *进度安排*：
  ],
  // 中期检查评语
  mid-term-comment: [],
  // 指导教师评语
  instructor-comment: [],
  // 评阅人评语
  reviewer-comment: [],
  // 答辩委员会评语
  defense-comment: [],
)
