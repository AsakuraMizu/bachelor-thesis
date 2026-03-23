#import "../template.typ": todo

= 系统设计

#todo[开头一段：说明本章在 ArceOS 已有组件化基础上，进一步探索宏内核场景下的关键设计问题，涵盖组件化机制、用户态切换，以及高效内核-用户交互的设计。]

== ArceOS 组件化基础

=== 组件层次结构

#todo[
  介绍 ArceOS 的组件层次划分（axhal / axruntime / modules / crates / apps），
  配一张层次结构图（参考 thuthesis-zyj 图3.1）。
]

=== Rust 组件化开发的挑战

#todo[
  说明 Rust 依赖树在编译时必须 resolve 的特性，举 `#[panic_handler]`、
  `#[global_allocator]` 等典型反向依赖例子，说明这在 OS 开发中尤为突出。
]

=== crate_interface 机制

#todo[
  简述 crate_interface 解决的问题（跨 crate 的接口定义与实现解耦），
  指出其局限性（不支持复杂类型传递、RAII 语义受限），引出 extern_trait 的动机。
]

== extern_trait 机制

=== 设计动机

#todo[
  对比 `Box<dyn Trait>`、`*mut ()` 等现有方案的不足（overhead、内存安全、
  需要动态分配），说明 extern_trait 的设计目标。
]

=== 实现原理

#todo[
  说明 extern_trait 的核心思想：通过过程宏在编译期生成调用桩，
  实现零开销的跨 crate 接口调用，支持任意类型和 RAII 语义。可附代码示例。
]

=== 应用场景

#todo[
  列举在 StarryOS 中的具体应用（TaskExt、on_enter/on_leave/drop 等），
  以及已发布/计划发布到 crates.io 的情况（extern-trait crate）。
]

== 用户态切换机制

=== 传统宏内核的问题

#todo[
  说明传统宏内核"用户程序调用内核"模式对组件化的影响：
  对用户程序流控制能力差，难以将控制流逻辑组件化（注册回调等方式的局限）。
]

=== 反转控制流设计

#todo[
  说明 StarryOS 的设计：内核代码"调用"用户程序，主动控制用户程序流，
  对比 Asterinas 的类似思路，说明其对组件化架构的意义。
]

=== 基于 axcpu 的实现

#todo[
  简述 axcpu 组件的职责（封装用户态/内核态切换的底层机制），
  说明实现难点及关键设计决策。
]

== 高效“内核-用户”交互设计

=== 用户内存访问机制

#todo[
  说明内核访问用户内存的设计目标——零额外开销（无异常时）。
  介绍 Exception Fixup 机制：在汇编层面处理页异常并保证控制流不受破坏，
  参考 Linux 的实现思路，在没有异常发生时不存在额外开销。
]

=== 缓冲区抽象设计

#todo[
  说明传统 `read`/`write` 接口（`&mut [u8]`）在处理用户数据时需要额外分配与拷贝的问题。
  介绍 Buf/BufMut 抽象：统一内核与用户缓冲区，大部分场景实现 one-copy I/O，
  说明其与 Linux 设计的契合性，以及更 Rusty 的接口特点。
]

== 异步机制设计

=== 设计目标

#todo[
  说明异步机制的目标：消除低效轮询，在 I/O 瓶颈场景下提升吞吐量。
  分析纯同步与纯异步实现各自的优缺点，引出混合方案的必要性。
]

=== 同步+异步混合架构

#todo[
  介绍 Waker/Poller 机制：PollSet（无锁单向链表存储 Waker）、
  Pollable 接口（poll + register），以及 Poller 实现的核心逻辑。
  说明如何兼容 POSIX poll 语义。可附架构图。
]

=== 与信号和硬件的集成

#todo[
  说明异步机制与信号（可中断的系统调用）的交互，
  以及外设中断（VirtIO 网卡/输入、UART）通过注册 Waker 实现硬件唤醒的机制。
]

== 整体组件架构

=== 仓库拆分与解耦设计

#todo[
  说明将 StarryOS 拆分为 30+ 个独立代码仓库的设计原则，
  各仓库的功能边界，以及如何通过接口隔离保持可维护性。
]

=== 组件复用与开源实践

#todo[
  介绍已被其他团队复用的组件（如被 Starry X、undefined 等队伍使用），
  以及计划发布到 crates.io 的组件（weak-map、scope-local、extern-trait 等）。
]
