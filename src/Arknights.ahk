#Requires AutoHotkey v2.0
#SingleInstance Force

#Include AutoRecruit.ahk
#Include RepeatStage.ahk
#Include RepeatVisit.ahk

#HotIf WinActive('Arknights ahk_class CROSVM_1')
#1:: Do(RepeatStage) ; WIN + 1
<+#1:: Do(RepeatAnnihilation) ; LSHIFT + WIN + 1
#2:: Do(RepeatVisit) ; WIN + 2
#3:: Do(AutoRecruit) ; WIN + 3
#Escape:: Reload() ; WIN + Esc

Do(function) {
  function()
  MsgBox(function.Name . ' has completed!', A_ScriptName, 0x40 + 0x1000)
}
