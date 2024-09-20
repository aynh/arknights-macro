#Include Adb.ahk

REGION := {
  menu: [1155, 25, 95, 35],
  skip_confirm: [700, 500, 140, 45],
  accept_reward: [555, 600, 160, 65],
  read_next_story: [715, 490, 125, 50],
  start_battle: [1085, 630, 145, 50],
  end_battle: [1110, 640, 110, 45],
  all_clear: [690, 145, 190, 35]
}

COORDINATE := {
  skip_button: [1205, 120]
}

StorySkip() {
  switch true {
    case Adb.OCR(REGION.menu, , true) == "Menu":
    {
      Adb.ClickRegion(REGION.menu)
      Sleep(250)
      Adb.Click(COORDINATE.skip_button*)
      Sleep(250)
      if Adb.OCR(REGION.skip_confirm, , true) == "Confirm"
        Adb.ClickRegion(REGION.skip_confirm)
    }

    case Adb.OCR(REGION.accept_reward) == "TOUCH":
    {
      Adb.ClickRegion(REGION.accept_reward)
    }

    case Adb.OCR(REGION.read_next_story) == "Watch":
    {
      Adb.ClickRegion(REGION.read_next_story)
    }

    case Adb.OCR(REGION.start_battle) == "Mobilize":
    {
      Adb.ClickRegion(REGION.start_battle)
      Adb.OCR_Click(REGION.end_battle, "Confirm")
    }

    case Adb.OCR(REGION.all_clear) == "All Episodes cleared.":
    {
      return true
    }
  }

  return false
}

loop {
  if StorySkip() {
    MsgBox("Done clearing a chapter", A_ScriptName, 0x30)
    break
  }

  Sleep(500)
}
