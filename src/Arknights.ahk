#Requires AutoHotkey v2.0
#SingleInstance Force

#Include Adb.ahk
#Include RecruitTool.ahk
#Include RepeatStage.ahk
#Include RepeatVisit.ahk

#HotIf WinExist('LDPlayer ahk_exe dnplayer.exe')
#1:: Do(RepeatStage) ; WIN + 1
<+#1:: Do(RepeatAnnihilation) ; LSHIFT + WIN + 1
#2:: Do(RepeatVisit) ; WIN + 2
#3:: Do(RecruitTool) ; WIN + 3
#Escape:: Reload() ; WIN + Esc

Do(task) {
  static is_running := false
  if !is_running {
    is_running := true
    task()
    TrayTip(Format("{} is finished", task.Name), A_ScriptName, 0x1 + 0x10)
    is_running := false
  }
}

#`:: {
  Adb.Screenshot()
  Run(A_Temp "/screenshot.png")
}
