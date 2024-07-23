write-output "building..."
ca65 main.s -o bin\main.o
write-output $compilerOut
write-output "linking..."
ld65 -C lorom.cfg -o bin\test.sfc bin\main.o
.\bin\test.sfc # default program = Mesen