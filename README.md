botasm
======

botasm is an IRC bot written in nasm(x86) assembler.

# features
- connect to irc server(non-ssl)
- join a chanel

# building
- nasm -f elf main.asm -o botasm.o
- gcc botasm.o -m32 -o botasm

# todo 
- ping/pong
- error handling
- config parser
- write makefile
- modules(gimme a break)

