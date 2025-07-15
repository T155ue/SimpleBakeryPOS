.MODEL SMALL
.STACK 100h

.DATA
loginBanner      db 13, 10, '==== Bakery POS Login ====$'
userPrompt       db 13, 10, 'Enter username: $'
passPrompt       db 13, 10, 'Enter password: $'
loginSuccess     db 13, 10, 'Login successful!', 13, 10, '$'
loginFail        db 13, 10, 'Invalid credentials. Access denied.', 13, 10, '$'

correctUser      db "Tester", 0
correctPass      db "1234", 0

userInputStruct  db 16, ?, 16 dup(0)
passInputStruct  db 16, ?, 16 dup(0)

; Inventory data
bread1Name db 13, 10, '1. Garlic Bread     - RM3 - Qty: $'
bread2Name db 13, 10, '2. Chocolate Roll   - RM4 - Qty: $'
bread3Name db 13, 10, '3. Butter Bun       - RM2 - Qty: $'
bread4Name db 13, 10, '4. Cheese Loaf      - RM5 - Qty: $'

breadQuantities db 10, 8, 12, 5  
breadPrices db 3, 4, 2, 5         
qtyBuffer db '00', 13, 10, '$'   

; Menu and input
mainMenu db 13, 10, '===    Bakery POS    ===', 13, 10
         db '1. View Inventory', 13, 10
         db '2. Make Sale', 13, 10
         db '3. Restock Breads', 13, 10
         db '4. Exit', 13, 10, '$'

menuPrompt db 13, 10, 'Enter option: $'
menuInput  db ?

; Pause prompt
backPrompt db 13, 10, 'Press Enter to return to main menu...$'
dummyBuffer db 2, ?, 2 dup(0)

; Restock prompts
restockIDPrompt   db 13, 10, 'Enter Bread ID to restock (1-4): $'
restockQtyPrompt  db 13, 10, 'Enter quantity to add (1-99): $'
restockSuccessMsg db 13, 10, 'Stock successfully updated!', 13, 10, '$'
invalidMsg        db 13, 10, 'Invalid input. Returning to menu...', 13, 10, '$'

breadIDInput      db 2, ?, 2 dup(0)
restockQtyInput   db 3, ?, 3 dup(0)

; Sale prompts
saleIDPrompt      db 13, 10, 'Enter Bread ID to purchase (1-4): $'
saleQtyPrompt     db 'Enter quantity to buy: $'
saleResultMsg     db 13, 10, 'Total Sale = RM$'
saleTotalBuffer   db '00', '$'
saleDonePrompt    db 13, 10, 'Transaction complete!', 13, 10, '$'

saleQtyTotals     db 0, 0, 0, 0  

.CODE
MAIN:
    mov ax, @DATA
    mov ds, ax

    ; Login 
    mov ah, 09h
    lea dx, loginBanner
    int 21h

    mov ah, 09h
    lea dx, userPrompt
    int 21h

    lea dx, userInputStruct
    mov ah, 0Ah
    int 21h

    mov ah, 09h
    lea dx, passPrompt
    int 21h

    lea dx, passInputStruct
    mov ah, 0Ah
    int 21h

    lea si, userInputStruct + 2
    call strip_cr
    lea di, correctUser
    call strcmp_nullterm
    jnz LOGIN_FAIL

    lea si, passInputStruct + 2
    call strip_cr
    lea di, correctPass
    call strcmp_nullterm
    jnz LOGIN_FAIL

    mov ah, 09h
    lea dx, loginSuccess
    int 21h
    jmp SHOW_MENU

LOGIN_FAIL:
    mov ah, 09h
    lea dx, loginFail
    int 21h
    jmp EXIT

; MAIN MENU
SHOW_MENU:
    mov ah, 09h
    lea dx, mainMenu
    int 21h

    mov ah, 09h
    lea dx, menuPrompt
    int 21h

    mov ah, 01h
    int 21h
    sub al, '0'
    mov menuInput, al

    mov ah, 02h
    mov dl, 13
    int 21h
    mov dl, 10
    int 21h

    cmp menuInput, 1
    jne check_option_2
    jmp SHOW_INVENTORY

check_option_2:
    cmp menuInput, 2
    jne check_option_3
    jmp make_sale

check_option_3:
    cmp menuInput, 3
    jne check_option_4
    jmp restock_bread

check_option_4:
    cmp menuInput, 4
    jne invalid_option
    jmp EXIT

invalid_option:
    jmp SHOW_MENU

; VIEW INVENTORY
SHOW_INVENTORY:
    mov ah, 09h
    lea dx, bread1Name
    int 21h
    mov al, breadQuantities
    call print_quantity

    mov ah, 09h
    lea dx, bread2Name
    int 21h
    mov al, breadQuantities + 1
    call print_quantity

    mov ah, 09h
    lea dx, bread3Name
    int 21h
    mov al, breadQuantities + 2
    call print_quantity

    mov ah, 09h
    lea dx, bread4Name
    int 21h
    mov al, breadQuantities + 3
    call print_quantity

    call wait_for_enter
    jmp SHOW_MENU

; MAKE SALE
make_sale:
    ; Clear saleQtyTotals
    mov cx, 4
    mov si, offset saleQtyTotals
clear_loop:
    mov byte ptr [si], 0
    inc si
    loop clear_loop

    xor cx, cx 

    mov ah, 09h
    lea dx, saleIDPrompt
    int 21h
    lea dx, breadIDInput
    mov ah, 0Ah
    int 21h

    mov ah, 02h
    mov dl, 13
    int 21h
    mov dl, 10
    int 21h

    ; Prompt for quantity
    lea dx, saleQtyPrompt
    mov ah, 09h
    int 21h

    lea dx, restockQtyInput
    mov ah, 0Ah
    int 21h

    ; Get Bread Index 
    mov al, breadIDInput + 2
    sub al, '1'
    cmp al, 3
    ja invalid_option
    mov bl, al 

    ; Convert quantity using routine
    call parse_quantity

    ; Store in saleQtyTotals[BL]
    mov si, offset saleQtyTotals
    add si, bx
    mov [si], al

    ; Deduct quantity directly from inventory
    mov si, offset breadQuantities
    add si, bx
    sub [si], al

    ; Calculate total
    xor cx, cx
    mov si, 0

calc_loop:
    mov al, saleQtyTotals[si]
    mov ah, 0
    mov bl, breadPrices[si]
    mul bl
    add cx, ax

    inc si
    cmp si, 4
    jl calc_loop

    ; Convert CX to ASCII and store in saleTotalBuffer as 2 digits
    mov ax, cx
    xor dx, dx
    mov bx, 10
    div bx
    add al, '0'
    mov saleTotalBuffer, al
    add dl, '0'
    mov saleTotalBuffer + 1, dl

    mov ah, 09h
    lea dx, saleResultMsg
    int 21h
    lea dx, saleTotalBuffer
    int 21h

    mov ah, 09h
    lea dx, saleDonePrompt
    int 21h

    call wait_for_enter
    jmp SHOW_MENU

; RESTOCK BREAD
restock_bread:
    mov ah, 09h
    lea dx, restockIDPrompt
    int 21h

    lea dx, breadIDInput
    mov ah, 0Ah
    int 21h

    mov al, breadIDInput + 2
    sub al, '1'
    cmp al, 3
    ja invalid_input
    mov bl, al

    mov ah, 09h
    lea dx, restockQtyPrompt
    int 21h

    lea dx, restockQtyInput
    mov ah, 0Ah
    int 21h

    call parse_quantity

    mov si, offset breadQuantities
    add si, bx
    add [si], al

    mov ah, 09h
    lea dx, restockSuccessMsg
    int 21h

    call wait_for_enter
    jmp SHOW_MENU

invalid_input:
    mov ah, 09h
    lea dx, invalidMsg
    int 21h
    call wait_for_enter
    jmp SHOW_MENU

EXIT:
    mov ah, 4Ch
    int 21h

; Print quantity in AL as 2-digit ASCII 
print_quantity:
    mov ah, 0
    mov bl, 10
    div bl         
    add al, '0'
    mov qtyBuffer, al
    add ah, '0'
    mov qtyBuffer + 1, ah
    mov ah, 09h
    lea dx, qtyBuffer
    int 21h
    ret

; Wait for Enter key
wait_for_enter:
    mov ah, 09h
    lea dx, backPrompt
    int 21h

    lea dx, dummyBuffer
    mov ah, 0Ah
    int 21h

    mov ah, 02h
    mov dl, 13
    int 21h
    mov dl, 10
    int 21h
    ret

; Convert 1 or 2 digit quantity input in restockQtyInput to AL
parse_quantity:
    mov si, offset restockQtyInput
    mov cl, [si+1]   
    cmp cl, 1
    je .one_digit

    ; 2-digit input
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

;Strip CR from input buffer
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

;Null-Terminated String Compare
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
