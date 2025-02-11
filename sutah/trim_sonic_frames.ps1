set-location bin/sonic_frames
get-childitem | foreach-object { trim-file $_.Name 0x300 }
set-location -