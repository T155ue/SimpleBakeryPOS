; bakery.asm with menu loop

section .data
    ; Login banner and messages
    loginBanner  db "==== Bakery POS Login ====", 0xA, 0
    userPrompt   db "Enter username: ", 0
    passPrompt   db "Enter password: ", 0
    loginSuccess db 0xA, "Login successful!", 0xA, 0
    loginFail    db 0xA, "Invalid credentials. Access denied.", 0xA, 0

    ; Stored credentialsa
    correctUser db "Tester", 0
    correctPass db "1234", 0

    ; Main interface menu
    mainMenu db 0xA, "===    Bakery POS    ===", 0xA, \
                 "1. View Inventory", 0xA, \
                 "2. Make Sale", 0xA, \
                 "3. View Reports", 0xA, \
                 "4. Restock", 0xA, \
                 "5. Exit", 0xA, 0

    ; Inventory - bread names
    bread1 db "1. Garlic Bread     - RM3 - Qty: ", 0
    bread2 db "2. Chocolate Roll   - RM4 - Qty: ", 0
    bread3 db "3. Butter Bun       - RM2 - Qty: ", 0
    bread4 db "4. Cheese Loaf      - RM5 - Qty: ", 0

    ; Price table and stock
    breadPrices db 3, 4, 2, 5
    breadQuantities db 10, 8, 12, 5

    qtyBuffer db "00", 0xA, 0
    menuPrompt db 0xA, "Enter option: ", 0x20, 0
    newline db 0xA
    pauseMsg db 0xA, 0
    backMsg db 0xA, "Press Enter to return to main menu...", 0

    ; Restock prompts
    restockPrompt db 0xA, "Enter Bread ID to restock (1-4): ", 0
    qtyPrompt db "Enter quantity to add (2 digits): ", 0
    restockSuccess db 0xA, "Stock successfully updated!", 0xA, 0
    overflowMsg db "Error: stock exceeds limit (255)", 0xA, 0

section .bss
    userInput resb 16
    passInput resb 16
    menuInput resb 2
    breadIDInput resb 2
    restockQtyInput resb 3
    dummyInput resb 2

section .text
    global _start

_start:
    ; Print login banner
    mov eax, 4
    mov ebx, 1
    mov ecx, loginBanner
    mov edx, 27
    int 0x80

    ; Username
    mov eax, 4
    mov ebx, 1
    mov ecx, userPrompt
    mov edx, 17
    int 0x80

    mov eax, 3
    mov ebx, 0
    mov ecx, userInput
    mov edx, 16
    int 0x80
    call strip_newline_user

    ; Password
    mov eax, 4
    mov ebx, 1
    mov ecx, passPrompt
    mov edx, 17
    int 0x80

    mov eax, 3
    mov ebx, 0
    mov ecx, passInput
    mov edx, 16
    int 0x80
    call strip_newline_pass

    ; Validate
    mov esi, userInput
    mov edi, correctUser
    call strcmp
    cmp eax, 0
    jne login_failed

    mov esi, passInput
    mov edi, correctPass
    call strcmp
    cmp eax, 0
    jne login_failed

login_success:
    mov eax, 4
    mov ebx, 1
    mov ecx, loginSuccess
    mov edx, 21
    int 0x80

main_menu:
    mov eax, 4
    mov ebx, 1
    mov ecx, mainMenu
    mov edx, 102
    int 0x80

    mov eax, 4
    mov ebx, 1
    mov ecx, menuPrompt
    mov edx, 16
    int 0x80

    mov eax, 3
    mov ebx, 0
    mov ecx, menuInput
    mov edx, 2
    int 0x80

    mov eax, 4
    mov ebx, 1
    mov ecx, newline
    mov edx, 1
    int 0x80

    cmp byte [menuInput], '1'
    je view_inventory

    cmp byte [menuInput], '4'
    je restock

    cmp byte [menuInput], '5'
    je exit_program

    jmp main_menu

login_failed:
    mov eax, 4
    mov ebx, 1
    mov ecx, loginFail
    mov edx, 39
    int 0x80

exit_program:
    mov eax, 1
    xor ebx, ebx
    int 0x80

; === Utilities ===

strip_newline_user:
    mov ecx, userInput
.find_nl_user:
    mov al, [ecx]
    cmp al, 0xA
    je .replace
    cmp al, 0
    je .done
    inc ecx
    jmp .find_nl_user
.replace:
    mov byte [ecx], 0
.done:
    ret

strip_newline_pass:
    mov ecx, passInput
.find_nl_pass:
    mov al, [ecx]
    cmp al, 0xA
    je .replace
    cmp al, 0
    je .done
    inc ecx
    jmp .find_nl_pass
.replace:
    mov byte [ecx], 0
.done:
    ret

strcmp:
    xor eax, eax
.next_char:
    mov al, [esi]
    cmp al, [edi]
    jne .not_equal
    cmp al, 0
    je .equal
    inc esi
    inc edi
    jmp .next_char
.not_equal:
    mov eax, 1
    ret
.equal:
    xor eax, eax
    ret

wait_for_enter:
    mov eax, 4
    mov ebx, 1
    mov ecx, backMsg
    mov edx, 36
    int 0x80

    mov eax, 3
    mov ebx, 0
    mov ecx, dummyInput
    mov edx, 2
    int 0x80
    ret

; === View Inventory ===
view_inventory:
    mov eax, 4
    mov ebx, 1
    mov ecx, bread1
    mov edx, 34
    int 0x80
    movzx esi, byte [breadQuantities]
    call print_quantity

    mov eax, 4
    mov ebx, 1
    mov ecx, bread2
    mov edx, 34
    int 0x80
    movzx esi, byte [breadQuantities + 1]
    call print_quantity

    mov eax, 4
    mov ebx, 1
    mov ecx, bread3
    mov edx, 34
    int 0x80
    movzx esi, byte [breadQuantities + 2]
    call print_quantity

    mov eax, 4
    mov ebx, 1
    mov ecx, bread4
    mov edx, 34
    int 0x80
    movzx esi, byte [breadQuantities + 3]
    call print_quantity

    call wait_for_enter
    jmp main_menu

; === Restock Feature ===
restock:
    mov eax, 4
    mov ebx, 1
    mov ecx, restockPrompt
    mov edx, 38
    int 0x80

    mov eax, 4
    mov ebx, 1
    mov ecx, newline
    mov edx, 1
    int 0x80

    mov eax, 3
    mov ebx, 0
    mov ecx, breadIDInput
    mov edx, 2
    int 0x80

    movzx esi, byte [breadIDInput]
    sub esi, '1'
    cmp esi, 3
    jae main_menu

    mov eax, 4
    mov ebx, 1
    mov ecx, qtyPrompt
    mov edx, 33
    int 0x80

    mov eax, 3
    mov ebx, 0
    mov ecx, restockQtyInput
    mov edx, 3
    int 0x80

    movzx eax, byte [restockQtyInput]
    sub eax, '0'
    movzx ebx, byte [restockQtyInput + 1]
    sub ebx, '0'
    mov ecx, 10
    mul ecx
    add eax, ebx

    movzx edx, byte [breadQuantities + esi]
    add edx, eax
    cmp edx, 255
    ja overflow_error
    mov [breadQuantities + esi], dl

    mov eax, 4
    mov ebx, 1
    mov ecx, restockSuccess
    mov edx, 26
    int 0x80

    call wait_for_enter
    jmp main_menu

overflow_error:
    mov eax, 4
    mov ebx, 1
    mov ecx, overflowMsg
    mov edx, 31
    int 0x80
    call wait_for_enter
    jmp main_menu

; === Print 2-digit quantity in ESI ===
print_quantity:
    mov ecx, qtyBuffer
    mov eax, esi
    mov ebx, 10
    xor edx, edx
    div ebx
    add al, '0'
    mov [ecx], al
    add dl, '0'
    mov [ecx + 1], dl
    mov eax, 4
    mov ebx, 1
    mov ecx, qtyBuffer
    mov edx, 3
    int 0x80
    ret
