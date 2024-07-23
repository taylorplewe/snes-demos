$gamename = "snes_scrolling"
write-output "building..."
ca65 src\main.s -o bin\main.o
write-output "linking..."
ld65 -C lorom.cfg -o "bin\$gamename.sfc" bin\main.o
mesen ".\bin\$gamename.sfc"