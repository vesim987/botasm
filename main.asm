section .text
    global main
main:
    mov ebp, esp
        
    call irc_connect
    ;TODO: handle errors
    
    mov eax, 1
    push irc_msg_pass
    call irc_send_msg
    add esp, 4
    
    mov eax, 2
    push nick
    push irc_msg_nick
    call irc_send_msg
    add esp, 8
    
    mov eax, 4
    push real_name
    push irc_msg_user_2
    push user
    push irc_msg_user_1
    call irc_send_msg
    add esp, 16
    
    
    ;TODO: send it after RPL_WELCOME
    mov eax, 2
    push channel
    push irc_msg_join
    call irc_send_msg
    add esp, 8
    
    
  main_loop:
    mov eax, dword [irc_socket]
    mov ebx, irc_msg
    mov ecx, 4096
    call socket_recv
    cmp eax, 0
    jle end
    ;TODO: handle errors
    
    mov ebx, eax
    mov eax, 4
    mov ebx, 1
    mov ecx, irc_msg
    ;mov ebx, eax
    ;int 0x80
    
    jmp main_loop    
  end:
    xor eax, eax
    ret
    
;UTILS

;string
strlen:
    ;push ebp
    ;mov ebp, esp
    
    xor ecx, ecx
   
  strlen_loop:
    inc ecx
    cmp byte [ecx+eax], 0
    jne strlen_loop
    mov eax, ecx
    
    ;mov esp, ebp
    ;pop ebp
    ret
    
;str1, str2
strstr:
    push ebp
    mov ebp, esp
    sub esp, 4
    
  strstr_loop1:
    mov esi, eax
    mov [esp-4], esi
    mov edi, ebx
  strstr_loop2:
    cmp byte [esi], 0
    je strstr_eloop2
    cmp byte [edi], 0
    je strstr_eloop2
    
    mov cx, [esi]
    mov dx, [edi]
    inc esi
    inc edi
    cmp cx, dx
    je strstr_loop2
  strstr_eloop2:
   
    cmp byte [edi], 0
    jne strstr_loop1_continue
    mov eax, [esp-4]
    jmp strstr_end
    
  strstr_loop1_continue:
    inc eax
    cmp byte [eax], 0
    jnz strstr_loop1
    
    xor eax, eax    
  strstr_end:
    mov esp, ebp
    pop ebp
    ret
    
;str, character<bl>
strchr:
    push ebp
    mov ebp, esp
    
  strchr_loop:
    inc eax
    cmp byte[eax], bl
    je strchr_end
    cmp byte [eax], 0
    jne strchr_loop
    
    xor eax, eax
  strchr_end:
    mov esp, ebp
    pop ebp
    ret

;dst, src, length
memcpy:
    push ebp
    mov ebp, esp
    
    mov esi, eax
    
  memcpy_loop:
    mov dl, [ebx]
    mov byte [eax], dl
    inc eax
    inc ebx
    dec ecx
    jnz memcpy_loop
    
    mov eax, esi
    mov esp, ebp
    pop ebp
    ret


;IRC
irc_connect:
    push ebp
    mov ebp, esp
    
    call socket_create
    cmp eax, 0
    jle irc_connect_socket_error
    
    mov [irc_socket], eax
    mov ebx, dword [freenode_ip] ;ip
    mov cx, word [freenode_port] ;port
    call socket_connect
    cmp eax, 0
    jle irc_connect_socket_connect_error
    
    mov eax, 0
    jmp irc_connect_end
  irc_connect_socket_error:
    
    mov eax, 1
    jmp irc_connect_end
  irc_connect_socket_connect_error:
    mov eax, 2
  irc_connect_end:
    mov esp, ebp
    pop ebp
    ret
    
;<eax>num_args, <stack>args...
irc_send_msg:
    push ebp
    mov ebp, esp
    sub esp, 8
    
    mov dword [ebp - 4], eax
    mov dword [ebp - 8], ebp
    add dword [ebp - 8], 8
    
  irc_send_msg_loop:
    
    mov eax, dword [ebp - 8]
    mov eax, [eax]
    call strlen
    ;send part of message
    mov ecx, eax
    mov eax, [irc_socket]
    mov ebx, dword [ebp - 8]
    mov ebx, [ebx]
    call socket_send

    add dword [ebp - 8], 4
    dec dword [ebp - 4]
    jnz irc_send_msg_loop
    
    ;send \r\n
    mov eax, [irc_socket]
    mov ebx, irc_msg_cr_lf
    mov ecx, 2
    call socket_send
    
    mov eax, 1
    
    mov esp, ebp
    pop ebp
    ret
    
irc_recv:
    push ebp
    mov ebp, esp
    ;TODO: implement irc_recv
    mov esp, ebp
    pop ebp
    ret
    
;SOCKETS
socket_create:
    push ebp
    mov ebp, esp
    sub esp, 12
    
    mov dword [ebp-12], 2   ;AF_INET
    mov dword [ebp-8], 1    ;SOCK_STREAM
    mov dword [ebp-4], 0
    
    mov eax, 102      ;socketcall
    mov ebx, 1        ;socket
    lea ecx, [ebp-12] ;parameters
    int 0x80
    
    ;add esp, 12
    mov esp, ebp
    pop ebp
    ret
    
;socket, ip, port
socket_connect:
    push ebp
    mov ebp, esp
    sub esp, 28
   
    ;sockaddr
    mov word [ebp-28], 2     ;sin_family
    mov word [ebp-26], cx    ;sin_port
    mov dword [ebp-24], ebx  ;sin_addr.s_addr
    mov dword [ebp-20], 0    ;sin_zero
    mov dword [ebp-16], 0    ;sin_zero
    
    ;paramters
    mov dword [ebp-12], eax  ;socket
    lea eax, [ebp-28]
    mov dword [ebp-8], eax   ;sockaddr
    mov dword [ebp-4], 16    ;addrlen
    
    mov eax, 102      ;socketcall
    mov ebx, 3        ;connect
    lea ecx, [ebp-12] ;parameters
    int 0x80
    
    ;add esp, 28
    mov esp, ebp
    pop ebp
    ret

;socket, buffer, size    
socket_send:
    push ebp
    mov ebp, esp
    sub esp, 16
    
    ;paramters
    mov dword [ebp-16], eax  ;socket
    mov dword [ebp-12], ebx  ;buffer 
    mov dword [ebp-8], ecx   ;size
    mov dword [ebp-4], 0     ;flags
        
    mov eax, 102      ;socketcall
    mov ebx, 9        ;send
    lea ecx, [ebp-16] ;parameters
    int 0x80
    ;mov eax, [ebp-16]
    
    ;add esp, 16
    mov esp, ebp
    pop ebp
    ret
    
;socket, buffer, size    
socket_recv:
    push ebp
    mov ebp, esp
    sub esp, 16
    
    ;paramters
    mov dword [ebp-16], eax  ;socket
    mov dword [ebp-12], ebx  ;buffer 
    mov dword [ebp-8], ecx   ;size
    mov dword [ebp-4], 0     ;flags
        
    mov eax, 102      ;socketcall
    mov ebx, 10       ;recv
    lea ecx, [ebp-16] ;parameters
    int 0x80
    
    ;add esp, 16
    mov esp, ebp
    pop ebp
    ret

;socket
socket_close:
    push ebp
    mov ebp, esp
   
    mov ebx, eax      ;socket
    mov eax, 6        ;close
    int 0x80
    
    mov esp, ebp
    pop ebp
    ret
    
section .bss
    irc_msg resb 4096
    irc_msg_line resb 512
    irc_msg_to_send resb 512
    irc_socket resb 4
    
section .data
    irc_msg_pass db "PASS *", 0 
    irc_msg_nick db "NICK ", 0
    irc_msg_user_1 db "USER ", 0
    irc_msg_user_2 db " 8 * :", 0
    irc_msg_join db "JOIN #", 0
    irc_msg_cr_lf db 13, 10, 0
    irc_msg_privmsg_channel_1 db "PRIVMSG #", 0
    irc_msg_privmsg_channel_2 db " :", 0
    irc_msg_quit db "QUIT :Its something", 13, 10, 0

    freenode_ip dd 0x3180DBC1
    freenode_port dw 0x0B1A
    nick db "asmbot", 0
    user db "vesim", 0
    real_name db "vesim", 0
    channel db "vesbottest", 0
   