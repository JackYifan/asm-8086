;--------------------------------------------------
; 程序中未使用32位寄存器
; 转换为2进制和16进制使用循环左移的方法
; 转换为10进制利用div编写div_10函数,结局除法溢出问题
;--------------------------------------------------
data segment
   buffer db 20,0,20 dup(0) ;缓冲区大小为20 从02h开始是输入的数字,01h是字符数
   output db 50 dup(0) ;输出的算式字符串
   num1 dw 0 ;第一个数
   num2 dw 0 ;第二个数
   ans_2 db 20 dup(0) ;2进制的答案
   ans_10 db 20 dup(0) ;10进制的答案
   ans_16 db 50 dup(0) ;16进制的答案

data ends

code segment
assume cs:code, ds:data

main:
    mov ax,data
    mov ds,ax 
    lea dx,buffer ;获取缓存区地址
    ;读入第一个字符串,保存到ds:dx中
    mov ah,0Ah
    int 21h
    mov ax,0
    mov bx,2
    mov si,1
    mov di,0
    mov cl,buffer[si] ;buffer[1]存储的是字符数
    add cl,2 ;cl加2后是输入的最后一个字符后的索引
convert_to_num1:
    mov dx,10
    mul dx ;ax*10
    mov dl,buffer[bx] 
    mov output[di],dl ;存储到算式字符串中
    add di,1  
    sub dl,'0' ;字符转数字
    add ax,dx ;ax=ax*10+dx
    inc bx 
    cmp bx,cx ;bx+1后与cx比较判断是否转换完毕
    jne convert_to_num1
done1:
    mov num1,ax ;将转换的结果存储到num1中
    mov output[di],'*' ;在算式字符串中加'*'
    add di,1
    call print_enter
    lea dx,buffer ;获取缓存区地址
    ;读入第一个字符串,保存到ds:dx中
    mov ah,0Ah
    int 21h
    ;初始化
    mov ax,0
    mov bx,2
    mov si,1
    mov cl,buffer[si]
    add cl,2

convert_to_num2:
    ;转换为第二个数
    mov dx,10
    mul dx
    mov dl,buffer[bx]
    mov output[di],dl
    add di,1
    sub dl,'0'
    add ax,dx
    inc bx
    cmp bx,cx
    jne convert_to_num2
done2:
    mov num2,ax
    mov output[di],'=' ;在output中加'='
    add di,1
    call print_enter ;输入完成后换行
    mov bx,0
print:
    ;打印算式即output中的所有字符
    cmp bx,di
    je ans_dec
    mov dl,output[bx]
    mov ah,02h
    int 21h 
    add bx,1
    jmp print ;循环打印

;----------------------
; 十进制结果           
;----------------------
ans_dec:
    mov ax,num1
    mov bx,num2
    mul bx ;16位*16位
    ;高位在dx中，低位在ax中 3038 CFC7h
    push ax ;将低位存储到栈中
    push dx ;压栈
    mov di,0 
    mov si,0 ;栈中cx的数量(余数)
push_cx:
    mov cx,10 ;除数
    call div_10 
    add cl,'0' ;余数转字符
    push cx
    inc si
    ;判断商dx:ax是否为0，若为0则跳转到pop_dx
    cmp ax,0
    jne push_cx
    cmp dx,0
    jne push_cx
pop_cx:
    ;将余数字符弹栈，即可逆序存储到ans_10中
    pop cx
    mov ans_10[di],cl
    inc di
    sub si,1 ;栈中数量-1
    cmp si,0 ;si是栈中cx的数量，等于0时说明弹栈完毕
    jne pop_cx

print_ans_10_init:
    call print_enter ;在输出答案前先换行
    mov si,0
print_ans_10:
    cmp si,di ;判断是否输出完毕
    je finish_print_10
    mov dl,ans_10[si]
    mov ah,02h
    int 21h 
    add si,1
    jmp print_ans_10

finish_print_10:
    call print_enter ;输出16进制前换行

;----------------------
; 十六进制结果           
;----------------------

ans_hex:
    pop dx
    pop ax
    push ax
    push dx
    mov si,0
    mov cl,4
    ;dx循环左移4位
    rol dx,cl
    push dx ;保存左移4位后的dx
    and dl,0Fh ;与运算获得后4位
    mov ans_16[si],dl ;存储结果
    pop dx ;还原dx
    ;重复上述操作
    add si,1
    rol dx,cl
    push dx
    and dl,0Fh
    mov ans_16[si],dl
    pop dx
    add si,1
    rol dx,cl
    push dx
    and dl,0Fh
    mov ans_16[si],dl
    pop dx
    add si,1
    rol dx,cl
    push dx
    and dl,0Fh
    mov ans_16[si],dl
    pop dx
    add si,1
    ;ax循环左移4位
    rol ax,cl
    push ax
    and al,0Fh
    mov ans_16[si],al
    pop ax
    add si,1
    rol ax,cl
    push ax
    and al,0Fh
    mov ans_16[si],al
    pop ax
    add si,1
    rol ax,cl
    push ax
    and al,0Fh
    mov ans_16[si],al
    pop ax
    add si,1
    rol ax,cl
    push ax
    and al,0Fh
    mov ans_16[si],al
    pop ax
    add si,1
    mov di,0
transfer:
    ;将16进制的数字转换为字符
    cmp di,8 ;判断是否已输出8位
    je finish_16
    cmp ans_16[di],10
    jb lower_than_ten
    add ans_16[di],'A' 
    sub ans_16[di],10
    add di,1
    jmp transfer
lower_than_ten:
    add ans_16[di],'0'
    add di,1
    jmp transfer
finish_16:
    mov di,0
print_ans_16:
    ;打印16进制字符
    cmp di,8
    je finish_print_16
    mov dl,ans_16[di]
    mov ah,02h
    int 21h 
    add di,1
    jmp print_ans_16
finish_print_16:
    ;输出'h'
    mov dl,'h'
    mov ah,02h
    int 21h 
    
;----------------------
; 二进制结果           
;----------------------
ans_bin:
    call print_enter
    pop dx
    pop ax
    push ax
    push dx
    mov di,0 
    mov cx,0;循环次数
dx_to_bin:
    ;dx共左移16位
    cmp cx,16
    je ax_to_bin_init
    rol dx,1
    push dx
    and dl,1h ;与1相与获得最后一位
    add dl,'0' 
    mov ans_2[di],dl
    pop dx
    inc di
    inc cx
    jmp dx_to_bin

ax_to_bin_init:
    mov cx,0
ax_to_bin:
    cmp cx,16
    je finish_2
    rol ax,1
    push ax
    and al,1h
    add al,'0'
    mov ans_2[di],al
    pop ax
    inc di
    inc cx
    jmp ax_to_bin
    
finish_2:
    mov di,0
print_ans_2:
    mov dl,ans_2[di]
    mov ah,02h
    int 21h 
    add di,1
    ;每输出4个数字输出一个空格
    push di
    and di,03h ;最后2位全零表明是4的倍数
    mov si,di
    pop di
    cmp di,32 ;总共32个字符
    je finish_print_2
    cmp si,0
    jne print_ans_2
print_blank:
    ;打印空格
    mov dl,' ' 
    mov ah,02h
    int 21h
    jmp print_ans_2

finish_print_2:
    ;输出B结束打印
    mov dl,'B'
    mov ah,02h
    int 21h 
    call print_enter
finish:
   ;显示完成，等待键盘输入结束
   mov ah, 1
   int 21h 
   mov ah, 4Ch
   int 21h
print_enter:
    ;打印回车
    mov dl,0Dh 
    mov ah,02h
    int 21h
    mov dl,0Ah
    mov ah,02h
    int 21h
    ret
;-----------------------------
;dx:ax / cx = dx:ax ... cx
;-----------------------------
div_10:   
  push ax
  mov ax, dx ;高16位
  mov dx, 0 
  div cx   
  mov bx, ax ;结果的高16位
  pop ax   ;低16位
  div cx
  mov cx, dx ;余数
  mov dx, bx ;结果的高16位
  ret
code ends
end main


