#Requires AutoHotkey v2.0

#Include Helper.ahk

#Include <OCR>

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

  static SANITY_COUNT_REGION := [1210, 20, 1290, 65]
  static SANITY_PER_STAGE_REGION := [1255, 735, 1305, 760]
}

RepeatAnnihilation() {
  RepeatSequences(RepeatStageConst.ANNIHILATION_SEQUENCES, 5)
}

RepeatStage() {
  prompt := InputBox(, "RepeatStage", "w150 h75")
  if (prompt.Result != 'OK') {
    return
  }

  if prompt.Value == ''
    RepeatStageAuto()
  else if !IsNumber(prompt.Value)
    return
  else
    RepeatSequences(
      RepeatStageConst.NORMAL_STAGE_SEQUENCES,
      Number(prompt.Value)
    )
}

RepeatStageAuto() {
  region := RepeatStageConst.SANITY_COUNT_REGION
  sanity_count := Number(
    StrSplit(
      ; this OCR results in value like 14/130
      ; so we split it and get the first part
      OCR.FromRect(
        region[1], region[2],
        ; OCR.FromRect uses width and height as 3rd and 4th
        ; parameter instead of the usual x2 y2
        region[3] - region[1], region[4] - region[2],
        'en', 4
      ).Text,
      '/'
    )[1]
  )

  region := RepeatStageConst.SANITY_PER_STAGE_REGION
  sanity_per_stage := -( ; negate the value to make it positive
    Number(
      OCR.FromRect(
        region[1], region[2],
        region[3] - region[1], region[4] - region[2],
        'en', 4
      ).Text
    )
  )

  RepeatSequences(
    RepeatStageConst.NORMAL_STAGE_SEQUENCES,
    sanity_count // sanity_per_stage
  )
}

RepeatSequences(sequences, count) {
  idx := 0
  while (idx // sequences.Length) < count {
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
