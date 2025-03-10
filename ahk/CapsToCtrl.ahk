#Requires AutoHotkey v2.0

SetCapsLockState "AlwaysOff"  ; Ensure Caps Lock never gets turned on

CapsLock::Ctrl  ; Remap Caps Lock to CtrlS
!+CapsLock::CapsLock  ; Alt + Shift + CapsLock restores normal Caps Lock function

; Optional: Ensure Ctrl doesn't get stuck
CapsLock Up::Send "{Ctrl Up}"
