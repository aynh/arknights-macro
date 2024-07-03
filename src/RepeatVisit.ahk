#Requires AutoHotkey v2.0

#Include Adb.ahk

RepeatVisit() {
  idx := 1
  while idx < 10 {
    Sleep(2000)
    if Adb.ClickImage('visit-next', [1090, 580, 185, 100])
      idx += 1
  }
}
