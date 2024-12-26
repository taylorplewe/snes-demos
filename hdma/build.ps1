$gamename = "hdma"

write-output "assembling..."
ca65 main.s -o bin\main.o
if ($LASTEXITCODE -ne 0) { return }

write-output "linking..."
ld65 -C lorom.cfg -o "bin\$gamename.sfc" bin\main.o
if ($LASTEXITCODE -ne 0) { return }

& ".\bin\$gamename.sfc" # default program = Mesen