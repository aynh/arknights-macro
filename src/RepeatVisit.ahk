#Requires AutoHotkey v2.0

#Include Adb.ahk

RepeatVisit() {
  loop 10
    Adb.ClickImage('visit-next', [1120, 605, 130, 55])
}
