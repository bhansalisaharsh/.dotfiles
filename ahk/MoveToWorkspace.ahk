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

    Sleep(0.5)  ; Ultra-fast execution (1ms delay)

    ; Restore the extended window style
    WinSetExStyle("^0x80", "ahk_id " . hWnd)

    Sleep(0.5)  ; Minimal delay before reactivating

    ; Re-activate the moved window (forcing focus back)
    if (WinExist("ahk_id " . hWnd)) {
        WinActivate("ahk_id " . hWnd)
        WinWaitActive("ahk_id " . hWnd, , 0.05)  ; Ensure the activation is processed
    }
}
