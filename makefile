CC = gcc

# link avec libc
main: main.o
# link against libc for tcgetattr and tcsetattr
	@$(CC) -no-pie -o main main.o

# génération automatique des offsets
termios.inc: get_size
	@./get_size > termios.inc

get_size: get_size.c
	@$(CC) get_size.c -o get_size

# assemblage dépend de termios.inc
main.o: main.asm termios.inc
	@nasm -g -f elf64 -o main.o main.asm

.PHONY : clean

clean:
	@rm main termios.inc get_size