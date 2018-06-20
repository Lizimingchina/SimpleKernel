
# This file is a part of MRNIU/SimpleKernel (https://github.com/MRNIU/SimpleKernel).

# intr_s.s for MRNIU/SimpleKernel.

# 定义两个构造中断处理函数的宏(有的中断有错误代码，有的没有)
# 用于没有错误代码的中断
.macro ISR_NOERRCODE no
.global isr\no
isr\no:
    cli                  # 首先关闭中断
    push $0               # push 无效的中断错误代码
    push \no              # push 中断号
    jmp isr_common_stub
.endm

# 用于有错误代码的中断
.macro ISR_ERRCODE er
.global isr\er
isr\er:
    cli                  # 关闭中断
    push \er              # push 中断号
    jmp isr_common_stub
.endm

# 定义中断处理函数
ISR_NOERRCODE  0    # 0 #DE 除 0 异常
ISR_NOERRCODE  1    # 1 #DB 调试异常
ISR_NOERRCODE  2    # 2 NMI
ISR_NOERRCODE  3    # 3 BP 断点异常
ISR_NOERRCODE  4    # 4 #OF 溢出
ISR_NOERRCODE  5    # 5 #BR 对数组的引用超出边界
ISR_NOERRCODE  6    # 6 #UD 无效或未定义的操作码
ISR_NOERRCODE  7    # 7 #NM 设备不可用(无数学协处理器)
ISR_ERRCODE    8    # 8 #DF 双重故障(有错误代码)
ISR_NOERRCODE  9    # 9 协处理器跨段操作
ISR_ERRCODE   10    # 10 #TS 无效TSS(有错误代码)
ISR_ERRCODE   11    # 11 #NP 段不存在(有错误代码)
ISR_ERRCODE   12    # 12 #SS 栈错误(有错误代码)
ISR_ERRCODE   13    # 13 #GP 常规保护(有错误代码)
ISR_ERRCODE   14    # 14 #PF 页故障(有错误代码)
ISR_NOERRCODE 15    # 15 CPU 保留
ISR_NOERRCODE 16    # 16 #MF 浮点处理单元错误
ISR_ERRCODE   17    # 17 #AC 对齐检查
ISR_NOERRCODE 18    # 18 #MC 机器检查
ISR_NOERRCODE 19    # 19 #XM SIMD(单指令多数据)浮点异常

# 20 ~ 31 Intel 保留
ISR_NOERRCODE 20
ISR_NOERRCODE 21
ISR_NOERRCODE 22
ISR_NOERRCODE 23
ISR_NOERRCODE 24
ISR_NOERRCODE 25
ISR_NOERRCODE 26
ISR_NOERRCODE 27
ISR_NOERRCODE 28
ISR_NOERRCODE 29
ISR_NOERRCODE 30
ISR_NOERRCODE 31
# 32 ～ 255 用户自定义
# 128=0x80 用于系统调用
ISR_NOERRCODE 128


# 中断服务程序
isr_common_stub:
  pusha    # Pushes edi, esi, ebp, esp, ebx, edx, ecx, eax
  mov %ds, %ax
  push %eax  # 保存数据段描述符

  mov $0x10, %ax # 加载内核数据段描述符表
  mov %ax, %ds
  mov %ax, %es
  mov %ax, %fs
  mov %ax, %gs
  mov %ax, %ss

  push %esp        # 此时的 esp 寄存器的值等价于 pt_regs 结构体的指针
  call isr_handler        # 在 C 语言代码里
  add $4, %esp  # 清除压入的参数

  pop %ebx                 # 恢复原来的数据段描述符
  mov %bx, %ds
  mov %bx, %es
  mov %bx, %fs
  mov %bx, %gs
  mov %bx, %ss

  popa                     # Pops edi, esi, ebp, esp, ebx, edx, ecx, eax
  add $8, %esp  # 清理栈里的 error code 和 ISR
  iret


# 加载 idt
.global idt_load
idt_load:
  mov 4(%esp), %edx # 参数保存在 eax
  lidt (%edx)
  sti 				# turn on interrupts
  ret
