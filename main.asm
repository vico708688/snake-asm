
BITS 64 ; précise l'architecture à NASM
GLOBAL main

; permet d'activer ou désactiver l'affichage des touches claviers immédiatement
EXTERN tcgetattr, tcsetattr

DEFAULT rel ; relative addresses

%define width 64
%define height 32

section .rodata
    c_dr         db 0xE2,0x94,0x8C,0
    c_dl         db 0xE2,0x94,0x90,0
    l_h          db 0xE2,0x94,0x80,0
    l_v          db 0xE2,0x94,0x82,0
    c_ur         db 0xE2,0x94,0x94,0
    c_ul         db 0xE2,0x94,0x98,0
    body         db 0xE2,0x96,0x88,0

    new_line     db 10,0

    hide_cursor  db 27,"[?25l",0 ; 27 : escape key in decimal
    show_cursor  db 27,"[?25h",0

    home_cursor  db 27,"[H",0
    start_cursor db 27,"[18;33H",0
    end_cursor   db 27,"[35;64H",0

%include "termios.inc"
section .bss
    buffer      resb 4096 ; buffer de la grille
    oldtcattr   resb TERM_SIZE
    newtcattr   resb TERM_SIZE
    tail        resb 4
    key_pressed resb 3
    playing     resb 1

section .text

draw_grid:
    ; creation of a long string containing the entire grid

    lea rdi, [buffer]

    ; first line
    mov rcx, width ; nb de caractères sur une ligne
    mov eax, dword [c_dr] ; eax car "┌" a une longueur de 3 bytes, il nous faut donc au minimum 4 bytes
    stosd ; "ajoute" c_dr à la chaine de caractère (copie le registre eax dans la cellule mémoire à
          ; l'adresse es:di (es=extra segment) et incrémente di de 4 (dword))
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

    inc rdi ; il faut maintenant compenser le byte écrit en trop (pas forcément nécessaire puisque c_ul est terminé par 0)
    mov byte [rdi],0 ; null-terminated string -> met 0 dans l'octet stocké à la position rdi en mémoire
                     ; puisqu'on veut écrire en mémoire, il faut préciser sur combien d'octets, ex :
                     ; byte: 1
                     ; word: 2
                     ; long: 4 (int), 8 (float)
                     ; quad: 8

    ; affichage de la grille    
    mov rax, 1
    mov rdi, 1
    mov rsi, buffer
    mov rdx, 4096
    syscall

    ret

init:
    cld ; met le flag DF à 0 (incrémentation du registre di par stosd)

    ; hide cursor
    mov rax, 1
    mov rdi, 1
    mov rsi, hide_cursor
    mov rdx, 7
    syscall

    ; désactivation de l'affichage des touches clavier
    ; tcgetattr(0, &oldtcattr)
    mov rdi, 0
    lea rsi, [rel oldtcattr] ; important d'utiliser lea au lieu de mov, on veut un pointeur vers une adresse relative
                             ; (flag no-pie) !!!
    call tcgetattr ; sur les call : vérifier l'alignement de la stack sur 16 bytes

    ; copie oldtcattr dans newtcattr
    lea rsi, [rel oldtcattr]
    lea rdi, [rel newtcattr]
    mov rcx, TERM_SIZE
    rep movsb

    ; désactivation des flags ICANON ET ECHO
    mov eax, [newtcattr + C_LFLAG]
    and eax, ~(ICANON_V | ECHO_V)
    mov [newtcattr + C_LFLAG], eax ; enregistrement des modifications

    ;tcsetattr(0, 0, &newtcattr)
    mov rdi, 0
    mov rsi, TCSANOW_V
    lea rdx, [rel newtcattr]
    call tcsetattr

    call draw_grid

    ; met le curseur à la position (0,0)
    mov rax, 1
    mov rdi, 1
    mov rsi, home_cursor
    mov rdx, 4
    syscall

    ret

main_loop:
    ; update snake pos

    ; key-listener
    xor rax, rax ; apparemment plus court: xor eax, eax et met automatiquement les MSB à 0
    mov rdi, 0
    mov rsi, key_pressed
    mov rdx, 3 ; touches =>  ← : 0x445b1b , → : 0x435b1b , ↓ : 0x425b1b , ↑ : 0x415b1b
    syscall

    mov al, [body]
    mov rdi, tail
    mov rcx, 1
    rep stosb ; copie un octet de l'adresse de si dans di, cx fois
    inc rdi
    mov byte [rdi], 0

    mov rax, 1
    mov rdi, 1
    mov rsi, tail
    mov rdx, 4
    syscall

    ; update apple pos


    ; tant qu'on est pas mort, on joue
    mov al, [playing]
    dec byte [playing] ; DEBUG
    cmp al, 0
    jz end_game
    jmp main_loop

; add menu
start_game:
    mov rax, 1
    mov rdi, 1
    mov rsi, start_cursor
    mov rdx, 9
    syscall

    mov rax, 1
    mov rdi, 1
    mov rsi, body
    mov rdx, 4
    syscall

    ; on lance la partie
    inc byte [playing]
    ret

end_game:
    nop
    jmp end_proc

end_proc:
    ; shows cursor places cursor at the end of the code
    mov rax, 1
    mov rdi, 1
    mov rsi, show_cursor
    mov rdx, 7
    syscall

    mov rax, 1
    mov rdi, 1
    mov rsi, end_cursor
    mov rdx, 9
    syscall

    mov rax, 1
    mov rdi, 1
    mov rsi, new_line
    mov rdx, 2
    syscall

    ; activation de l'affichage des touches clavier
    ; tcsetattr(0, 0, &oldtcattr)
    mov rdi, 0
    mov rsi, 0
    lea rdx, [rel oldtcattr]
    call tcsetattr

    mov rax, 60
    xor rdi, rdi
    syscall

main:
    push rbp ; décale la stack de 8
    mov rbp, rsp
    sub rsp, 8 ; ABI SysV demande l'alignement de la stack sur 16 octets avant un appel à call

    call init
    call start_game
    call main_loop

    add rsp, 8
    pop rbp
    jmp end_proc