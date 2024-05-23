#Requires AutoHotkey v2.0

#Include RepeatStage.ahk
#Include RepeatVisit.ahk

#1:: Do(RepeatStage) ; WIN + 1
#2:: Do(RepeatVisit) ; WIN + 2

Do(function) {
  function()
  MsgBox(function.Name . ' has completed!', A_ScriptName, 0x40 + 0x1000)
}
