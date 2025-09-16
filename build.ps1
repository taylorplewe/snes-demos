$initialDir = $pwd

if ($args.count -gt 0) { set-location $args[0] }
$gamename = split-path -leaf $pwd

write-output "assembling..."
ca65 main.s -o bin\main.o -g
if ($LASTEXITCODE -ne 0) { set-location $initialDir; return }

write-output "linking..."
ld65 -C ..\lorom.cfg -o "bin\$gamename.sfc" bin\main.o --dbgfile "bin\$gamename.dbg"
if ($LASTEXITCODE -ne 0) { set-location $initialDir; return }

# & "bin\$gamename.sfc" # default program = Mesen

if ($args.count -gt 0) { set-location $initialDir }
