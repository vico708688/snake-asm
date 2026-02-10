
BITS 64 ; précise l'architecture à NASM
GLOBAL main
DEFAULT rel ; relative addresses

EXTERN printf
EXTERN fflush
EXTERN stdout

%define width 64
%define height 32

section .data
    c_dr        db "┌" ; 0xE2,0x94,0x8C
    c_dl        db "┐" ; 0xE2,0x94,0x90
    l_h         db "─" ; 0xE2,0x94,0x80
    l_v         db "│"
    c_ur        db "└"
    c_ul        db "┘"
    body        db 0xE2,0x96,0x88

    fmt         db "%s",0

    new_line    db 13,10,0

    hide_cursor db 27,"[?25l",0 ; 27 : escape key in decimal
    show_cursor db 27,"[?25h",0

    home_cursor db 27,"[32;16H",0
    end_cursor  db 27,"[34;64H",0

section .bss
    buffer   resb 4096 ; buffer de la grille
    tail     resb 4
    head     resb 1
    snake_x  resb 1
    snake_y  resb 1
    snake_vx resb 1
    snake_vy resb 1
    apple_x  resb 1
    apple_y  resb 1

section .text

draw_grid:
    ; creation of a long string containing the entire grid

    mov rdi, buffer

    ; first line
    mov rcx, width ; nb de caractères sur une ligne
    mov eax, dword [c_dr] ; eax car "┌" a une longueur de 3 bytes, il nous faut donc au minimum 4 bytes
    stosd ; "ajoute" c_dr à la chaine de caractère
    dec rdi ; compense le byte en trop de eax ("┌" a une longueur de 3 bytes, pas 4, il faut donc reculer de 1 byte)
    mov eax, dword [l_h]

r0: ; first line
    stosd
    dec rdi
    dec rcx
    jnz r0 ; ajoute tous les "─" de la ligne

    mov eax, dword [c_dl]
    stosd
    dec rdi
    mov eax, 10
    stosb
    mov rdx, height
    
r1: ; middle lines
    mov eax, dword [l_v]
    stosd
    dec rdi
    mov rcx, width
    mov al, "."
    rep stosb
    mov eax, dword [l_v]
    stosd
    dec rdi
    mov al, 10
    stosb
    dec rdx
    jnz r1

    ; last line
    mov rcx, width
    mov eax, dword [c_ur]
    stosd
    dec rdi
    mov eax, dword [l_h]

r2: ; last line
    stosd
    dec rdi
    dec rcx
    jnz r2

    mov eax, dword [c_ul]
    stosd

    mov byte [rdi],0 ; null-terminated string

    ; affichage de la grille    
    mov rdi, buffer
    xor rax, rax
    call printf

    ret

init:
    cld ; met le flag DF à 0 (incrémentation du registre di par stosd)

    ; hide cursor
    ;mov rdi, hide_cursor
    ;xor rax, rax
    ;call printf

    call draw_grid

    xor rax, rax
    mov rdi, [rel stdout] ; ATTENTION : addresse relative se trouvant en mémoire ([])
    call fflush

    ret

main_loop:
    ; update snake pos
    xor rax, rax
    mov rdi, home_cursor
    call printf

    mov rdi, tail
    mov rsi, body
    mov rcx, 3
    rep movsb ; copie un octet de l'adresse de si dans di
    mov byte [rdi], 0

    xor rax, rax
    mov rdi, fmt
    mov rsi, tail
    call printf

    xor rax, rax
    mov rdi, [rel stdout]
    call fflush
    ; update apple pos

    ret


exit:
    ; show cursor
    xor rax, rax
    mov rdi, show_cursor
    call printf

    ; place cursor at the end of the code
    xor rax, rax
    mov rdi, end_cursor
    call printf

    xor rax, rax
    mov rdi, new_line
    call printf

    xor rax, rax
    mov rdi, [rel stdout]
    call fflush

    mov rax, 1
    mov rdi, [rel stdout]
    mov rsi, new_line
    mov rdx, 3
    syscall

    xor rax, rax
    mov rdi, [rel stdout]
    call fflush

    mov rax, 60
    xor rdi, rdi
    syscall

main:
    push rbp
    mov rbp, rsp
    sub rsp, 8

    call init
    call main_loop

    add rsp, 8
    pop rbp
    jmp exit