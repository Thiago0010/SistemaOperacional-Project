

[BITS 16]
[ORG 0x7E00]

SECTION .text

start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    ; mov sp, 0x7C00  ; Set up stack below boot sector area
    sti

    mov [boot_drive], dl  ; Save boot drive number

    ; Print welcome message
    mov si, msg_stage2
    call print_string

    ; Load essential drivers (simulated)
    call load_drivers

    ; Check for Ctrl + N shortcut (give 5 seconds window)
    call check_ctrl_n

    ; Read config file
    call read_config

    ; Check if config has content
    call check_config_content
    cmp ax, 1
    je load_kernel

    ; If no content, load stage 3
    jmp load_stage3

load_kernel:
    mov si, msg_loading_kernel
    call print_string

    ; Load kernel from LBA 20, 10 sectors to 0x1000:0000
    mov eax, 20           ; Start LBA
    mov cx, 10            ; Sectors
    mov bx, 0x0000        ; Offset
    mov dx, 0x1000        ; Segment (0x10000 physical = 0x1000:0000)
    call read_disk
    jc error

    ; Jump to kernel (assuming kernel ORG 0x0000 in segment 0x1000)
    jmp 0x1000:0000

load_stage3:
    mov si, msg_loading_stage3
    call print_string

    ; Load stage 3 from LBA 30, 5 sectors to 0x900:0000
    mov eax, 30           ; Start LBA
    mov cx, 5             ; Sectors
    mov bx, 0x0000        ; Offset
    mov dx, 0x900         ; Segment (0x9000 physical = 0x900:0000)
    call read_disk
    jc error

    ; Jump to stage 3 (assuming stage 3 ORG 0x0000 in segment 0x900)
    jmp 0x900:0000

error:
    mov si, msg_error
    call print_string
    .error_loop:
        call play_error_sound
        jmp .error_loop  ; Infinite loop of beeps

; --- Functions ---

load_drivers:
    mov si, msg_loading_drivers
    call print_string
    ; Simulate loading drivers (e.g., keyboard, disk)
    ; Add more if needed, like initializing interrupts
    ret

check_ctrl_n:
    mov si, msg_press_ctrl_n
    call print_string

    ; Get start ticks
    mov ah, 0x00
    int 0x1A
    mov [start_ticks], dx  ; Low word of ticks

    .check_loop:
        mov ah, 0x12   ; Get extended keyboard flags
        int 0x16
        test ah, 0x04  ; Bit 2: Ctrl (either left or right)
        jz .no_ctrl

        mov ah, 0x01   ; Check if key available
        int 0x16
        jz .no_key

        mov ah, 0x00   ; Get keystroke
        int 0x16       ; AL = ASCII, AH = scancode
        cmp al, 'N'    ; Check for 'N'
        je enter_terminal
        cmp al, 'n'
        je enter_terminal

    .no_key:
    .no_ctrl:
        ; Check time
        mov ah, 0x00
        int 0x1A
        sub dx, [start_ticks]
        cmp dx, 91     ; Approx 5 seconds (18.2 ticks/sec * 5 ≈ 91)
        jb .check_loop
        ; Timeout, continue
        ret

enter_terminal:
    mov si, msg_terminal
    call print_string

    .terminal_loop:
        mov si, prompt
        call print_string

        ; Read command (simple, up to 32 chars)
        mov di, command_buffer
        mov cx, 32
        .read_char:
            mov ah, 0x00
            int 0x16
            cmp al, 0x0D  ; Enter
            je .exec
            cmp al, 0x08  ; Backspace
            je .backspace
            stosb         ; Store char
            mov ah, 0x0E  ; Echo
            int 0x10
            loop .read_char
        .exec:
            mov byte [di], 0  ; Null terminate
            ; Execute simple commands (add more as liked)
            mov si, command_buffer
            call strcmp_help   ; Compare with "help"
            cmp ax, 0
            je .help
            call strcmp_exit
            cmp ax, 0
            je .exit_terminal
            ; Unknown
            mov si, msg_unknown_cmd
            call print_string
            jmp .terminal_loop

        .help:
            mov si, msg_help
            call print_string
            jmp .terminal_loop

        .exit_terminal:
            mov si, msg_exit_terminal
            call print_string
            ret  ; Exit terminal, continue boot

        .backspace:
            ; Simple backspace handling
            cmp di, command_buffer
            je .read_char  ; Can't backspace if empty
            dec di
            mov ah, 0x0E
            mov al, 0x08
            int 0x10
            mov al, ' '
            int 0x10
            mov al, 0x08
            int 0x10
            inc cx
            jmp .read_char

read_config:
    mov si, msg_reading_config
    call print_string

    ; Read 1 sector from LBA 10 to 0x200:0000 (physical 0x2000, below 1MB)
    mov eax, 10           ; LBA
    mov cx, 1             ; Sectors
    mov bx, 0x0000        ; Offset
    mov dx, 0x200         ; Segment (0x2000 physical = 0x200:0000)
    call read_disk
    jc error
    ret

check_config_content:
    push es
    mov ax, 0x200
    mov es, ax
    xor di, di
    mov cx, 512 / 2  ; Check 512 bytes (words)
    xor ax, ax
    repe scasw        ; Scan for zero, stops if non-zero
    setnz al         ; AL=1 if ZF=0 (found non-zero, has content)
    pop es
    ret

read_disk:
    ; eax: LBA start (lower 32 bits)
    ; cx: num sectors (max 127)
    ; bx: buffer offset
    ; dx: buffer segment
    ; Uses DAP

    cmp cx, 127
    jbe .good_size
    ; Handle large reads if needed, but for simplicity assume small

    .good_size:
        mov [dap_lba_lower], eax
        mov [dap_num_sectors], cx
        mov [dap_buf_offset], bx
        mov [dap_buf_segment], dx
        mov dl, [boot_drive]
        mov si, dap
        mov ah, 0x42
        int 0x13
        ret  ; CF set on error

play_error_sound:
    ; Play 440Hz tone for 0.5 second (A4 note), then pause 0.5s for beep effect
    mov ax, 2712  ; Freq divider for 440Hz (1193180 / 440 ≈ 2712)

    ; Tone on
    pusha
    mov bx, ax
    mov al, 182
    out 0x43, al
    mov ax, bx
    out 0x42, al
    mov al, ah
    out 0x42, al
    in al, 0x61
    or al, 03h
    out 0x61, al

    ; Wait 0.5s
    mov cx, 0x0007  ; Approx 0.5 second (CX:DX = 500,000 us)
    mov dx, 0xA120
    mov ah, 0x86
    int 0x15

    ; Tone off
    in al, 0x61
    and al, 0FCh
    out 0x61, al
    popa

    ; Pause 0.5s
    mov cx, 0x0007
    mov dx, 0xA120
    mov ah, 0x86
    int 0x15

    ret

print_string:
    mov ah, 0x0E
    .loop:
        lodsb
        or al, al
        jz .done
        int 0x10
        jmp .loop
    .done:
        ret

strcmp_help:  ; strcmp si with cmd_help
    mov di, cmd_help
    .cmp_loop:
        cmpsb
        jne .not_equal
        mov al, [si-1]
        or al, al  ; Check null
        jz .equal
        jmp .cmp_loop
    .equal:
        mov ax, 0
        ret
    .not_equal:
        mov ax, 1
        ret

strcmp_exit:  ; strcmp si with cmd_exit
    mov di, cmd_exit
    .cmp_loop:
        cmpsb
        jne .not_equal
        mov al, [si-1]
        or al, al  ; Check null
        jz .equal
        jmp .cmp_loop
    .equal:
        mov ax, 0
        ret
    .not_equal:
        mov ax, 1
        ret

; --- Data ---

msg_stage2: db 'Stage 2 Bootloader Loaded!', 0x0D, 0x0A, 0
msg_loading_drivers: db 'Loading essential drivers...', 0x0D, 0x0A, 0
msg_press_ctrl_n: db 'Press Ctrl + N for root terminal (5 sec window)...', 0x0D, 0x0A, 0
msg_terminal: db 'Entering root terminal...', 0x0D, 0x0A, 0
prompt: db '# ', 0
msg_unknown_cmd: db 'Unknown command', 0x0D, 0x0A, 0
msg_help: db 'Commands: help, exit', 0x0D, 0x0A, 0
msg_exit_terminal: db 'Exiting terminal...', 0x0D, 0x0A, 0
msg_reading_config: db 'Reading config file...', 0x0D, 0x0A, 0
msg_loading_kernel: db 'Config found, loading kernel...', 0x0D, 0x0A, 0
msg_loading_stage3: db 'No config, loading stage 3...', 0x0D, 0x0A, 0
msg_error: db 'Error occurred!', 0x0D, 0x0A, 0

cmd_help: db 'help', 0
cmd_exit: db 'exit', 0

boot_drive: db 0

dap:
    db 0x10  ; Size
    db 0     ; Unused
dap_num_sectors: dw 0
dap_buf_offset: dw 0
dap_buf_segment: dw 0
dap_lba_lower: dd 0
dap_lba_upper: dd 0

start_ticks: dw 0

command_buffer: times 32 db 0
times 4608 - ($ - $$) db 0  ; Fill to 5120 bytes (10 sectors)
; No padding needed, stage 2 can be multiple sectors