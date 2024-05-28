#Requires AutoHotkey v2.0

#Include Helper.ahk

RepeatStage() {
  CLICK_SEQUENCES := [
    ClickSequence(["start-1a", "start-1b", "start-1c"], [1110, 680, 1320, 720]),
    ClickSequence(["start-2a", "start-2b"], [1110, 400, 1240, 680]),
    ClickSequence(["end"], [70, 190, 170, 270])
  ]

  prompt := InputBox(, "RepeatStage", "w150 h75")
  if prompt.Result != 'OK'
    return

  if StrLower(prompt.Value) == "annihilation" {
    CLICK_SEQUENCES := [
      ClickSequence(['start-annihilation-1'], [1110, 670, 1320, 720]),
      ClickSequence(['start-annihilation-2'], [1110, 670, 1320, 720]),
      ClickSequence(['end'], [70, 190, 170, 270])
    ]
    count := 5
  } else if !IsNumber(prompt.Value) {
    MsgBox "Value must be a number", , 0x10
    return
  }

  count := Number(prompt.Value)

  idx := 0
  while Floor(idx / CLICK_SEQUENCES.Length) < count {
    click_sequence := CLICK_SEQUENCES[
      Mod(idx, CLICK_SEQUENCES.Length) + 1 ; ahk array starts at 1
    ]

    if click_sequence.Click()
      idx += 1
  }
}

class ClickSequence {
  __New(variations, region) {
    this.variations := variations
    this.region := region
  }

  Click() {
    idx := 0
    loop {
      if ClickImage(
        this.variations[Mod(idx, this.variations.Length) + 1],
        this.region[1], this.region[2], this.region[3], this.region[4],
      ) {
        return true
      }
      idx += 1
    }
  }
}
