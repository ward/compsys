objects = MAIN.OBJ PRINT.OBJ STOI.OBJ BALL.OBJ

all: START.EXE

START.EXE: $(objects)
	ml $(objects) /Fe START.EXE
# make knows how to compile these
MAIN.OBJ: MAIN.ASM
PRINT.OBJ: PRINT.ASM
STOI.OBJ: STOI.ASM
BALL.OBJ: BALL.ASM
clean:
	del *.OBJ
	del *.EXE
