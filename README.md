# About

This is the source code for a small project for the class *Computersystemen*
("*Computersystems*") at the Vrije Universiteit Brussel. The project objective
was to write a program in ASM such that it would compile with MASM 6.11 in DOSBox.
The program's function was left up to the student, but every idea first had
to be run by professor Joeri Barbarien.

This particular project had the idea of creating a graphical simulation of balls
(represented as simple circles) bouncing across the screen. The deadline was early
January 2011 and as such **development stopped** after that.

# Setup

The following guideline assumes you have MASM installed and properly
set up, meaning `ml`, `nmake`, `link`, ... are available in the path.

1. Get the source by cloning the git repo into a directory your DOSBox setup can see.
2. Open DOSBox and `cd` into the project directory
3. Compile the project using `nmake all`
4. Run `START.EXE` and follow the instructions on screen.
