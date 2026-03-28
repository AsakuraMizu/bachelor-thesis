#import "../template.typ": todo

= 实验评测

#todo[
  开头一段：说明本章从功能完整性、应用兼容性和性能三个维度对 StarryOS 进行评测，
  包括操作系统大赛标准测例、实际应用验证，以及关键性能基准测试。
]

== 实验环境

#todo[
  简述测试所用的硬件平台（x86/riscv64/aarch64 等架构、QEMU 版本）
  和软件环境（Rust 工具链版本、Alpine Linux 镜像版本等）。
]

== 功能完整性评测

=== 系统调用测例

#todo[
  介绍操作系统大赛的标准测例套件，
  说明 StarryOS 的通过情况（可配表格，对比赛道测例通过率）。
]

=== 应用兼容性测试

#todo[
  展示在 Alpine Linux 下运行实际应用的验证结果，包括：
  - 开发工具链（GCC 编译、Cargo 构建、Git 操作）
  - 图形应用（X11/dwm + ImageMagick 等）
  - 其他典型应用（Python、SQLite、Redis、xv6 嵌套运行等）
  可用截图或描述性文字。
]

== 性能评测

#todo[说明性能测试的方法和基准（lmbench、UnixBench 或自定义 microbenchmark）。]

=== 系统调用开销

#todo[
  测试典型系统调用（getpid、read、write 等）的延迟，
  与 Linux 基线对比。
]

=== I/O 性能

#todo[测试文件读写吞吐量，体现异步机制和多级缓存优化的效果。]

== 优化效果分析

#todo[
  将第 4 章提出的关键机制与优化点和实验结果对应起来，
  分析其对系统吞吐量、延迟和资源利用率的影响。
]

== 开发工作量统计

#todo[
  统计整体工作量，参考 thuthesis-zyj 表 5.3 的形式：
  主仓库新增代码行数、子仓库数量、commit 数量等。
]

== 本章小结

#todo[
  总结实验结果，说明 StarryOS 在功能完整性、应用兼容性和性能方面的整体表现。
]
