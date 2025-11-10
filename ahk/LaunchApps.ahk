#Requires AutoHotkey v2.0

; --- Launch Windows Terminal with Win + T (AHK v2.0) ---
#t::  ; '#' means the Windows key
{
    ; Try to run Windows Terminal using its app ID
    try
        Run("wt.exe")  ; Works if wt.exe is in PATH
    catch
        MsgBox("Couldn't launch Windows Terminal. Make sure it's installed.")
}
