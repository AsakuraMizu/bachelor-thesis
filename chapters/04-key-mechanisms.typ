#import "../template.typ": todo

= 关键机制与性能优化

在完成兼容性内核基本功能之后，StarryOS 面临的主要问题不再只是“是否具备某项能力”，而是“这些能力能否以可维护、可复用且足够高效的方式组织起来”。一方面，ArceOS/StarryOS 所坚持的组件化路线要求系统在 Rust 严格的依赖与类型约束下处理复杂的跨模块协作；另一方面，Linux 兼容性内核在用户态访存、I/O 路径、事件等待与缓存管理上天然存在显著的性能压力。因此，本章聚焦于若干真正影响系统结构和性能上限的关键机制，说明系统在组件化实现与性能优化之间所做的设计取舍。

== Rust 组件化开发的挑战

Rust 的模块与包管理机制天然强调依赖关系在编译期的静态确定，这使其在构建大型系统时能够获得良好的类型安全与优化效果，但也会给组件化操作系统开发带来特殊挑战。对于内核而言，某些功能依赖并不总是沿着“底层依赖上层”的单向路径展开。例如，底层组件有时需要回调上层提供的能力，或者在抽象数据结构中挂接由上层定义的扩展状态；再如 `#[panic_handler]`、`#[global_allocator]` 这类入口级能力，往往天然表现出一种“反向依赖”的特征。与 C 语言更多在链接阶段解决符号关系不同，Rust 需要在更早阶段就将这些依赖明确下来，因此会更早暴露出组件边界不清或依赖方向不合理的问题。

这一问题在操作系统开发中尤为突出。操作系统内部模块数量多、层次深，而且控制流和资源关系往往比普通应用程序更复杂，简单地通过重新组织调用顺序并不能完全消除循环依赖或跨层扩展需求。因此，如何在不破坏 Rust 类型系统和性能优势的前提下，为上层模块向下层注入实现、为下层模块保留可扩展接口，就成为组件化宏内核设计中的一个核心问题。后文介绍的 `extern_trait` 机制，正是在这一背景下提出的。

== extern_trait 机制

=== 设计动机

在组件化操作系统开发中，跨 crate 的接口定义与实现解耦是一个核心需求。ArceOS 项目早期引入的 `crate_interface` 机制正是为解决这一问题而设计：它允许在一个 crate 中定义 trait 接口，在另一个 crate 中提供实现，然后通过链接器符号在运行时连接。这种方式成功避免了循环依赖，使底层模块能够调用上层提供的能力，例如日志模块调用平台层提供的 `console_write_str` 函数。

然而，`crate_interface` 的设计存在若干局限性。首先，它不支持带接收者参数的方法（`&self`、`&mut self`），只能定义关联函数，因此无法表达具有状态的接口。更重要的是，它无法自动处理 RAII 语义——当实现类型需要资源清理时，调用方必须显式调用某种 `drop` 方法，这不仅破坏了 Rust 的所有权语义，也增加了使用复杂度。

面对这些局限，常见的替代方案也存在明显缺陷。`Box<dyn Trait>` 虽然能完整表达 trait 语义，但需要堆分配每个 trait 对象，且每次方法调用都要经过 vtable 进行间接寻址，在内核性能敏感路径上代价过高。另一种极端方案是使用 `*mut ()` 进行手动类型擦除，这虽然避免了堆分配和间接调用，但完全依赖 unsafe 代码进行类型转换，极易引入内存安全漏洞。这些方案要么牺牲性能，要么牺牲安全性，难以满足操作系统内核的需求。

值得注意的是，Rust 语言团队正在推进的 EII（Externally Implementable Items）特性试图从语言层面解决类似问题。该特性采用属性语法，使用 `#[eii(...)]` 定义可外部实现的函数或静态变量，使用同名属性提供实现，类似于 `#[panic_handler]` 和 `#[global_allocator]` 的机制。但这一特性的 RFC 尚未正式合并，目前仅处于实验阶段（`#![feature(extern_item_impls)]`），且仅支持函数而非完整的 trait 语义。因此，StarryOS 需要一种既能获得完整 trait 语义，又不依赖 nightly 特性的解决方案。

`extern_trait` 机制正是在这一背景下设计的。它的核心目标是：在不依赖语言层面修改的前提下，通过过程宏实现零开销的跨 crate trait 调用，支持带接收者的方法、自动 RAII 处理，并保持完整的类型安全。与 Rust 官方的 EII 特性相比，它作为第三方库可在 stable Rust 上使用，并且提供更完整的 trait 支持；与传统的动态分派方案相比，它在编译期完成所有决议，在链接时绑定具体实现，避免了任何运行时开销。

=== 实现原理

`extern_trait` 的实现基于一个核心观察：在大多数调用约定中，大小不超过两个指针的结构体可以通过寄存器直接传递，无需经过栈内存。这一观察启发了一种"静态 vtable"的设计思路——将 trait 的方法分派从运行时的间接调用转变为链接时的直接符号绑定。

具体而言，`extern_trait` 通过过程宏完成三方面的工作。首先，在 trait 定义侧，宏生成一个固定大小的代理类型 `Repr`，其大小为两个指针（16 字节在 64 位平台，8 字节在 32 位平台），足以存储大多数常见的实现类型，如 `Box<T>`、`Arc<T>`、`&T` 以及胖指针 `&[T]`、`&str` 等。宏同时为该代理类型生成 trait 实现，其中每个方法都被替换为对外部符号的调用：

```rust
// 定义侧生成的代码（简化）
#[repr(transparent)]
pub struct HelloProxy(extern_trait::Repr);

impl Hello for HelloProxy {
    fn new(arg: i32) -> Self {
        extern "Rust" {
            #[link_name = "extern_trait_Hello_new"]
            fn __new(arg: i32) -> Repr;
        }
        Self(unsafe { __new(arg) })
    }

    fn hello(&self) {
        extern "Rust" {
            #[link_name = "extern_trait_Hello_hello"]
            fn __hello(this: &Repr);
        }
        unsafe { __hello(&self.0) }
    }
}

impl Drop for HelloProxy {
    fn drop(&mut self) {
        extern "Rust" {
            #[link_name = "extern_trait_Hello_drop"]
            fn __drop(this: *mut Repr);
        }
        unsafe { __drop(&mut self.0 as *mut _) }
    }
}
```

其次，在 trait 实现侧，宏生成对应的符号导出函数。每个 trait 方法都被包装为一个带有 `#[export_name]` 属性的函数，该函数接收 `Repr` 类型的参数，在其中完成实际实现类型的构造或方法调用：

```rust
// 实现侧生成的代码（简化）
struct HelloImpl(i32);

#[export_name = "extern_trait_Hello_new"]
extern "Rust" fn __new(arg: i32) -> Repr {
    Repr::from_value(HelloImpl::new(arg))
}

#[export_name = "extern_trait_Hello_hello"]
extern "Rust" fn __hello(this: &Repr) {
    let impl_ref: &HelloImpl = this.as_ref();
    impl_ref.hello();
}

#[export_name = "extern_trait_Hello_drop"]
extern "Rust" fn __drop(this: *mut Repr) {
    unsafe { ptr::drop_in_place(this.as_mut::<HelloImpl>()) };
}
```

最后，宏在编译期进行大小检查，确保实现类型能够容纳于 `Repr` 中。如果实现类型过大，编译时会触发静态断言错误，引导用户将类型包装在 `Box` 或其他指针类型中。

这种设计的关键优势在于：代理类型与实现类型之间通过链接器符号进行连接，而非通过运行时的 vtable。当调用方调用 `HelloProxy::hello()` 时，编译器生成的代码直接跳转到 `__hello` 符号，该符号在链接时被解析为实现 crate 中导出的函数地址。这消除了动态分派的开销，同时保持了完整的类型安全——所有类型转换都在宏生成的代码中完成，用户代码无需使用 unsafe。

对于 supertrait 的处理，宏会自动为代理类型生成相应的 trait 实现。例如，如果 trait 定义为 `trait Resource: Send + Sync + Clone + Debug`，则 `ResourceProxy` 会自动获得 `Send`、`Sync`、`Clone` 和 `Debug` 的实现，这些实现同样通过外部符号绑定，确保实现 crate 中提供的 supertrait 实现被正确传递。

=== 应用场景

`extern_trait` 机制在 ArceOS 和 StarryOS 中有着广泛的应用，其中最具代表性的场景是任务扩展机制（`TaskExt`）。

在 ArceOS 的调度器模块 `axtask` 中，`TaskExt` trait 被定义为任务切换时的回调接口：

```rust
#[extern_trait(pub AxTaskExt)]
pub trait TaskExt {
    fn on_enter(&self) {}
    fn on_leave(&self) {}
}
```

这一设计允许上层模块（如 StarryOS 的进程管理）向下层模块（调度器）注入任务切换时的自定义逻辑。在 StarryOS 中，`TaskExt` 被实现为 `Box<Thread>`，用于管理进程相关的上下文切换：

```rust
#[extern_trait]
impl TaskExt for Box<Thread> {
    fn on_enter(&self) {
        let scope = self.proc_data.scope.read();
        unsafe { ActiveScope::set(&scope) };
        core::mem::forget(scope);
    }

    fn on_leave(&self) {
        ActiveScope::set_global();
        unsafe { self.proc_data.scope.force_read_decrement() };
    }
}
```

通过这一机制，当调度器切换任务时，会自动调用 `on_enter` 和 `on_leave` 方法，完成进程资源作用域的切换。调度器模块无需了解进程管理的具体实现，只需在 `TaskInner` 结构中存储 `Option<AxTaskExt>` 字段，并在任务切换时调用相应方法即可。这种设计实现了底层调度逻辑与上层进程管理的完全解耦。

另一个重要应用是用户态内存访问接口 `VmIo`。在 StarryOS 的架构中，内存管理与内核核心高度相关，但信号处理等组件（`starry-signal`）也需要访问用户内存。为避免循环依赖，同时为后续的异常修复机制提供统一入口，引入了 `VmIo` trait。通过 `extern_trait`，`Vm` 类型可以作为跨模块的内存访问接口被传递和调用：

```rust
#[extern_trait]
unsafe impl VmIo for Vm {
    fn new() -> Self { Self(IrqSave::new()) }
    fn read(&mut self, start: usize, buf: &mut [MaybeUninit<u8>]) -> VmResult { ... }
    fn write(&mut self, start: usize, buf: &[u8]) -> VmResult { ... }
}
```

这使得文件系统、驱动、信号处理等模块可以在不依赖具体内存管理实现的情况下，通过统一的接口访问用户态数据，同时也为后续介绍的异常修复机制提供了接口层面的支撑。

目前，`extern_trait` 已作为独立 crate 发布于 crates.io @extern_trait，由本文作者开发维护。其设计灵感来源于 `crate_interface` 机制，但在功能完整性、类型安全和性能方面均有显著改进。随着 Rust 语言层面 EII 特性的推进，未来可能存在语言原生支持与库层实现之间的融合或迁移，但 `extern_trait` 在当下已为组件化操作系统开发提供了一种切实可用的解决方案。

== 用户态切换与反转控制流

=== 传统宏内核控制流的局限

传统宏内核通常将系统执行过程组织为“用户程序调用内核服务”的形式：用户态程序通过系统调用主动进入内核，内核在完成请求后再返回用户态继续执行。这种模式在概念上直观、实现上成熟，也是大多数经典操作系统教材默认采用的控制流描述方式。然而，当系统希望将更多控制流相关逻辑抽象为可复用组件时，这种结构会暴露出局限性。原因在于，内核虽然能够在陷入时临时接管控制权，却很难以统一方式主动组织用户程序执行的不同阶段，因此很多与进入用户态、离开用户态、任务切换相关的逻辑容易分散在不同位置，增加模块间耦合。

对于强调组件化的 StarryOS 而言，这种局限尤其明显。如果内核只能被动响应用户程序的调用，那么一些原本应当由统一机制处理的控制流操作，往往需要通过回调、全局状态或额外约定散落在不同模块中，不利于形成清晰边界。也正因为如此，StarryOS 在用户态切换机制上采取了更强调内核主动组织控制流的设计思路，从而为任务扩展、资源切换和后续的上下文管理提供更整洁的承载方式。

=== 反转控制流设计

StarryOS 采用了一种与传统宏内核不同的控制流组织方式。在传统模型中，用户程序通过系统调用主动进入内核，内核被动响应请求后返回用户态继续执行。这种被动响应模式虽然直观，但难以将用户态切换、任务调度、信号处理等逻辑组织为可复用的组件——它们往往分散在异常处理入口、系统调用路径、调度器等多个位置，通过隐式约定相互协调。

StarryOS 的设计则将控制权反转：内核代码主动"调用"用户程序，而非被动等待用户程序的调用。具体而言，每个用户任务的入口函数并非用户程序的 `main` 函数，而是一个内核循环，其核心结构如下：

```rust
while !thread.pending_exit() {
    let reason = user_context.run();  // 进入用户态

    match reason {
        ReturnReason::Syscall => handle_syscall(&mut user_context),
        ReturnReason::PageFault(addr, flags) => handle_page_fault(...),
        ReturnReason::Exception(info) => handle_exception(...),
        ReturnReason::Interrupt => {}
    }

    check_signals(&thread, &mut user_context);  // 处理信号
}
```

`user_context.run()` 是整个设计的关键：它将处理器从内核态切换到用户态，开始执行用户代码，直到发生系统调用、异常或中断时返回。返回后，内核在一个集中的位置处理各类事件，然后再次调用 `run()` 继续用户态执行。这种设计使内核能够以统一的方式组织控制流，而非在多个入口点分散处理。

这一设计思路与 Asterinas 项目@asterinas2024 的 `UserMode::execute()` 机制相似。Asterinas 同样采用内核主动调用用户程序的模式，其任务入口函数中包含一个循环，在每次用户态返回后处理系统调用、异常和信号。两个项目的设计都体现了将控制流逻辑集中化的思路，这为组件化架构提供了便利：信号处理、地址空间切换、FPU 状态管理等逻辑可以通过调度器回调（如前文所述的 `TaskExt::on_enter`/`on_leave`）注入到任务切换路径中，而非散落在各个异常处理入口。

=== 基于 axcpu 的实现

axcpu 组件负责封装用户态与内核态切换的底层机制。它为每种支持的架构（RISC-V、x86\_64、AArch64、LoongArch64）提供了一致的接口，主要包括：

- `UserContext`：封装用户态的寄存器状态，包括通用寄存器、程序计数器、栈指针以及架构特定的状态（如 RISC-V 的 `sstatus`、x86\_64 的段寄存器基址）
- `run()` 方法：执行用户态切换，返回 `ReturnReason` 枚举指示返回原因
- `TrapFrame`：异常帧结构，保存陷入内核时的完整寄存器状态

核心的用户态进入逻辑由汇编代码实现。以 RISC-V 为例，`enter_user` 函数的执行流程如下：

```
enter_user:
    # 保存内核态 callee-saved 寄存器
    addi    sp, sp, -16 * XLENB
    STR     s0, sp, 0
    ...
    STR     ra, sp, 12

    # 设置用户态入口
    csrw    sepc, t0          # 设置返回地址
    csrw    sstatus, t1       # 设置状态寄存器（SPP=0 表示返回用户态）

    # 恢复用户态寄存器
    POP_GENERAL_REGS
    LDR     sp, sp, 2         # 切换到用户态栈

    sret                      # 返回用户态
```

` sret` 指令将处理器从 S 模式切换到 U 模式，开始执行用户程序。当用户程序执行系统调用（`ecall` 指令）或发生异常时，处理器重新陷入 S 模式，跳转到 trap 向量入口。trap 处理代码根据 `scause` 寄存器判断陷入原因，构造 `ReturnReason` 并返回 Rust 代码。

x86\_64 架构的实现略有不同。由于 x86\_64 使用 `syscall`/`sysret` 指令进行系统调用入口和返回，而非通过统一的异常入口，axcpu 需要分别处理：`syscall` 指令跳转到 MSR `LSTAR` 指定的入口点，而异常则通过 IDT 进入 trap 处理代码。此外，x86\_64 需要处理 FS/GS 段寄存器基址的切换——用户态和内核态可能使用不同的 TLS 基址，这需要在进入和离开用户态时通过 `wrmsr`/`rdmsr` 操作 `KERNEL_GS_BASE` MSR。

axcpu 的设计目标是将这些架构差异封装在组件内部，向上层提供统一的接口。这使得 ArceOS/StarryOS 的内核代码无需关心底层的寄存器操作细节，只需调用 `UserContext::run()` 即可完成用户态切换。同时，axcpu 也提供了 `TrapFrame` 结构的访问接口，使系统调用处理代码能够读取和修改用户态寄存器（如系统调用参数和返回值），实现了跨架构的统一抽象。

== 高效内核-用户交互机制

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

== 异步 I/O 机制

=== 设计目标

在 StarryOS 中，引入异步机制的目的并不是为了追求某种编程范式上的“新颖性”，而是为了解决同步实现中广泛存在的低效轮询问题。对于串口、网络设备、输入设备以及 `futex`、`waitpid` 等需要等待事件发生的操作，如果仍然采用频繁检查状态的同步路径，系统会在 I/O 瓶颈场景下浪费大量处理器时间，并显著拉低整体吞吐量。因此，异步机制的直接目标，是在真正存在等待需求的路径上尽量减少无效轮询，使阻塞中的任务在事件发生时被精确唤醒。

不过，异步并不天然等于高性能。纯同步实现的优点在于控制流直接、上下文切换成本较低，但复杂等待场景往往难以优雅处理；纯异步实现则更容易统一事件机制，也便于复用 Rust 异步生态中的部分思路，但往往伴随更高的状态机复杂度、额外堆内存使用以及潜在性能损失。基于这一判断，StarryOS 更倾向于在整体上保持同步任务调度框架，而在真正耗时且需要等待事件的路径上引入异步兼容层，形成同步与异步混合的设计。这也成为后续 Poller、Pollable 与 Waker 机制设计的出发点。

=== 同步与异步混合架构

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

== 多级缓存优化

#todo[
  展开说明页缓存（page cache）、块缓存（block cache）、目录项缓存
  （dcache）三层缓存的实现细节，以及脏页写回策略。
]

== 多核调度与虚拟内存优化方向

=== 多核调度优化

#todo[
  说明当前调度实现的基础（基于 ArceOS axtask），
  以及针对多核场景规划/已实施的优化（负载均衡、调度延迟等）。
  如工作尚未完成，说明设计方向和参考（KRR, OSDI'25）。
]

=== 虚拟内存优化

#todo[
  说明当前虚拟内存实现（VMA + 页表双层结构），
  以及参考 CortenMM（SOSP'25）取消独立 VMA 抽象的优化方向。
  如工作尚未完成，说明设计思路。
]

== 本章小结

#todo[
  总结本章的关键机制与性能优化工作，
  强调其在组件化兼容内核中的作用，并引出后续 AI 应用支持与实验评测。
]
