#Requires AutoHotkey v2.0

#Include Adb.ahk

StartAnnihilation() {
  Adb.ClickAnyImage(['start-annihilation-1'], [1040, 640, 200, 40])
  Adb.ClickAnyImage(['start-annihilation-2'], [1040, 640, 200, 40])
}

StartStage() {
  Adb.ClickAnyImage(["start-1a", "start-1b", "start-1c"], [1040, 640, 200, 40])
  Adb.ClickAnyImage(["start-2a", "start-2b"], [1035, 370, 135, 280])
}

WaitUntilOperationComplete() {
  static OPERATION_COMPLETE_REGION := [60, 175, 220, 80]

  loop {
    if Adb.OCR_Region(OPERATION_COMPLETE_REGION) == "OPERATION COMPLETE" {
      Sleep(3000) ; wait for the dialogue to finist
      Adb.ClickRegion(OPERATION_COMPLETE_REGION)
      break
    }

    Sleep(3000)
  }
}

RepeatAnnihilation() {
  loop 5 {
    StartAnnihilation()
    WaitUntilOperationComplete()
  }
}

RepeatStage() {
  prompt := InputBox(, "RepeatStage", "w150 h75")
  if prompt.Result != "OK"
    return

  LoopStage(n) {
    loop n {
      StartStage()
      WaitUntilOperationComplete()
    }
  }

  if prompt.Value == ""
    LoopStage(GetCurrentSanity() // GetStageCost())
  else if IsNumber(prompt.Value)
    LoopStage(Number(prompt.Value))
}

GetCurrentSanity() {
  static SANITY_REGION := [1115, 15, 120, 50]

  sanity_and_max_sanity := Adb.OCR_Region(SANITY_REGION, 4)
  sanity := StrSplit(sanity_and_max_sanity)[1]
  return Number(sanity)
}

GetStageCost() {
  static STAGE_COST_REGION := [1185, 690, 45, 25]

  stage_cost := -Number(Adb.OCR_Region(STAGE_COST_REGION, 4))
  return stage_cost
}
