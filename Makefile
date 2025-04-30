all: rombat.rom

rombat.o: rombat.s
	asz80 -l rombat.lst rombat.s 
 
rombat:	rombat.o
	ldz80 -b -C 0 rombat.o -o rombat

rombat.rom: rombat
	dd if=rombat of=rombat.rom bs=8192 conv=sync

clean:
	rm -f rombat rombat.rom rombat.o rombat.lst

