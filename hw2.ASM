data segment
   hex db 2 dup(0)
data ends

code segment
assume cs:code, ds:data

print:
   mov word ptr es:[di], ax ;在屏幕中显示
   add di,2 ;每次显示完成后di+2
   ret

change_to_hex:
;将要打印的ASCII码转为两位2进制
   mov si,0 ;si表示hex数组的下标
again:
   ;循环左移4位,因rol dl,4报错故改为4行rol dl,1
   rol dl,1
   rol dl,1
   rol dl,1
   rol dl,1
   push dx ;在栈中保存当前dx
   and dl,0Fh ;相与后的结果时2进制后四位
   cmp dl,10 
   jb is_digit ;将数字转换为字符
   sub dl, 10
   add dl, 'A'
   jmp save_to_hex
is_digit:
   add dl,'0'
save_to_hex:
   mov hex[si],dl ;将字符存储到hex数组中
   pop dx ;取出以前保存的dx
   add si,1 ;存储到hex的下一位
   cmp si,2
   jnz again ;如果未存储完2位重复上述操作 
   ret


main:
   mov ax, 0B800h
   mov es, ax 
   mov di, 0
   push di ;
   mov bx, 0 ;当前列
   mov cx, 0 ;当前行
   mov dl, 0 ;当前的ASCII码值
   mov ax,3
   int 10h ;清屏

col:
   cmp bx,0
   jz row ;第一列不用+14
   add di,14 ;下一列
   push di ;因为后续操作会改变di所以存储到栈中
row:
   mov al,dl;
   mov ah, 0Ch; 黑色背景，红色前景
   call print ;打印当前ASCII码对应的字符
   call change_to_hex ;将ASCII码转换为2位16进制
print_hex:
   mov si,0
print_again:
   mov al,hex[si] ;显示第一位
   mov ah, 02h; 黑色背景，绿色前景
   call print
   add si,1
   mov al,hex[si] ;显示第二位
   mov ah, 02h; 黑色背景，绿色前景
   call print
   add di,154 ;下一行
print_finish:
   add dl,1
   cmp dl,0 ;如果dl的值溢出说明已经显示完成了
   jz finish
   add cx,1 
   cmp cx,25 ;循环显示25行
   jnz row 
   pop di;
   mov cx,0 ;每次循环列前需要将行数归零
   add bx,1
   cmp bx,11 ;循环显示11列
   jnz col
finish:
   ;显示完成，等待键盘输入结束
   mov ah, 1
   int 21h 
   mov ah, 4Ch
   int 21h
code ends
end main


