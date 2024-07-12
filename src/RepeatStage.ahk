#Requires AutoHotkey v2.0

#Include Adb.ahk

RepeatAnnihilation() {
  LoopStage(5, "annihilation")
}

RepeatStage() {
  prompt := InputBox(, "RepeatStage", "w150 h75")
  if prompt.Result != "OK"
    return

  if prompt.Value == ""
    LoopStageAuto()
  else if IsNumber(prompt.Value)
    LoopStage(Number(prompt.Value), "normal")
}

LoopStageAuto() {
  static START_STAGE_XY := [1140, 660]

  ChangeStageMultiplier(2)
  stage_cost := GetStageCost() / 2

  loop {
    sanity := GetCurrentSanity()
    if sanity < stage_cost {
      Adb.Click(START_STAGE_XY*)
      if !TryRestoreSanity("potion")
        break

      continue
    }

    DoStageAuto(sanity, stage_cost)
  }
}

DoStageAuto(sanity, stage_cost) {
  loop 6 {
    ; loop through 6 to 1 to get maximum sanity spent
    multiplier := 7 - A_Index
    if (multiplier * stage_cost) <= sanity {
      ChangeStageMultiplier(multiplier)
      DoStage("normal")
      return
    }
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

LoopStage(count, kind) {
  loop count {
    if !DoStage(kind)
      return
  }
}

DoStage(kind) {
  switch kind {
    case "annihilation":
      Start1 := () => Adb.ClickImage(['start-annihilation-1'], [1040, 640, 200, 40])
      Start2 := () => Adb.TryClickImage(['start-annihilation-2'], [1040, 640, 200, 40])
    case "normal":
      Start1 := () => Adb.ClickImage(["start-1a", "start-1b", "start-1c"], [1040, 640, 200, 40])
      Start2 := () => Adb.TryClickImage(["start-2a", "start-2b"], [1035, 370, 135, 280])
    default:
      return
  }

  Start1()
  if (
    !Start2() ; if the image is not found
    && CheckRestoreSanityMenu() ; and restore sanity menu is showed
  ) {
    Adb.PressBack()
    return false
  }

  WaitUntilOperationComplete()
  return true
}

WaitUntilOperationComplete() {
  static OPERATION_COMPLETE_REGION := [60, 175, 220, 80]

  Adb.OCR_Click(OPERATION_COMPLETE_REGION, "OPERATION COMPLETE",
    , 3000 ; add delay to wait for the dialoge to finish
  )
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
