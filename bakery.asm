.MODEL SMALL
.STACK 100h

.DATA
LoginBanner     db 13, 10, '==== Bakery POS Login ====$'
User            db 13, 10, 'Enter username: $'
Pass            db 13, 10, 'Enter password: $'
LoginOK         db 13, 10, 'Login successful!', 13, 10, '$'
LoginFail       db 13, 10, 'Invalid credentials. Access denied.', 13, 10, '$'

CorrectUser     db "Tester", 0
CorrectPass     db "1234", 0

UserInput       db 16, ?, 16 dup(0)
PassInput       db 16, ?, 16 dup(0)

B1Name          db 13,10, '1. Garlic Bread     - RM3 - Qty: $'
B2Name          db 13,10, '2. Chocolate Roll   - RM4 - Qty: $'
B3Name          db 13,10, '3. Butter Bun       - RM2 - Qty: $'
B4Name          db 13,10, '4. Cheese Loaf      - RM5 - Qty: $'
B5Name          db 13,10, '5. Kaya Bun         - RM3 - Qty: $'
B6Name          db 13,10, '6. Raisin Bread     - RM4 - Qty: $'
B7Name          db 13,10, '7. Whole Wheat Loaf - RM5 - Qty: $'
B8Name          db 13,10, '8. Mini Croissant   - RM2 - Qty: $'
B9Name          db 13,10, '9. Cinnamon Twist   - RM4 - Qty: $'
B10Name         db 13,10, '10. Brioche Bun     - RM6 - Qty: $'

BreadNames      dw offset B1Name, offset B2Name, offset B3Name, offset B4Name, offset B5Name
                dw offset B6Name, offset B7Name, offset B8Name, offset B9Name, offset B10Name

Stock           db 10, 8, 12, 5, 6, 9, 7, 4, 10, 3
Price           db 3, 4, 2, 5, 3, 4, 5, 2, 4, 6
QtyBuf          db '00', 13, 10, '$'

MenuText        db 13, 10, '===    Bakery POS    ===', 13, 10
                db '1. View Inventory', 13, 10
                db '2. Make Sale', 13, 10
                db '3. Restock Breads', 13, 10
                db '4. Exit', 13, 10, '$'

Menu            db 13, 10, 'Enter option: $'
MenuOpt         db ?

Pause           db 13, 10, 'Press Enter to return to main menu...$'
PauseBuf        db 2, ?, 2 dup(0)

RestockIDMsg    db 13, 10, 'Enter Bread ID to restock (1-10): $'
RestockQtyMsg   db 13, 10, 'Enter quantity to add (1-99): $'
RestockOK       db 13, 10, 'Stock successfully updated!', 13, 10, '$'
InvalidMsg      db 13, 10, 'Invalid input. Returning to menu...', 13, 10, '$'

BIDInput        db 2, ?, 2 dup(0)
QtyInput        db 3, ?, 3 dup(0)

SaleIDMsg       db 13, 10, 'Enter Bread ID to sale (1-10): $'
SaleQtyMsg      db 'Enter quantity to sale: $'
SaleTotalMsg    db 13, 10, 'Total Sale = RM$'
SaleTotalBuf    db '00', '$'
SaleDone        db 13, 10, 'Transaction complete!', 13, 10, '$'

SaleQty         db 0,0,0,0,0,0,0,0,0,0

.CODE
MAIN:
    mov ax, @DATA
    mov ds, ax

    mov ah, 09h
    lea dx, LoginBanner
    int 21h

    mov ah, 09h
    lea dx, User
    int 21h

    lea dx, UserInput
    mov ah, 0Ah
    int 21h

    mov ah, 09h
    lea dx, Pass
    int 21h

    lea dx, PassInput
    mov ah, 0Ah
    int 21h

    lea si, UserInput + 2
    call strip_cr
    lea di, CorrectUser
    call strcmp_nullterm
    jnz LOGIN_FAIL

    lea si, PassInput + 2
    call strip_cr
    lea di, CorrectPass
    call strcmp_nullterm
    jnz LOGIN_FAIL

    mov ah, 09h
    lea dx, LoginOK
    int 21h
    jmp SHOW_MENU

LOGIN_FAIL:
    mov ah, 09h
    lea dx, LoginFail
    int 21h
    jmp EXIT

SHOW_MENU:
    mov ah, 09h
    lea dx, MenuText
    int 21h

    mov ah, 09h
    lea dx, Menu
    int 21h

    mov ah, 01h
    int 21h
    sub al, '0'
    mov MenuOpt, al

    mov ah, 02h
    mov dl, 13
    int 21h
    mov dl, 10
    int 21h

    cmp MenuOpt, 1
    jne check_option_2
    jmp SHOW_INVENTORY

check_option_2:
    cmp MenuOpt, 2
    jne check_option_3
    jmp make_sale

check_option_3:
    cmp MenuOpt, 3
    jne check_option_4
    jmp restock_bread

check_option_4:
    cmp MenuOpt, 4
    jne invalid_option
    jmp EXIT

invalid_option:
    jmp SHOW_MENU

SHOW_INVENTORY:
    mov cx, 10
    mov si, offset BreadNames
    mov di, offset Stock

show_loop:
    lodsw
    mov dx, ax
    mov ah, 09h
    int 21h

    mov al, [di]
    call print_quantity

    inc di
    loop show_loop

    call wait_for_enter
    jmp SHOW_MENU

make_sale:
    mov cx, 10
    mov si, offset SaleQty
clear_loop:
    mov byte ptr [si], 0
    inc si
    loop clear_loop

    xor cx, cx

    mov ah, 09h
    lea dx, SaleIDMsg
    int 21h
    lea dx, BIDInput
    mov ah, 0Ah
    int 21h

    mov ah, 02h
    mov dl, 13
    int 21h
    mov dl, 10
    int 21h

    lea dx, SaleQtyMsg
    mov ah, 09h
    int 21h

    lea dx, QtyInput
    mov ah, 0Ah
    int 21h

    mov al, BIDInput + 2
    sub al, '1'
    cmp al, 9
    jna valid_id_sale
    jmp invalid_option
valid_id_sale:
    mov bl, al
    call parse_quantity

    mov si, offset SaleQty
    add si, bx
    mov [si], al

    mov si, offset Stock
    add si, bx
    sub [si], al

    xor cx, cx
    mov si, 0

calc_loop:
    mov al, SaleQty[si]
    mov ah, 0
    mov bl, Price[si]
    mul bl
    add cx, ax

    inc si
    cmp si, 10
    jl calc_loop

    mov ax, cx
    xor dx, dx
    mov bx, 10
    div bx
    add al, '0'
    mov SaleTotalBuf, al
    add dl, '0'
    mov SaleTotalBuf + 1, dl

    mov ah, 09h
    lea dx, SaleTotalMsg
    int 21h
    lea dx, SaleTotalBuf
    int 21h

    mov ah, 09h
    lea dx, SaleDone
    int 21h

    call wait_for_enter
    jmp SHOW_MENU

restock_bread:
    mov ah, 09h
    lea dx, RestockIDMsg
    int 21h

    lea dx, BIDInput
    mov ah, 0Ah
    int 21h

    mov al, BIDInput + 2
    sub al, '1'
    cmp al, 9
    jna valid_id_restock
    jmp invalid_input
valid_id_restock:
    mov bl, al

    mov ah, 09h
    lea dx, RestockQtyMsg
    int 21h

    lea dx, QtyInput
    mov ah, 0Ah
    int 21h

    call parse_quantity

    mov si, offset Stock
    add si, bx
    add [si], al

    mov ah, 09h
    lea dx, RestockOK
    int 21h

    call wait_for_enter
    jmp SHOW_MENU

invalid_input:
    mov ah, 09h
    lea dx, InvalidMsg
    int 21h
    call wait_for_enter
    jmp SHOW_MENU

EXIT:
    mov ah, 4Ch
    int 21h

print_quantity:
    mov ah, 0
    mov bl, 10
    div bl
    add al, '0'
    mov QtyBuf, al
    add ah, '0'
    mov QtyBuf + 1, ah
    mov ah, 09h
    lea dx, QtyBuf
    int 21h
    ret

wait_for_enter:
    mov ah, 09h
    lea dx, Pause
    int 21h

    lea dx, PauseBuf
    mov ah, 0Ah
    int 21h

    mov ah, 02h
    mov dl, 13
    int 21h
    mov dl, 10
    int 21h
    ret

parse_quantity:
    mov si, offset QtyInput
    mov cl, [si+1]
    cmp cl, 1
    je .one_digit

    mov ah, [si+2]
    sub ah, '0'
    mov al, 10
    mul ah
    mov ah, [si+3]
    sub ah, '0'
    add al, ah
    ret

.one_digit:
    mov al, [si+2]
    sub al, '0'
    ret

strip_cr:
    mov cx, 0
.next:
    mov bx, si
    add bx, cx
    mov al, [bx]
    cmp al, 0Dh
    je .strip
    cmp al, 0
    je .done
    inc cx
    jmp .next
.strip:
    mov bx, si
    add bx, cx
    mov byte ptr [bx], 0
.done:
    ret

strcmp_nullterm:
.loop:
    mov al, [si]
    mov bl, [di]
    cmp al, bl
    jne .notequal
    cmp al, 0
    je .equal
    inc si
    inc di
    jmp .loop
.notequal:
    mov ax, 1
    ret
.equal:
    xor ax, ax
    ret

END MAIN
