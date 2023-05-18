org 0x7C00  ;offsets everything else by this cuz start of program.
bits 16 ;only use 32 and 64 so emit 16 bit

%define ENDL 0x0D, 0x0A

start:
    jmp main

;
; Prints a string to the screen.
; Params:
;   - ds:si points to the string
puts:
    ; save registers we will modify
    push si
    push ax

.loop:
    ; check for next character until reach null character, then jump
    lodsb      ; loads next character in al
    or al, al  ; verify if next character is null, zero flag set if result is zero
    jz .done

    ; Write the character to screen
    mov ah, 0x0e ; call bios interrupt for tty mode in video category
    mov bh, 0
    int 0x10     ; BIOS interrupt for video
    jmp .loop
.done:
   pop ax
   pop si
   ret

main:

    ; setup data segments
    mov ax, 0  ; can't write to ds/es directly
    mov ds, ax ; data segment
    mov es, ax ; extra data segment

    ; setup stack
    mov ss, ax     ; stack segment
    mov sp, 0x7C00 ; stack grows downwards from where we are loaded in memory
    
    ; print message
    mov si, msg_hello
    call puts

    hlt

.halt:
jmp .halt

msg_hello: db 'Hello world!', ENDL, 0

times 510-($-$$) db 0 ;Pad the rest of the boot sector (memory segment 0) with zeros
dw 0AA55h ;create two byte word at end of memory segment as signature for BIOS to recognize
