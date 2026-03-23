#import "../template.typ": todo

= 绪论

== 研究背景

=== 操作系统内核架构的演进

#todo[
  简要介绍宏内核、微内核、Unikernel 三种架构的设计权衡（性能/隔离/灵活性），
  说明各自的适用场景与局限性。可配一张对比表格（参考 thuthesis-zyj 表2.1）。1-2段。
]

=== 组件化操作系统与 ArceOS

#todo[引出组件化设计理念，介绍 ArceOS 的灵活内核原则（One Architecture to build all）]

=== Starry OS 的发展

#todo[梳理 Starry-Next → Starry Mix → StarryOS 主线的演进历程]

== 相关工作

#todo[
  每类2-3句话即可：
  - 其他 Rust OS：Asterinas（Framekernel）、Theseus、Tock
  - Linux 兼容性内核：gVisor、Graphene/Occlum（TEE场景）
  - 性能优化相关：io_uring、CortenMM（SOSP'25最佳论文）
]

== 本文工作

#todo[
  分3-4段简述本文主要贡献：
  + 组件化设计探索（extern_trait、用户态切换机制、30+仓库解耦）
  + 兼容性内核实现（200+ syscall、Alpine Linux 生态）
  + 性能优化（用户访存、缓冲区抽象、异步I/O、多级缓存）
  + AI 应用支持方向（展望）
]
