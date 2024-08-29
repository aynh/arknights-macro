#Requires AutoHotkey v2.0
#SingleInstance Force

#Include Adb.ahk
#Include Error.ahk
#Include RecruitTool.ahk
#Include RepeatStage.ahk
#Include RepeatVisit.ahk

#HotIf WinActive(Arknights.AHK_EXE)
#1:: RunTask(RepeatStage, true) ; WIN + 1
#2:: RunTask(RepeatVisit, true) ; WIN + 2
#3:: RunTask(RecruitTool, false) ; WIN + 3
!Space:: ArknightsTray().Show() ; ALT + Space

class RunTask {
  static current := ""

  __New(task, notify_after_done) {
    if RunTask.current != "" {
      MsgBox(Format("The script is currently running {}!", RunTask.current), , 0x10)
      return
    }

    RunTask.current := task.Name

    try {
      task()
      if notify_after_done
        TrayTip(Format("{} is finished", task.Name), A_ScriptName, 0x1)
    } catch ArknightsError as err {
      SplitPath(err.File, &filename)
      title := Format("Error @ {}:{}", filename, err.Line)
      MsgBox(err.Message, title, 0x10)
    }

    RunTask.current := ""
  }
}

A_TrayMenu.Delete() ; clear the default tray
OnMessage(0x404, ShowTrayMenu)
ShowTrayMenu(wParam, lParam, *) {
  ; only handle left/right click event
  if lParam == 0x201 || lParam == 0x204 {
    MouseGetPos(&X, &Y)
    SetTimer(() => ArknightsTray().Show(X, Y), -1) ; show the menu in another thread
  }
}

class Arknights {
  static PACKAGE_NAME := "com.YoStarEN.Arknights"
  static EMULATOR_PATH := "C:\LDPlayer\LDPlayer9\dnplayer.exe"
  static EMULATOR_SERIAL := "127.0.0.1:5555"

  static AHK_EXE {
    get {
      return Format("ahk_exe {}", Arknights.EMULATOR_EXE)
    }
  }

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
        this.CloseEmulator()
      else
        throw ArknightsError(Format("Emulator {} is already open", this.EMULATOR_EXE))
    }

    shell := ComObject("Wscript.Shell")
    shell.Run(Format("{} /C start {}", A_ComSpec, this.EMULATOR_PATH), 0, false)
    WinWait(this.AHK_EXE)
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

  static CloseEmulator() {
    ProcessClose(this.EMULATOR_EXE)
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

  static Mute(yes) {
    Adb.SetVolume(yes ? 0 : 15)
  }
}

class ArknightsTray extends Menu {
  __New() {
    state := RunTask.current != "" ? Format("Running {}", RunTask.current) : "Idle"
    state := Format("State: {}", state)
    this.Add(state, (*) => {})
    this.Disable(state)

    this.Add()
    this.Add("Arknights", ArknightsTray.Arknights())
    this.Add("Script", ArknightsTray.Script())

    this.Add()
    this.Add("Tools", ArknightsTray.Tools())
    if !Arknights.emulator_running
      this.Disable("Tools")
  }

  static Arknights() {
    m := Menu()
    m.Add("Start", (*) => Arknights.Start())
    m.Add("Restart", (*) => Arknights.Start(true))
    m.Add()
    m.Add("Mute", (*) => Arknights.Mute(true))
    m.Add("Unmute", (*) => Arknights.Mute(false))
    m.Add("Screenshot", (*) => Arknights.Screenshot())
    m.Add()
    m.Add("Close", (*) => Arknights.CloseEmulator())

    if Arknights.emulator_running {
      m.Disable("Start")
    } else {
      m.Disable("Restart")
      m.Disable("Mute")
      m.Disable("Unmute")
      m.Disable("Screenshot")
      m.Disable("Close")
    }

    return m
  }

  static Script() {
    m := Menu()

    EditScript(*) {
      ; using code.cmd because directly opening Code.exe here sometimes doesn't work
      static VSCODE_BIN := "C:\Program Files\Microsoft VS Code\bin\code.cmd"

      shell := ComObject("Wscript.Shell")
      ; and also Wscript.Shell.Run instead of plain Run to hide the cmd window
      shell.Run(Format('"{}" ..', VSCODE_BIN), 0, true)
    }
    m.Add("Edit", EditScript)
    m.Add("Reload", (*) => Reload())
    m.Add("Exit", (*) => ExitApp())


    return m
  }

  static Tools() {
    m := Menu()
    m.Add("Repeat-Stage", (*) => RunTask(RepeatStage, true))
    m.Add("Repeat-Visit", (*) => RunTask(RepeatVisit, true))
    m.Add("Recruit-Tool", (*) => RunTask(RecruitTool, false))

    return m
  }
}
