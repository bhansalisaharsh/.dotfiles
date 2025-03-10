#Requires AutoHotkey v2.0

; Define the function outside the block
prevChromeTab()
{
    Send("^+a")
    SetKeyDelay(50)
    Send("{BackSpace}")
    Send("{Enter}")
}

; Set the hotkey
^Tab::
{
    If WinActive("ahk_exe Chrome.exe")
    {
        prevChromeTab()
    }
}
