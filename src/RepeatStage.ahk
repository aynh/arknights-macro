#Requires AutoHotkey v2.0

#Include Helper.ahk

class RepeatStageConst {
  static ANNIHILATION_SEQUENCES := [
    ClickSequence(['start-annihilation-1'], [1110, 670, 1320, 720]),
    ClickSequence(['start-annihilation-2'], [1110, 670, 1320, 720]),
    ClickSequence(['end'], [70, 190, 170, 270])
  ]

  static NORMAL_STAGE_SEQUENCES := [
    ClickSequence(["start-1a", "start-1b", "start-1c"], [1110, 680, 1320, 720]),
    ClickSequence(["start-2a", "start-2b"], [1110, 400, 1240, 680]),
    ClickSequence(["end"], [70, 190, 170, 270])
  ]
}

RepeatAnnihilation() {
  RepeatSequences(RepeatStageConst.ANNIHILATION_SEQUENCES, 5)
}

RepeatStage() {
  prompt := InputBox(, "RepeatStage", "w150 h75")
  if (prompt.Result != 'OK') || (!IsNumber(prompt.Value)) {
    return
  }

  RepeatSequences(RepeatStageConst.NORMAL_STAGE_SEQUENCES, Number(prompt.Value))
}

RepeatSequences(sequences, count) {
  idx := 0
  while Floor(idx / sequences.Length) < count {
    click_sequence := sequences[
      Mod(idx, sequences.Length) + 1 ; ahk array starts at 1
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
