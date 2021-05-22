.386
data segment use16
    filename db 100,0,100 dup(0)
    buf db 255,0,255 dup(0)
    message db "Please input filename:",0Dh,0Ah,"$"
    error db "Cannot open file!",0Dh,0Ah,"$"
    handle dw 0,0
    file_size dd 0,0,0,0
    file_offset dd 0,0,0,0
    n dd 0,0,0,0
    old_offset dd 0,0,0,0
    bytes_in_buf dw 0,0
    rows dw 0,0 ;当前行数
    bytes_on_row dw 0,0
    pattern db "00000000:            |           |           |                             "
    s db "00000000: xx xx xx xx|xx xx xx xx|xx xx xx xx|xx xx xx xx  ................"
    t db "0123456789ABCDEF"
    rrow dw 0,0
    roffset dd 0,0,0,0
    rbuf db 0
    key dw 0,0
    key_map db "0123456789ABCDEF"
    input db 9 dup(0)
    box db "+----------+","|          |","+----------+"
    boxbuf db 72 dup(0)
    len dw 0,0

data ends
;0238
code segment use16
assume cs:code, ds:data
main:
    mov ax, 0B800h
    mov es, ax
    mov di,0
    ;puts("Please input filename:");
    mov ax,data
    mov ds,ax
    mov ah,09h
    mov dx,offset message
    int 21h
    mov dx,offset buf
    mov ah,0Ah
    int 21h
    call print_enter
    mov cl,buf[1] ;读入的字符个数
    mov si,2
    mov di,0
transfer:
    ;转移buf中的字符到filename中
    cmp cl,0
    je open_file
    mov dl,buf[si]
    mov filename[di],dl
    add di,1
    add si,1
    sub cl,1 
    jmp transfer

open_file:
    mov ah, 3Dh
    mov al, 0
    mov dx, offset filename
    int 21h; CF=0 on success, AX=handle
    mov handle, ax;handle为dw类型的变量
    jc open_file_error ;如果CF=1则文件打开失败
    ;fseek(fp, 0, SEEK_END);
    mov ah, 42h
    mov al, 2; SEEK_END, 表示以EOF为起点移动文件指针
    mov bx, handle ;handle为句柄，用于操控文件
    mov cx, 0; \ 移动距离为cx:dx
    mov dx, 0; / 
    int 21h  ; 返回dx:ax=文件长度  
    mov word ptr file_size[2], dx
    mov word ptr file_size[0], ax
    ;将文件指针移动到文件首部
    mov ah, 42h
    mov al, 0; SEEK_SET, 以文件内容的首字节为起点移动文件指针
    mov bx, handle
    mov cx, 0;\ 移动距离 = 0
    mov dx, 0;/
    int 21h
    mov dx,0
    mov file_offset,0
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;大循环
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;
show_again:
    mov ebx,file_size ;0085
    mov ecx,file_offset
    sub ebx,ecx
    mov n,ebx
    cmp ebx,256
    jge check_page_size
    mov bytes_in_buf,bx
    jmp read_file

check_page_size:
    mov bytes_in_buf,256
read_file:
    ;移动文件指针到file_offset处
    mov ah, 42h
    mov al, 0
    mov bx, handle
    mov cx, word ptr file_offset[2]; \cx:dx一起构成
    mov dx, word ptr file_offset[0]; /32位值=offset
    int 21h
    ;读取文件中的bytes_in_buf个字节到buf中 
    mov ah, 3Fh
    mov bx, handle
    mov cx, bytes_in_buf
    mov dx, offset buf; ds:dx->buf
    int 21h; CF=0 on success, AX=bytes actually read




    ;;显示当前页
    call show_this_page ;;;00D0

    ;键盘输入
    ;Return:
    ;AH = BIOS scan code
    ;AL = ASCII character
    mov ah, 0
    int 16h
    cmp ax,4900h
    je page_up
    cmp ax,5100h
    je page_down
    cmp ax,4700h
    je home
    cmp ax,3F00h
    je f5
    cmp ax,4F00h
    je key_end
    jmp choose_finish


;
; case PageUp:
;
page_up:
    cmp file_offset,255
    jb below_255
    sub file_offset,256
    jmp page_up_finish
below_255:
    mov file_offset,0
page_up_finish:
    jmp choose_finish


;
; case PageDown:
;
page_down:
    mov eax,file_offset
    add eax,256
    cmp eax,file_size
    jb page_down_fork
    jmp page_down_finish
page_down_fork:
    add file_offset,256
page_down_finish:
    jmp choose_finish
;
; Home
;
home:
    mov file_offset,0
    jmp choose_finish

f5:
    ;old_offset = offset;
    mov edx,file_offset
    mov old_offset,edx
    ;offset = get_offset();结果保存在ecx中
    jmp get_offset ;015A
get_offset_finish:
    mov file_offset,ecx

    mov ecx,file_offset
    mov ebx,file_size
    cmp ecx,ebx
    jge larger_than_size
    jmp f5_break
larger_than_size:
    mov edx,old_offset
    mov file_offset,edx
f5_break:
    jmp choose_finish

key_end:
    mov eax,file_size
    and eax,00FFh ;取最后8位，相当于%256
    cmp eax,0
    je key_end_fork
    mov ebx,file_size
    sub ebx,eax
    mov file_offset,ebx
    jmp key_end_finish
key_end_fork:
    mov eax,file_offset
    sub eax,256
    mov file_offset,eax
key_end_finish:
    jmp choose_finish



choose_finish:
    ;case语句中break后跳转至此
    cmp ax,011Bh
    je finish
    ;循环
    jmp show_again



    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;大循环
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;

finish:
    ;关闭文件
    mov ah, 3Eh
    mov bx, handle
    int 21h

   ;显示完成，等待键盘输入结束
   mov ah, 1
   int 21h 
   mov ah, 4Ch
   int 21h
open_file_error:
    ;判断打开是否成功
    mov ah,09h
    mov dx,offset error
    int 21h
    ;exit(0);
    mov ah, 4Ch
    mov al, 0
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

;
;显示当前页
;
show_this_page:
    call clear_this_page
    mov ax,bytes_in_buf ;01BD
    add ax,15
    shr ax,4 ;右移4位等价/16
    mov rows,ax
    mov cx,0
    mov di,0
show_this_page_again:
    cmp cx,rows
    je loop_finish
    mov ax,rows
    sub ax,1
    cmp cx,ax
    je ax_eq_cx
    mov bytes_on_row,16
    jmp cmp_finish
ax_eq_cx:
    mov dx,bytes_in_buf ;dx=bytes_in_buf
    mov bx,cx
    shl bx,4 ; bx=i*16
    sub dx,bx ;dx=bytes_in_buf-i*16
    mov bytes_on_row,dx;
cmp_finish:
    push cx
    ;;TODO
    mov rrow,cx
    shl cx,4 ;cx=i*16
    mov eax,file_offset
    add eax,ecx ;ax=offset+i*16
    mov roffset,eax    
    mov rbuf,cl
    call show_this_row ;;bug 0130
    pop cx 
    add cx,1
    jmp show_this_page_again ;循环
loop_finish:
    ret

;
;清屏 01BA
;
clear_this_page:
    mov di,0
    mov cx,1280 ;共80*16个
    cld
    mov ax,0020h ;填入0020h
    rep stosw
    ret 

;
;显示当前行
;
show_this_row:
    ;strcpy(s, pattern); 0228
    push ax
    push si
    push di
    push cx
    push es
    mov ax, data
    mov ds, ax
    mov si, offset pattern
    mov ax, data
    mov es, ax
    mov di, offset s      
    mov cx, 75
    cld            
    rep movsb
    pop es 
    pop cx
    pop di
    pop si
    pop ax


    call long2hex ;;bug 0140
    ;TODO
    push cx
    mov cx,0 ;循环次数
again1:
    cmp cx,bytes_on_row
    je finish1    
    ;循环内容
    
    push dx
    push di

    mov si,cx
    add si,rbuf
    mov dl,buf[si]
    mov di,cx
    imul di,di,3
    add di,10
    call char2hex

    pop di
    pop dx

    add cx,1
    jmp again1
finish1:
    pop cx
    push cx 
    push di
    mov cx,0
again2:
    cmp cx,bytes_on_row
    je finish2    
    ;循环内容
    mov si,cx
    mov di,cx 
    add si,rbuf
    mov dl,buf[si]
    mov s[59+di],dl

    add cx,1
    jmp again2
finish2:
    pop di
    pop cx
    ;;TODO
    push bx 
    mov bx,0
    mov ax,rrow
    imul ax,ax,160 ;019F
    add di,ax
    
again3:
    cmp bx,75
    je finish3    
    ;循环内容
    mov al,s[bx]
    mov bp,bx
    add bp,bx ;bp=2*bx
    mov es:[di+bp],al ;vp[i*2] = s[i];
    cmp bx,59
    jb lower_59
    jmp normal
lower_59:
    cmp s[bx],'|'
    je highlight
    jmp normal
highlight:
    mov bp,bx
    add bp,bx ;bp=2*bx
    mov byte ptr es:[di+bp+1],0Fh
    jmp jmp_again3
normal:
    mov bp,bx
    add bp,bx ;bp=2*bx
    mov byte ptr es:[di+bp+1],07h
jmp_again3:
    add bx,1
    jmp again3
finish3:
    pop bx
    ret 

;
;32位数转为16进制格式
;
long2hex:
    push cx
    mov cx,0
    mov di,0
long2hex_again:
    cmp cx,4
    je long2hex_finish
    rol roffset,8
    mov edx,roffset
    and edx,00FFh ;保留低8位置,xx
    push cx 
    push dx
    push di
    mov di,cx
    shl di,1 ;2*cx
    call char2hex
    pop di
    pop dx
    pop cx 
    add cx,1
    jmp long2hex_again
long2hex_finish:
    pop cx
    ret 

;
;把8位数转化成16进制格式
; dl,s[di]
;
char2hex:
    push dx; //保存当前dl ;;bug0116
    shr dl,4
    and dl,0Fh;
    mov si,dx
    mov bl,t[si]
    mov s[di],bl ;将t[si]存储到s[di]中
    pop dx
    and dl,0Fh;
    mov si,dx
    mov bl,t[si]
    mov s[di+1],bl 
    ret

;
;弹出输入框获取offset 0343
;    
get_offset: 
    push di
    mov di,0
    add di,1828
    ;;二重循环
    mov ax,0
againax:
    cmp ax,3
    je againax_finish
    ;;内层循环
    mov bx,0
againbx:
    cmp bx,24
    je againbx_finish
    ;;
    mov cx,ax
    imul cx,cx,24
    add cx,bx ;cx=i*24+j
    mov dl,es:[di+bx]
    mov bp,cx
    mov boxbuf[bp],dl
    ;;
    add bx,1
    jmp againbx
againbx_finish:
    ;;  
    add di,160
    add ax,1
    jmp againax

againax_finish:
    mov di,0
    add di,1828

;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;二重循环
    mov ax,0
againax1:
    cmp ax,3
    je againax_finish1
    ;;内层循环
    mov bx,0
againbx1:
    cmp bx,12
    je againbx_finish1
    ;;
    mov cx,ax
    imul cx,cx,12
    add cx,bx ;cx=i*13+j
    mov dx,bx
    imul dx,dx,2 ;dx=2*j
    mov si,cx
    mov cl,box[si]
    mov bp,dx
    mov es:[di+bp],cl
    add dx,1 ;dx=2*j+1
    mov bp,dx
    mov byte ptr es:[di+bp],17h
    ;;
    add bx,1
    jmp againbx1
againbx_finish1:
    ;;  
    add di,160
    add ax,1
    jmp againax1

;;;;;;;;;;;;;;;;;;;;;

againax_finish1:
    mov di,1990
    mov cx,0 ;已输入字符个数
bios_again:
    mov ah, 0
    int 16h ;;;;;;;;;;;;;;;;;;;;03FC
    ;键盘输入保存在ax
    cmp ax,0E08h
    je bkspace
    cmp ax,1C0Dh
    je key_enter 
    jmp key_process


bkspace:
    cmp cx,0
    je while_judge
    mov bx,cx
    sub bx,1
    imul bx,bx,2
    mov byte ptr es:[di+bx],' '
    add bx,1
    mov byte ptr es:[di+bx],17h
    sub cx,1
    jmp while_judge

key_enter:
    mov bp,cx
    mov input[bp],0
    mov len,bp
    jmp while_judge
key_process:
    and ax,00FFh
    cmp ax,'a'
    jge greater_than_a
    jmp map

greater_than_a:
    cmp ax,'f'
    jbe lower_case
    jmp map
lower_case:
    sub ax,20h
map:
    mov dx,0
map_again:
    cmp dx,16 ;sizeof(key_map)-1
    je map_finish
    mov bp,dx
    cmp al,key_map[bp]
    je map_finish
    add dx,1
    jmp map_again
map_finish:
    cmp dx,16
    je while_judge
    cmp cx,8
    je while_judge
    mov bp,cx
    mov input[bp],al ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    imul bp,bp,2
    mov es:[di+bp],ax
    add bp,1
    mov byte ptr es:[di+bp],17h
    add cx,1
while_judge:
    cmp ax,1C0Dh 
    jne bios_again
;恢复屏幕上弹框区域的信息;
    mov di,1828

    ;;二重循环
    mov ax,0
againax2:
    cmp ax,3
    je againax_finish2
    ;;内层循环
    mov bx,0
againbx2:
    cmp bx,24
    je againbx_finish2
    ;;
    mov cx,ax
    imul cx,cx,24
    add cx,bx ;cx=i*24+j
    mov bp,cx
    mov dl,boxbuf[bp]
    mov es:[di+bx],dl
    ;;
    add bx,1
    jmp againbx2
againbx_finish2:
    ;;  
    add di,160
    add ax,1
    jmp againax2

againax_finish2:
    call hex2long ;04CE
    jmp get_offset_finish 

hex2long:
    ;16进制字符串转化成32位数;
    ;n=9 sizeof(t)=16
    ;返回值保存在ecx中
    mov ecx,0
    mov ax,0
axagain:
    cmp ax,len
    je axagain_finish
    mov bx,0
bxagain:
    cmp bx,16
    je bxagain_finish
    ;遍历input 
    mov bp,ax
    mov dl,input[bp]
    cmp t[bx],dl
    je bxagain_finish
    ;;
    add bx,1
    jmp bxagain
bxagain_finish:
    shl ecx,4
    or ecx,ebx
    add ax,1
    jmp axagain
axagain_finish:
    ret 
code ends
end main


