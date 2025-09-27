; NEVOS Bootloader - Stage 2 Menu
[BITS 16]
[ORG 0x7E00]

start:
    ; setup segmentos
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    sti

    ; limpa tela (80x25, fundo preto, texto branco)
    mov ax, 0x0600
    mov bh, 0x07
    mov cx, 0x0000
    mov dx, 0x184F
    int 0x10

    ; desenhar o quadro ASCII centralizado
    call draw_header

    ; desenhar opções
    call draw_menu

wait_key:
    mov ah, 0x00
    int 0x16        ; esperar tecla
    cmp al, '1'     ; Initialize normal
    je mode_normal
    cmp al, '2'     ; Security
    je mode_secure
    cmp al, '3'
    je mode_nodrives
    cmp al, '4'
    je mode_tests
    cmp al, '5'
    je mode_terminal
    cmp al, '6'
    je mode_reboot
    jmp wait_key

; --- modos ---
mode_normal:
    mov si, msg_normal
    call print_string
    jmp $

mode_secure:
    mov si, msg_secure
    call print_string
    jmp $

mode_nodrives:
    mov si, msg_nodrives
    call print_string
    jmp $

mode_tests:
    mov si, msg_tests
    call print_string
    jmp $

mode_terminal:
    mov si, msg_terminal
    call print_string
    jmp $

mode_reboot:
    int 0x19        ; reboot pelo BIOS
    jmp $

; --- Funções ---
set_cursor:         ; DH = linha, DL = coluna
    mov ah, 0x02
    mov bh, 0x00
    int 0x10
    ret

print_string:       ; imprime string terminada em 0
    lodsb
    cmp al, 0
    je .done
    mov ah, 0x0E
    mov bh, 0x00
    mov bl, 0x07
    int 0x10
    jmp print_string
.done:
    ret

draw_header:
    ; linha 3, centralizada
    mov dh, 3
    mov dl, 25
    call set_cursor
    mov si, line_top
    call print_string

    mov dh, 4
    mov dl, 25
    call set_cursor
    mov si, line_empty
    call print_string

    mov dh, 5
    mov dl, 25
    call set_cursor
    mov si, line_title
    call print_string

    mov dh, 6
    mov dl, 25
    call set_cursor
    mov si, line_stage
    call print_string

    mov dh, 7
    mov dl, 25
    call set_cursor
    mov si, line_empty
    call print_string

    mov dh, 8
    mov dl, 25
    call set_cursor
    mov si, line_bottom
    call print_string
    ret

draw_menu:
    ; lado esquerdo
    mov dh, 12
    mov dl, 10
    call set_cursor
    mov si, opt1
    call print_string

    mov dh, 14
    mov dl, 10
    call set_cursor
    mov si, opt3
    call print_string

    mov dh, 16
    mov dl, 10
    call set_cursor
    mov si, opt5
    call print_string

    ; linha divisória central
    mov cx, 6
    mov dh, 11
    mov dl, 39
.drawline:
    call set_cursor
    mov al, '|'
    mov ah, 0x0E
    mov bh, 0x00
    mov bl, 0x07
    int 0x10
    inc dh
    loop .drawline

    ; lado direito
    mov dh, 12
    mov dl, 45
    call set_cursor
    mov si, opt2
    call print_string

    mov dh, 14
    mov dl, 45
    call set_cursor
    mov si, opt4
    call print_string

    mov dh, 16
    mov dl, 45
    call set_cursor
    mov si, opt6
    call print_string
    ret

; --- Dados ASCII ---
line_top    db "##############################",0
line_bottom db "##############################",0
line_empty  db "#                            #",0
line_title  db "#          N E V O S         #",0
line_stage  db "#  Bootloader v0.1 - Stage2  #",0

opt1 db "1--> Initialize normal",0
opt2 db "2--> Initialize in security mode",0
opt3 db "3--> Initialize with no drives",0
opt4 db "4--> Initialize tests",0
opt5 db "5--> Terminal Mode",0
opt6 db "6--> Reboot",0

msg_normal   db 0x0D,0x0A,"[Boot] Normal Init...",0
msg_secure   db 0x0D,0x0A,"[Boot] Secure Mode...",0
msg_nodrives db 0x0D,0x0A,"[Boot] No Drives Init...",0
msg_tests    db 0x0D,0x0A,"[Boot] Running Tests...",0
msg_terminal db 0x0D,0x0A,"[Boot] Terminal Mode...",0

times 2048-($-$$) db 0
