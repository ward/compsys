PRINT.EXE: lf.obj mylib.a
	ML MAIN.OBJ LF.OBJ /Fe PRINT.EXE
lf.obj: lf.asm
	ML /c lf.asm
main.obj: main.asm
	ML /c main.asm
clean:
	del *.OBJ
	del *.EXE
