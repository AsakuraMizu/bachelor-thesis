#import "../template.typ": todo

= 总结与展望

== 工作总结

#todo[
  3-4段，逐一总结各章的主要工作和成果：
  + 组件化设计探索（extern_trait、用户态切换）
  + 兼容性内核实现（200+ syscall、Alpine生态）
  + 性能优化（访存、缓冲区、异步I/O、缓存）
  + AI应用支持探索
]

== 未来工作展望

#todo[
  2-3段，说明后续计划：
  - 多核调度优化（参考 KRR 等工作）
  - 虚拟内存优化（参考 CortenMM，取消VMA抽象）
  - NPU 驱动完善与 AI 应用落地
  - 组件进一步开源复用（已有 weak-map、extern-trait、scope-local 等发布计划）
]
