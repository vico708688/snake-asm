main: main.o
	@ld -I/lib64/ld-linux-x86-64.so.2 -lc -entry main -o main main.o

main.o: main.asm
	@nasm -g -f elf64 -o main.o main.asm

.PHONY : clean

clean:
	@rm main.o main