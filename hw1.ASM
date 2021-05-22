; ---------------------------------------------------
; Written by Wu Yifan 
; 输入一行字符(敲回车结束输入)并保存到数组s中,
; 其中回车转化成ASCII码00h保存到数组中,
; 再把s中的每个元素逐个取出判断:
; (1) 若元素为小写字母则把它转化成大写并保存到数组t中;
; (2) 若元素为空格则丢弃该元素,不要保存到t中;
; (3) 若元素为其它字符则原样保存到t中;
; 最后输出t中的全部元素再输出回车换行。
; ---------------------------------------------------
data segment
    s db 100 dup(0)
    t db 100 dup(0)
data ends

code segment
assume cs:code, ds:data
main:
    mov ax, data
    mov ds, ax
    mov si,0 ;初始化源变址寄存器
    mov di,0 ;初始化目地变址寄存器
    jmp input
    
input:
    mov ah, 01h ;int 21h的01h功能
    int 21h ;将输入的字符存储到al
    cmp al,0Dh ;将输入和回车的ASCII码0Dh比较
    jnz is_not_enter ;如果不同继续循环
    mov s[si],00h ;si是最后一个元素的下标
    mov bx,0 ;bx表示当前遍历到的数组下标
    mov di,0
    jmp transfer

is_not_enter:
    mov s[si],al
    add si,1
    jmp input

transfer:
    cmp bx,si
    jg output_init ;遍历完s中的所有元素
    mov al,s[bx]
    cmp al,32 ;判断是否是空格
    jz is_space 
    cmp al,'a'
    jl save_to_t
    cmp al,'z'
    jg save_to_t
    sub al,32 ;小写字母减32变大写字母
    jg save_to_t

is_space:
    add bx,1
    jmp transfer
save_to_t:
    mov t[di],al
    add di,1
    add bx,1
    jmp transfer
output_init:
    sub di,1 ;将di指向的是t中最后一个元素
    mov bx,0 
    jmp output
output:
    cmp bx,di
    jg finish
    mov dl,t[bx]
    mov ah,02h
    int 21h ;输出t[bx]存储的字符
    add bx,1
    jmp output ;循环
finish:
    mov dl,0Dh ;将t中的元素输出后输出回车换行
    mov ah,02h
    int 21h
    mov dl,0Ah
    mov ah,02h
    int 21h
    mov ah, 4Ch
    int 21h
code ends
end main
