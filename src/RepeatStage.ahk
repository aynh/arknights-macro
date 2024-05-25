#Requires AutoHotkey v2.0

#Include Utilities.ahk

RepeatStage() {
  prompt := InputBox("How many runs?", "RepeatStage", "w150 h90")
  if prompt.Result != 'OK'
    return
  else if !IsNumber(prompt.Value) {
    MsgBox "Value must be a number", , 0x10
    return
  }

  how_many := Number(prompt.Value)

  sequences := [
    ; image variations, X1, Y1, X2, Y2
    [["start-1a", "start-1b", "start-1c"], 1110, 680, 1320, 720],
    [["start-2a", "start-2b"], 1110, 400, 1240, 680],
    [["end"], 70, 190, 170, 270]
  ]

  idx := 0
  while Floor(idx / sequences.Length) < how_many {
    sequence := sequences[Mod(idx, sequences.Length) + 1] ; ahk array starts at 1
    if ClickSequence(
      sequence[1], sequence[2],
      sequence[3], sequence[4], sequence[5]
    ) {
      idx += 1
    }
  }
}

ClickSequence(images, X1, Y1, X2, Y2) {
  idx := 0
  while true {
    if ClickImage(
      images[Mod(idx, images.Length) + 1],
      X1, Y1, X2, Y2
    ) {
      return true
    }
    idx += 1
  }
}
