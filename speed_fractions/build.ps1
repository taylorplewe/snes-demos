$gamename = "snes_speed_fractions"
write-output "building..."
ca65 main.s -o bin\main.o
write-output "linking..."
ld65 -C lorom.cfg -o "bin\$gamename.sfc" bin\main.o
& ".\bin\$gamename.sfc" # default program = Mesen