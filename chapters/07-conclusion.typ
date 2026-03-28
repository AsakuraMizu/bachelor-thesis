#import "../template.typ": todo

= 总结与展望

== 工作总结

#todo[
  3-4 段，逐一总结各章的主要工作和成果：
  + 系统背景与总体架构：明确 StarryOS 的设计目标、系统定位与整体结构
  + 核心子系统实现：完成兼容性内核的基本盘，实现 200+ Linux 系统调用并支撑 Alpine 生态
  + 关键机制与性能优化：组件化设计探索（extern_trait、用户态切换）以及访存、
    缓冲区、异步 I/O、多级缓存等优化
  + AI 应用支持探索：面向 AIoT 场景的 NPU 驱动与应用运行支持方向
]

== 未来工作展望

#todo[
  2-3 段，说明后续计划：
  - 多核调度优化（参考 KRR 等工作）
  - 虚拟内存优化（参考 CortenMM，取消 VMA 抽象）
  - NPU 驱动完善与 AI 应用落地
  - 组件进一步开源复用（已有 weak-map、extern-trait、scope-local 等发布计划）
]
