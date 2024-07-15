#Requires AutoHotkey v2.0
#SingleInstance Force

#Include Adb.ahk
#Include RecruitTool.ahk
#Include RepeatStage.ahk
#Include RepeatVisit.ahk

#HotIf WinExist('LDPlayer ahk_exe dnplayer.exe')
#1:: Do(RepeatStage) ; WIN + 1
#2:: Do(RepeatVisit) ; WIN + 2
#3:: Do(RecruitTool) ; WIN + 3
#Escape:: Reload() ; WIN + Esc
#`:: ScreenshotArknights()

StartArknights() {
  static ARKNIGHTS_PACKAGE_NAME := "com.YoStarEN.Arknights"
  static EMULATOR_PATH := "C:\LDPlayer\LDPlayer9\dnplayer.exe"
  static EMULATOR_SERIAL := "127.0.0.1:5555"

  SplitPath(EMULATOR_PATH, &emulator_exe)
  if ProcessExist(emulator_exe) {
    MsgBox(Format("Emulator {} is already open", emulator_exe), , 0x10)
    return
  }

  shell := ComObject("Wscript.Shell")
  shell.Run(Format("{} /C start {}", A_ComSpec, EMULATOR_PATH), 0, false)
  WinWait(Format("ahk_exe {}", emulator_exe))
  WinMinimize()

  Adb.Setup(EMULATOR_SERIAL)
  while not Adb.Run(
    ; sometimes it doesn't actually launch the game so
    Format(
      ; check if arknights is currently open
      'shell dumpsys window windows | findstr "mCurrentFocus" | findstr "{}"', ARKNIGHTS_PACKAGE_NAME
    )
  )
    Adb.Run(Format("shell monkey -p {} 1", ARKNIGHTS_PACKAGE_NAME))

  Adb.OCR_Click([615, 655, 50, 50], "START", 2.5)
  Adb.OCR_Click([595, 495, 85, 25], "START", 2.5)

  if (
    WinGetMinMax() == -1 ; if window is minimized
    && MsgBox("Arknights has started, show the window?", , 0x4 + 0x40) == "Yes"
  )
    WinActivate()
}

ScreenshotArknights() {
  buf := Adb.Screenshot()

  Run(Adb.TMP_IMAGE_PATH, , , &pid)
  WinWait("ahk_pid " pid)
  region_prompt := InputBox("region (comma separated)", , "w150 h90", A_Clipboard)
  WinClose()

  if region_prompt.Result != "OK"
    return
  else if region := region_prompt.Value {
    A_Clipboard := region_prompt.Value
    buf := ImagePutBuffer({
      buffer: buf, crop: StrSplit(StrReplace(region, " ", ""), ",")
    })
  }

  ImagePutFile(buf, Adb.TMP_IMAGE_PATH)
  Run(Adb.TMP_IMAGE_PATH, , , &pid)
  WinWait("ahk_pid " pid)

  text := OCR.FromBitmap(ImagePutHBitmap(buf)).Text
  if (
    text != ""
      ? MsgBox(text . "`n`nSave the image?", "OCR text", 0x4) == "Yes"
      : MsgBox("Save the image?", , 0x4) == "Yes"
  )
    FileMove(Adb.TMP_IMAGE_PATH, FileSelect("S " 8 + 16, "../assets/images/image.png"))

  WinClose()
}

Do(task) {
  static is_running := false
  if !is_running {
    is_running := true
    task()
    TrayTip(Format("{} is finished", task.Name), A_ScriptName, 0x1)
    is_running := false
  }
}

tray := A_TrayMenu
tray.Delete()
tray.Add("Start Arknights", (*) => StartArknights())
tray.Add("Screenshot Arknights", (*) => ScreenshotArknights())
tray.Add("Exit", (*) => ExitApp())
