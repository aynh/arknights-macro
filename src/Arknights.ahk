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

    try task()
    catch ArknightsError as err
      ArknightsError.Handle(err)
    else
      TrayTip(Format("{} is finished", task.Name), A_ScriptName, 0x1)

    is_running := false
  }
}

A_TrayMenu.Delete() ; clear the default tray
OnMessage(0x404, ShowTrayMenu)
ShowTrayMenu(wParam, lParam, *) {
  ; only handle left/right click event
  if lParam == 0x201 || lParam == 0x204
    SetTimer(() => CustomTrayMenu().Show(), -1) ; show the menu in another thread
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

  static emulator_muted {
    get {
      return Adb.Run('shell media volume --get | findstr /C:"volume is 0"')
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

  static ToggleMute() {
    new_volume := this.emulator_muted ? 15 : 0
    Adb.Run(Format("shell media volume --show --set {}", new_volume))
  }
}

class ArknightsError extends Error {
  static Handle(err) {
    SplitPath(err.File, &filename)
    title := Format("Error @ {}:{}", filename, err.Line)
    MsgBox(err.Message, title, 0x10)
  }
}

class CustomTrayMenu extends Menu {
  __New() {
    this.Add("Arknights", CustomTrayMenu.Arknights())
    this.Add("Script", CustomTrayMenu.Script())
  }

  static Arknights() {
    m := Menu()
    m.Add("Start", (*) => Arknights.Start())
    m.Add("Restart", (*) => Arknights.Start(true))
    m.Add()
    m.Add("Mute", (*) => Arknights.ToggleMute())
    m.Add("Screenshot", (*) => Arknights.Screenshot())
    m.Add()
    m.Add("Close", (*) => Arknights.Close())

    if Arknights.emulator_running {
      m.Disable("Start")
      if Arknights.emulator_muted
        m.Check("Mute")
    } else {
      m.Disable("Restart")
      m.Disable("Mute")
      m.Disable("Screenshot")
      m.Disable("Close")
    }

    return m
  }

  static Script() {
    m := Menu()
    m.Add("Edit", (*) => Run('"C:\Program Files\Microsoft VS Code\Code.exe" ..'))
    m.Add("Reload", (*) => Reload())
    m.Add("Exit", (*) => ExitApp())

    return m
  }
}
