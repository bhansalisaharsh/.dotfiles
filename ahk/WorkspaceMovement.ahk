#Requires AutoHotkey v2.0+

; WIN + ALT + LEFT/RIGHT to move window to left/right monitor
#!Left::MoveWindowToMonitor("Left")
#!Right::MoveWindowToMonitor("Right")

MoveWindowToMonitor(direction) {
    hWnd := WinExist("A")  ; Get the unique ID of the active window

    if !hWnd
        return

    ; Remove the "topmost" extended window style to allow movement
    WinSetExStyle("^0x80", "ahk_id " . hWnd)

    ; Move the window left or right between monitors
    if (direction = "Left") {
        Send("{LWin down}{Ctrl down}{Left}{Ctrl up}{LWin up}")
    } else if (direction = "Right") {
        Send("{LWin down}{Ctrl down}{Right}{Ctrl up}{LWin up}")
    }

    Sleep(3)  ; Reduced sleep time to 3ms for ultra-fast execution

    ; Restore the extended window style
    WinSetExStyle("^0x80", "ahk_id " . hWnd)
    
    ; Sleep(2)  ; Quick delay to ensure stability

    ; Re-activate the moved window
    WinActivate("ahk_id " . hWnd)
}
