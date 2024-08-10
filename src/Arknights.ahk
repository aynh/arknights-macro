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
#Escape:: { ; WIN + Esc
  if MsgBox("Reload the script?", , 0x4) == "Yes"
    Reload()
}
#`:: Arknights.Screenshot()

Do(task) {
  static is_running := false
  if !is_running {
    is_running := true
    task()
    TrayTip(Format("{} is finished", task.Name), A_ScriptName, 0x1)
    is_running := false
  }
}

A_TrayMenu.Delete() ; clear the default tray
OnMessage(0x404, ShowTrayMenu)
ShowTrayMenu(wParam, lParam, *) {
  ; only handle left/right click event
  if lParam != 0x201 && lParam != 0x204
    return

  arknights_menu := Menu()
  arknights_menu.Add("Start", (*) => Arknights.Start())
  arknights_menu.Add("Restart", (*) => Arknights.Start(true))
  arknights_menu.Add()
  arknights_menu.Add("Screenshot", (*) => Arknights.Screenshot())
  arknights_menu.Add()
  arknights_menu.Add("Close", (*) => Arknights.Close())

  if Arknights.emulator_running {
    arknights_menu.Disable("Start")
  } else {
    arknights_menu.Disable("Restart")
    arknights_menu.Disable("Screenshot")
    arknights_menu.Disable("Close")
  }

  script_menu := Menu()
  script_menu.Add("Reload", (*) => Reload())
  script_menu.Add("Exit", (*) => ExitApp())

  tray := Menu()
  tray.Add("Arknights", arknights_menu)
  tray.Add("Script", script_menu)
  SetTimer(() => tray.Show(), -1)
}

class Arknights {
  static PACKAGE_NAME := "com.YoStarEN.Arknights"
  static EMULATOR_PATH := "C:\LDPlayer\LDPlayer9\dnplayer.exe"
  static EMULATOR_SERIAL := "127.0.0.1:5555"

  static EMULATOR_EXE {
    get {
      SplitPath(this.EMULATOR_PATH, &out)
      return out
    }
  }

  static emulator_running {
    get {
      return ProcessExist(this.EMULATOR_EXE)
    }
  }

  static Start(close_existing := false) {
    if this.emulator_running {
      if close_existing
        ProcessClose(this.EMULATOR_EXE)
      else
        throw ArknightsError(Format("Emulator {} is already open", this.EMULATOR_EXE))
    }

    shell := ComObject("Wscript.Shell")
    shell.Run(Format("{} /C start {}", A_ComSpec, this.EMULATOR_PATH), 0, false)
    WinWait(Format("ahk_exe {}", this.EMULATOR_EXE))
    WinMinimize()

    Adb.Setup(this.EMULATOR_SERIAL)
    while not Adb.Run(
      ; sometimes it doesn't actually launch the game so
      Format(
        ; check if arknights is currently open
        'shell dumpsys window windows | findstr "mCurrentFocus" | findstr "{}"', this.PACKAGE_NAME
      )
    )
      Adb.Run(Format("shell monkey -p {} 1", this.PACKAGE_NAME))

    Adb.OCR_Click([615, 655, 50, 50], "START", 2.5)
    Adb.OCR_Click([595, 495, 85, 25], "START", 2.5)

    if (
      WinGetMinMax() == -1 ; if window is minimized
      && MsgBox("Arknights has started, show the window?", , 0x4 + 0x40) == "Yes"
    )
      WinActivate()
  }

  static Close() {
    if ProcessClose(this.EMULATOR_EXE)
      MsgBox("Arknights has been closed", , 0x20)
  }

  static Screenshot() {
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
}

OnError(HandleArknightsError)
class ArknightsError extends Error {
}
HandleArknightsError(err, mode) {
  if !(err is ArknightsError)
    return

  SplitPath(err.File, &filename)
  MsgBox(err.Message, Format("Error @ {}:{}", filename, err.Line), 0x10)
  return -1
}
