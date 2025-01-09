if ($args.count -gt 0) { set-location $args[0] }
$gamename = split-path -leaf $pwd

write-output "assembling..."
ca65 main.s -o bin\main.o
if ($LASTEXITCODE -ne 0) { set-location -; return }

write-output "linking..."
ld65 -C ..\lorom.cfg -o "bin\$gamename.sfc" bin\main.o
if ($LASTEXITCODE -ne 0) { set-location -; return }

& "bin\$gamename.sfc" # default program = Mesen

if ($args.count -gt 0) { set-location - }