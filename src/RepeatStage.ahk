#Requires AutoHotkey v2.0

#Include Adb.ahk

RepeatStage() {
  gui := RepeatStageGui()
  gui.Show()
  WinWaitClose(gui.Hwnd)
}

class RepeatStageGui extends Gui {
  __New() {
    super.__New("AlwaysOnTop -MinimizeBox", "RepeatStage")

    this.AddText(, "stage type")
    this.AddDropDownList("vstage_type Choose2 w80", ["annihilation", "normal"])

    this.AddText(, "count")
    this.AddEdit("vloop_count Number w48", "1")
    this.AddCheckbox("vloop_auto yp x+12 hp", "auto")
    this.AddCheckbox("vuse_potion Checked xm y+8", "use sanity potions")

    this.AddButton("vstart_button xm-2 y+12", "start")

    StageTypeOnChange(*) {
      switch this["stage_type"].Text {
        case "annihilation":
          this["loop_count"].Enabled := this["loop_auto"].Enabled := false
        case "normal":
          this["loop_count"].Enabled := this["loop_auto"].Enabled := true
      }
    }
    this["stage_type"].OnEvent("Change", StageTypeOnChange)

    this["loop_auto"].OnEvent("Click", (*) => this["loop_count"].Enabled := !this["loop_auto"].Value)

    StartButtonOnClick(*) {
      options := this.Submit()
      switch options.stage_type {
        case "annihilation":
          LoopStageAuto("annihilation", options.use_potion)
        case "normal":
          if options.loop_auto
            LoopStageAuto("normal", options.use_potion)
          else
            LoopStage(Number(options.loop_count), "normal", options.use_potion)
      }
    }
    this["start_button"].OnEvent("Click", StartButtonOnClick)
  }
}

LoopStageAuto(kind, use_sanity_potions) {
  static ANNIHILATION_WEEKLY_ORUNDUM_REGION := [100, 635, 200, 45]
  static ANNIHILATION_WEEKLY_ORUNDUM_CAP := 1800
  static START_STAGE_XY := [1140, 660]

  switch kind {
    case "annihilation":
      stage_cost := 25
    case "normal":
      ChangeStageMultiplier(6)
      stage_cost := GetStageCost() / 6
  }

  loop {
    if kind == "annihilation" {
annihilation_orundum:
      loop {
        ; the region also includes the loading screen' tips text
        ; so keep looping until it found a number
        weekly_orundum := Adb.OCR_NonEmpty(ANNIHILATION_WEEKLY_ORUNDUM_REGION)
        weekly_orundum := Trim(StrSplit(weekly_orundum, "/")[1])
        if weekly_orundum == "O"
          ; the OCR read 0 (zero) as O (letter O)
          weekly_orundum := 0

        if IsNumber(weekly_orundum) {
          weekly_orundum := Number(weekly_orundum)
          break annihilation_orundum
        }
      }

      if weekly_orundum == ANNIHILATION_WEEKLY_ORUNDUM_CAP
        break
    }

    sanity := GetCurrentSanity()
    if sanity < stage_cost {
      if !use_sanity_potions
        break

      ChangeStageMultiplier(1)
      Adb.Click(START_STAGE_XY*)
      if !TryRestoreSanity("potion")
        break

      continue
    }

    switch kind {
      case "annihilation":
        DoStage("annihilation", false)
      case "normal":
        DoStageNormalAuto(sanity, stage_cost)
    }
  }
}

DoStageNormalAuto(sanity, stage_cost) {
  multiplier := Min(Floor(sanity / stage_cost), 6)
  if multiplier > 0 {
    ChangeStageMultiplier(multiplier)
    DoStage("normal", false)
  }
}

GetCurrentSanity() {
  static SANITY_REGION := [1130, 20, 110, 40]

  sanity_and_max_sanity := Adb.OCR_NonEmpty(SANITY_REGION, 2.5)
  sanity := StrSplit(sanity_and_max_sanity, "/")[1]
  return Number(sanity)
}

GetStageCost() {
  static STAGE_COST_REGION := [1185, 690, 45, 25]

  stage_cost := Adb.OCR_NonEmpty(STAGE_COST_REGION, 2.5)
  return -Number(stage_cost)
}

ChangeStageMultiplier(value) {
  static STAGE_MULTIPLIER_XY := [1020, 605]
  static SELECT_STAGE_MULTIPLIER_XY := [
    [1000, 535], [1000, 470], [1000, 415], [1000, 350], [1000, 285], [1000, 225]
  ]

  Adb.Click(STAGE_MULTIPLIER_XY*)
  Sleep(500) ; wait for the selection menu to show up
  Adb.Click(SELECT_STAGE_MULTIPLIER_XY[value]*)
}

LoopStage(count, kind, use_sanity_potion) {
  loop count {
    if !DoStage(kind, use_sanity_potion)
      return
  }
}

DoStage(kind, use_sanity_potion) {
  switch kind {
    case "annihilation":
      Start1 := () => Adb.OCR_Click([1150, 640, 90, 35], "Start")
      Start2 := () => Adb.OCR_TryClick([1095, 645, 90, 35], "Confirm")
    case "normal":
      Start1 := () => Adb.OCR_Click([1150, 655, 90, 35], "Start")
      Start2 := () => Adb.OCR_TryClick([1055, 520, 95, 40], "START")
    default:
      return
  }

  Start1()
  Sleep(2000) ; wait for the menu to change
  if Start2() {
    WaitUntilOperationComplete()
    return true
  }

  if !use_sanity_potion
    Adb.PressBack()
  else if TryRestoreSanity("potion")
    return DoStage(kind, use_sanity_potion)

  return false
}

WaitUntilOperationComplete() {
  static OPERATION_COMPLETE_REGION := [60, 175, 220, 90]

  Adb.OCR_WaitUntilMatch(OPERATION_COMPLETE_REGION, "OPERATION COMPLETE")
  Sleep(3000) ; wait for the dialogue to finish
  Adb.PressBack()
}

; restore sanity with (potion|originite prime)
; return false if there is no 'with' to use
; otherwise return true
TryRestoreSanity(with) {
  static CONFIRM_RESTORE_BUTTON_XY := [1090, 575]

  if view := CheckRestoreSanityMenu() {
    if view != with {
      Adb.PressBack()
      return false
    }

    Adb.Click(CONFIRM_RESTORE_BUTTON_XY*)
  }

  return true
}

; check if we're currently viewing restore sanity menu
; return either 'potion' or 'originite prime' depending on which menu is showed
; otherwise return false if neither is showed
CheckRestoreSanityMenu() {
  static RESTORE_POTION_REGION := [695, 80, 205, 45]
  static RESTORE_ORIGINITE_PRIME_REGION := [1005, 80, 250, 45]

  switch {
    case Adb.ImageSearch(RESTORE_POTION_REGION, "restore-potion"):
      return "potion"
    case Adb.ImageSearch(RESTORE_ORIGINITE_PRIME_REGION, "restore-originite-prime"):
      return "originite prime"
    default:
      return false
  }
}
