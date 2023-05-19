org 0x7C00  ;offsets everything else by this cuz start of program.
bits 16 ;only use 32 and 64 so emit 16 bit

%define ENDL 0x0D, 0x0A

;
;  FAT12 Header
;
jmp short start
nop

bdb_oem:                       db 'MSWIN4.1'         ; 8 bytes
bdb_bytes_per_sector:          dw 512
bdb_sectors_per_cluster:       db 1
bdb_reserved_sectors:          dw 1
bdb_fat_count:                 db 2
bdb_dir_entries_count:         dw 0E0h
bdb_total_sectors:             dw 2880
bdb_media_descriptor_type:     db 0F0h
bdb_sectors_per_fat:           dw 9
bdb_sectors_per_track:         dw 18
bdb_heads:                     dw 2
bdb_hidden_sectors:            dd 0
bdb_large_sector_count:        dd 0

; extended boot record
ebr_drive_number:              db 0
                               db 0 ; reserved
ebr_signature:                 db 29h
ebr_volume_id:                 db 12h, 34h, 56h, 78h
ebr_volume_label:              db 'MY OS      ' ; 11 bytes padded with spaces
ebr_system_id:                 db 'FAT12   ' ; 8 bytes padded with spaces

;
; Code goes here
;

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

;
; Disk routines
;


;
; Converts an LBA address to a CHS address
; Parameters:
;  - ax: LBA address
; Returns:
;  - cx [bits 0-5]: sector number
;  - cx [bits 6-15]: cylinder
;  - dh: head

lba_to_chs:

    xor dx, dx                          ; dx = 0
    div word [bdb_sectors_per_track]    ; ax = LBA / SectorsPerTrack
                                        ; dx = LBA % SectorsPerTrack

    inc dx                              ; dx = (LBA % SectorsPerTrack + 1) = sector
    mov cx, dx                          ; cx = sector

    xor dx, dx                          ; dx = 0
    div word [bdb_heads]                ; ax = (LBA / SectorsPerTrack) / Heads = cylinder
                                        ; dx = (LBA / SectorPerTrack) % Heads = head

    mov dh, dl                          ; dh = head
    mov ch, al                          ; ch = cylinder (lower 8 bits)
    shl ah, 6
    or cl, ah                           ; put upper 2 bits of cylinder in CL

    pop ax
    mov dl, al                          ; restore DL
    pop ax
    ret


;
; Reads sectors from a disk
; Parameters:
;  - ax: LBA address
;  - cl: number of sectors to read (up to 128)
;  - dl: drive number
;  - es:bx: memory address where to store read data
disk_read:
    


msg_hello: db 'Hello world!', ENDL, 0

times 510-($-$$) db 0 ;Pad the rest of the boot sector (memory segment 0) with zeros
dw 0AA55h ;create two byte word at end of memory segment as signature for BIOS to recognize
