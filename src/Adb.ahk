#Requires AutoHotkey v2.0

#Include <ImagePut>
#Include <OCR>

#Include Helper.ahk

class Adb {
  static device := ""
  static ready := false

  static Setup(device := "127.0.0.1:5555") {
    OnExit((*) => Adb.Cleanup())
    this.ready := true
    this.Run("kill-server")

    this.Run(Format("connect {}", device))
    this.device := device

    this.Run("shell wm 1280x720")
    this.Run("shell media volume --set 0")
  }

  static Cleanup() {
    this.Run("shell wm reset")
    this.Run("shell media volume --set 10")
    this.Run(Format("disconnect {}", this.device))
    this.Run("kill-server")
  }

  static Run(command) {
    if !this.ready
      this.Setup()

    shell := ComObject("Wscript.Shell")
    if this.device == ""
      shell.Run(Format("{} /C adb.exe {}", A_ComSpec, command), 0, true)
    else
      shell.Run(Format("{} /C adb.exe -s {} {}", A_ComSpec, this.device, command), 0, true)
  }

  static Click(X, Y) {
    this.Run(Format("shell input tap {} {}", X, Y))
  }

  static Screenshot(region := []) {
    TMP_IMAGE_PATH := Format("{}/screenshot.png", A_Temp)

    this.Run(Format("exec-out screencap -p > {}", TMP_IMAGE_PATH))

    if region.Length != 4
      buf := ImagePutBuffer({ file: TMP_IMAGE_PATH })
    else {
      UnpackRegionArray(region, &X1, &Y1, &W, &H)
      buf := ImagePutBuffer({
        file: TMP_IMAGE_PATH,
        crop: [X1, Y1, W, H]
      })
    }

    return buf
  }

  static ClickAnyImage(filenames, region) {
    idx := 0
    loop {
      if this.ClickImage(
        filenames[Mod(idx, filenames.Length) + 1], region
      ) {
        break
      }
      idx += 1
    }
  }

  static ClickImage(filename, region) {
    UnpackRegionArray(region, &X1, &Y1, &W, &H)
    screenshot := this.Screenshot(
      ; only get screenshot around the region
      [X1 - 10, Y1 - 10, W + 10, H + 10]
    )

    Sleep(1000)
    if screenshot.ImageSearch({
      file: Format("../assets/images/{}.png", filename)
    }) {
      this.ClickRegion(region)
      return true
    }

    return false
  }

  static ClickRegion(region) {
    UnpackRegionArray(region, &X1, &Y1, &W, &H)
    this.Click(X1 + W / 2, Y1 + H / 2) ; clicks the middle of region
  }

  static OCR_Region(region, scale := 1) {
    screenshot := this.Screenshot(region)
    hBitmap := ImagePutHBitmap({ buffer: screenshot, scale: scale })
    return OCR.FromBitmap(hBitmap, 'en-US').Text
  }
}
