#Requires AutoHotkey v2.0
; --- Close Active App with Win + Q (AHK v2.0) ---
#q::  ; '#' means the Windows key
{
    ; Get the active window
    hwnd := WinGetID("A")

    ; Send a close message to the active window
    WinClose(hwnd)

    ; Optional: force close if not responding (uncomment below if needed)
    ; if WinExist("ahk_id " hwnd)
    ;     ProcessClose(WinGetPID("ahk_id " hwnd))
}

