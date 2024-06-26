#Requires AutoHotkey v2.0

#Include Helper.ahk

RepeatVisit() {
  idx := 1
  while idx < 10 {
    Sleep(2000)
    if ClickImage('visit-next', [1160, 620, 1360, 720])
      idx += 1
  }
}
