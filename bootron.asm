.8086
    IS_FLOPPY = 0
BOOT_SEG segment public

    org 7b00h
wins byte ?
     byte ?
pos word ?
    word ?
vel word ?
    word ?
timer byte ?
color byte ?


    org 7c00h
    
    IF IS_FLOPPY
    jmp BootCode ; 2 byte jump
    nop
    byte "MSDOS5.0" ; OEM identifier
    word 512 ;sector size in bytes
    byte 1 ; cluster size in sectors
    word 1 ; reserved sectors
    byte 2 ; number of FAT copies
    word 224 ; number of directory entries
    word 2880 ; total sectors
    byte 0F0h ; media descriptor
    word 9 ; sectors per FAT
    word 18 ; sectors per track
    word 2 ; heads/sides
    dword 0 ; hidden sectors
    dword 0 ; larger total sectors count
    byte 00h ; drive number (drive A)
    byte 00h ; reserved/Windows NT flags
    byte 29h ; signature, must be 28h or 29h
    dword 0 ; serial number
    byte "KRD BOOTER " ; volume label
    byte "FAT12   " ; system identifier
BootCode:
    ENDIF
    
    ;long jump into code so that segment:offset is always consistent
    byte 0eah
    word offset begin,0000h ;offset,segment
;entry point
on_tic proc
    inc timer
    iret
on_tic endp

wait_for_tic proc
    mov timer,0
retry:
    mov ah,1
    int 16h
    jz chain
    mov ah,0
    int 16h
    cmp ah,17
    jne not_w
    mov vel,-80*2
not_w:
    cmp ah,30
    jne not_a
    mov vel,-2
not_a:
    cmp ah,31
    jne not_s
    mov vel,80*2
not_s:
    cmp ah,32
    jne not_d
    mov vel,2
not_d:
    cmp ah,72
    jne not_up
    mov word ptr vel+2,-80*2
not_up:
    cmp ah,75
    jne not_left
    mov word ptr vel+2,-2
not_left:
    cmp ah,77
    jne not_right
    mov word ptr vel+2,2
not_right:
    cmp ah,80
    jne not_down
    mov word ptr vel+2,80*2
not_down:
chain:
    cmp timer,0
    je retry
    ret
wait_for_tic endp

begin proc
    cli
    ;init stack
    mov ax,7000h
    mov ss,ax
    mov ax,0FFFEh
    mov bp,ax
    mov sp,ax
    
    ;set vectors
    mov bx,1Ch*4
    mov word ptr cs:[bx], offset on_tic
    inc bx
    inc bx
    mov word ptr cs:[bx], cs

    mov ax, 0B800h
    mov es,ax
    mov ds,ax
    sti

    mov color,09h
match:
    xor ax,ax
    mov word ptr wins,ax
    
round:
    cmp wins,10
    jge victory
    cmp wins+1,10
    jge victory
    mov pos,(80*12+20)*2
    mov pos+2,(80*12+60)*2
    mov vel,2
    mov vel+2,-2
    
    mov ax,0003h
    int 10h
    
    mov ah,color
    mov al,0DBh
    xor di,di
    mov cx,80
    rep stosw
    mov di, (80*23)*2
    mov cx,80
    rep stosw
    mov bx,(80)*2
    mov es:[bx],ax
    add bx,79*2
    mov es:[bx],ax
    mov si,(80)*2
    mov di,(80*2)*2
    mov cx,21*80
    rep movsw
    
    mov bx,(80*24+2)*2
    mov ax,0E30h
    add al,wins
    mov es:[bx],ax
    mov bx,(80*24+78)*2
    mov ax,0B30h
    add al,wins+1
    mov es:[bx],ax
    

gameloop:
    mov bx,pos
    mov ax,0EDBh
    cmp byte ptr es:[bx], ' '
    je nohitp1
    inc wins+1
    jmp round

nohitp1:
    mov es:[bx],ax
    mov ax,vel
    add pos,ax
    call wait_for_tic

    mov bx,pos+2
    mov ax,0BDBh
    cmp byte ptr es:[bx], ' '
    je nohitp2
    inc wins
    jmp round
nohitp2:
    mov es:[bx],ax
    mov ax,vel+2
    add pos+2,ax
    call wait_for_tic
    
    jmp gameloop
victory:
    mov al,wins
    cmp wins+1,al
    mov color,0Bh
    jg p2win
    add color,3
p2win:
    jmp match
    
    
IF IS_FLOPPY
;boot sector signature
    org 7dfeh
    dw 55aah
ENDIF    


begin endp

BOOT_SEG ends

END