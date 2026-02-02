.model small
.stack 100h
.data
    filename        db "database.txt",0
    filehandle      dw ?
    file_err_msg    db 0dh,0ah,"error: file access failed!$"
    file_suc_msg    db 0dh,0ah,"data saved to database.txt successfully!$"
    rec_size        equ 25
    max_recs        equ 20
    records         db max_recs*rec_size dup(0)
    record_count    dw 0
    menu_title      db 0dh,0ah,"-----------------------------------$"
    menu_opt1       db 0dh,0ah,"1. add record$"
    menu_opt2       db 0dh,0ah,"2. view all records$"
    menu_opt3       db 0dh,0ah,"3. update record$"
    menu_opt4       db 0dh,0ah,"4. delete record$"
    menu_opt5       db 0dh,0ah,"5. sort data$"
    menu_opt6       db 0dh,0ah,"6. show totals$"
    menu_opt7       db 0dh,0ah,"7. save & exit$"
    prompt_choice   db 0dh,0ah,"enter choice: $"
    msg_id          db 0dh,0ah,"enter id (sr# numeric): $"
    msg_name        db 0dh,0ah,"enter name (max 10 chars): $"
    msg_fam         db 0dh,0ah,"enter family members: $"
    msg_water       db 0dh,0ah,"enter water (l): $"
    msg_floor       db 0dh,0ah,"enter floor (kg): $"
    msg_pulses      db 0dh,0ah,"enter pulses (kg): $"
    msg_full        db 0dh,0ah,"error: database full!$"
    msg_dup         db 0dh,0ah,"error: duplicate id!$"
    msg_notfound    db 0dh,0ah,"error: record not found!$"
    msg_deleted     db 0dh,0ah,"record deleted.$"
    msg_saved       db 0dh,0ah,"record saved.$"
    header          db 0dh,0ah,"id   name           mem  wtr  flr  pls",0dh,0ah,"--------------------------------------$"
    newline         db 0dh,0ah,"$"
    space           db "  $"
    sort_menu       db 0dh,0ah,"sort by: 1.mem 2.water 3.floor 4.pulses: $"
    sort_offset     dw 0
    temp_num        dw 0
    temp_str        db 20 dup('$')
    msg_tot_mem     db 0dh,0ah,"total members: $"
    msg_tot_wtr     db 0dh,0ah,"total water:   $"
    msg_tot_flr     db 0dh,0ah,"total floor:   $"
    msg_tot_pls     db 0dh,0ah,"total pulses:  $"
.code
main proc
    mov ax,@data
    mov ds,ax
    mov es,ax
menu_loop:
    lea dx,menu_title
    mov ah,09h
    int 21h
    lea dx,menu_opt1
    int 21h
    lea dx,menu_opt2
    int 21h
    lea dx,menu_opt3
    int 21h
    lea dx,menu_opt4
    int 21h
    lea dx,menu_opt5
    int 21h
    lea dx,menu_opt6
    int 21h
    lea dx,menu_opt7
    int 21h
    lea dx,prompt_choice
    int 21h
    mov ah,01h
    int 21h
    mov bl,al
    lea dx,newline
    mov ah,09h
    int 21h
    cmp bl,'1'
    je call_add
    cmp bl,'2'
    je call_view
    cmp bl,'3'
    je call_update
    cmp bl,'4'
    je call_delete
    cmp bl,'5'
    je call_sort
    cmp bl,'6'
    je call_totals
    cmp bl,'7'
    je call_exit
    jmp menu_loop
call_add:
    call add_record
    jmp menu_loop
call_view:
    call view_all
    jmp menu_loop
call_update:
    call update_record
    jmp menu_loop
call_delete:
    call delete_record
    jmp menu_loop
call_sort:
    call sort_records
    jmp menu_loop
call_totals:
    call calc_totals
    jmp menu_loop
call_exit:
    call save_to_file
    mov ah,4ch
    int 21h
main endp
add_record proc
    mov ax,record_count
    cmp ax,max_recs
    jl continue_add
    lea dx,msg_full
    mov ah,09h
    int 21h
    ret
continue_add:
    mov ax,record_count
    mov bx,rec_size
    mul bx
    mov si,ax
    add si,offset records
    lea dx,msg_id
    mov ah,09h
    int 21h
    call read_number
    push ax
    call check_duplicate
    pop ax
    jz duplicate_found
    mov [si],ax
    lea dx,msg_name
    mov ah,09h
    int 21h
    push si
    add si,2
    call read_string
    pop si
    lea dx,msg_fam
    mov ah,09h
    int 21h
    call read_number
    mov [si+17],ax
    lea dx,msg_water
    mov ah,09h
    int 21h
    call read_number
    mov [si+19],ax
    lea dx,msg_floor
    mov ah,09h
    int 21h
    call read_number
    mov [si+21],ax
    lea dx,msg_pulses
    mov ah,09h
    int 21h
    call read_number
    mov [si+23],ax
    inc record_count
    lea dx,msg_saved
    mov ah,09h
    int 21h
    ret
duplicate_found:
    lea dx,msg_dup
    mov ah,09h
    int 21h
    ret
add_record endp
view_all proc
    lea dx,newline
    mov ah,09h
    int 21h
    lea dx,header
    int 21h
    cmp record_count,0
    je view_empty
    mov cx,record_count
    lea si,records
print_loop:
    lea dx,newline
    mov ah,09h
    int 21h
    mov ax,[si]
    call print_num
    call print_tab
    push si
    add si,2
    mov dx,si
    mov ah,09h
    int 21h
    pop si
    call print_tab
    mov ax,[si+17]
    call print_num
    lea dx,space
    mov ah,09h
    int 21h
    mov ax,[si+19]
    call print_num
    lea dx,space
    mov ah,09h
    int 21h
    mov ax,[si+21]
    call print_num
    lea dx,space
    mov ah,09h
    int 21h
    mov ax,[si+23]
    call print_num
    add si,rec_size
    loop print_loop
view_empty:
    ret
view_all endp
update_record proc
    lea dx,msg_id
    mov ah,09h
    int 21h
    call read_number
    call find_record_offset
    cmp si,0
    je rec_not_found_err
    lea dx,msg_fam
    mov ah,09h
    int 21h
    call read_number
    mov [si+17],ax
    lea dx,msg_water
    mov ah,09h
    int 21h
    call read_number
    mov [si+19],ax
    lea dx,msg_floor
    mov ah,09h
    int 21h
    call read_number
    mov [si+21],ax
    lea dx,msg_pulses
    mov ah,09h
    int 21h
    call read_number
    mov [si+23],ax
    lea dx,msg_saved
    mov ah,09h
    int 21h
    ret
rec_not_found_err:
    lea dx,msg_notfound
    mov ah,09h
    int 21h
    ret
update_record endp
delete_record proc
    lea dx,msg_id
    mov ah,09h
    int 21h
    call read_number
    call find_record_offset
    cmp si,0
    je rec_not_found_err
    mov ax,record_count
    dec ax
    mov bx,rec_size
    mul bx
    lea di,records
    add di,ax
    cmp si,di
    je dec_count
    mov cx,rec_size
    push ds
    pop es
    xchg si,di
rep_movsb:
    mov al,[si]
    mov bl,[di]
    mov [si],bl
    mov [di],al
    inc si
    inc di
    loop rep_movsb
dec_count:
    dec record_count
    lea dx,msg_deleted
    mov ah,09h
    int 21h
    ret
delete_record endp
sort_records proc
    cmp record_count,2
    jl sort_done
    lea dx,sort_menu
    mov ah,09h
    int 21h
    mov ah,01h
    int 21h
    cmp al,'1'
    je sort_mem
    cmp al,'2'
    je sort_wtr
    cmp al,'3'
    je sort_flr
    cmp al,'4'
    je sort_pls
    jmp sort_done
sort_mem: mov sort_offset,17
          jmp do_sort
sort_wtr: mov sort_offset,19
          jmp do_sort
sort_flr: mov sort_offset,21
          jmp do_sort
sort_pls: mov sort_offset,23
          jmp do_sort
do_sort:
    mov cx,record_count
    dec cx
outer_loop:
    push cx
    lea si,records
inner_loop:
    mov bx,sort_offset
    mov ax,[si+bx]
    mov dx,[si+rec_size+bx]
    cmp ax,dx
    jle no_swap
    push cx
    push si
    mov di,si
    add di,rec_size
    mov cx,rec_size
swap_bytes:
    mov al,[si]
    mov bl,[di]
    mov [si],bl
    mov [di],al
    inc si
    inc di
    loop swap_bytes
    pop si
    pop cx
no_swap:
    add si,rec_size
    loop inner_loop
    pop cx
    loop outer_loop
sort_done:
    ret
sort_records endp
calc_totals proc
    cmp record_count,0
    je totals_exit
    mov cx,record_count
    lea si,records
    xor bx,bx
    xor di,di
    xor bp,bp
push_cx_si:
    push cx
    push si
    xor bx,bx
l1: add bx,[si+17]
    add si,rec_size
    loop l1
    lea dx,msg_tot_mem
    mov ah,09h
    int 21h
    mov ax,bx
    call print_num
    pop si
    pop cx
push_cx_si2:
    push cx
    push si
    xor bx,bx
l2: add bx,[si+19]
    add si,rec_size
    loop l2
    lea dx,msg_tot_wtr
    mov ah,09h
    int 21h
    mov ax,bx
    call print_num
    pop si
    pop cx
push_cx_si3:
    push cx
    push si
    xor bx,bx
l3: add bx,[si+21]
    add si,rec_size
    loop l3
    lea dx,msg_tot_flr
    mov ah,09h
    int 21h
    mov ax,bx
    call print_num
    pop si
    pop cx
push_cx_si4:
    push cx
    push si
    xor bx,bx
l4: add bx,[si+23]
    add si,rec_size
    loop l4
    lea dx,msg_tot_pls
    mov ah,09h
    int 21h
    mov ax,bx
    call print_num
    pop si
    pop cx
totals_exit:
    ret
calc_totals endp
find_record_offset proc
    mov cx,record_count
    lea si,records
    cmp cx,0
    je not_found
search_loop:
    cmp [si],ax
    je found
    add si,rec_size
    loop search_loop
not_found:
    mov si,0
    ret
found:
    ret
find_record_offset endp
check_duplicate proc
    push cx
    push si
    mov cx,record_count
    lea si,records
    cmp cx,0
    je no_dup
dup_loop:
    cmp [si],ax
    je is_dup
    add si,rec_size
    loop dup_loop
no_dup:
    or cx,1
    jmp dup_exit
is_dup:
    cmp ax,ax
dup_exit:
    pop si
    pop cx
    ret
check_duplicate endp
read_number proc
    push bx
    push cx
    push dx
    xor bx,bx
    xor cx,cx
read_digit:
    mov ah,01h
    int 21h
    cmp al,0dh
    je end_read
    cmp al,'0'
    jl read_digit
    cmp al,'9'
    jg read_digit
    sub al,30h
    mov cl,al
    mov ax,10
    mul bx
    add ax,cx
    mov bx,ax
    jmp read_digit
end_read:
    mov ax,bx
    pop dx
    pop cx
    pop bx
    ret
read_number endp
print_num proc
    push ax
    push bx
    push cx
    push dx
    mov cx,0
    mov bx,10
div_loop:
    xor dx,dx
    div bx
    push dx
    inc cx
    cmp ax,0
    jne div_loop
print_digits:
    pop dx
    add dl,30h
    mov ah,02h
    int 21h
    loop print_digits
    pop dx
    pop cx
    pop bx
    pop ax
    ret
print_num endp
read_string proc
    push cx
    mov cx,0
str_loop:
    mov ah,01h
    int 21h
    cmp al,0dh
    je str_done
    mov [si],al
    inc si
    inc cx
    cmp cx,10
    jl str_loop
str_done:
    mov byte ptr [si],'$'
    pop cx
    ret
read_string endp
print_tab proc
    lea dx,space
    mov ah,09h
    int 21h
    int 21h
    ret
print_tab endp
save_to_file proc
    mov ah,3ch
    lea dx,filename
    mov cx,0
    int 21h
    jc file_error
    mov filehandle,ax
    mov ax,record_count
    mov bx,rec_size
    mul bx
    mov cx,ax
    mov ah,40h
    mov bx,filehandle
    lea dx,records
    int 21h
    mov ah,3eh
    mov bx,filehandle
    int 21h
    lea dx,file_suc_msg
    mov ah,09h
    int 21h
    ret
file_error:
    lea dx,file_err_msg
    mov ah,09h
    int 21h
    ret
save_to_file endp
end main
