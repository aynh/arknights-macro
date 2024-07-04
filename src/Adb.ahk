#Requires AutoHotkey v2.0

#Include <ImagePut>
#Include <OCR>

#Include Helper.ahk

class Adb {
  static connected := false
  static device := "127.0.0.1:5555"

  static Setup(device := this.device) {
    if !this.connected {
      this.Run("kill-server", true)
      this.Run("start-server", true)

      ; findstr will succeeds if it finds the word "connected"
      this.RunUntilSuccess(Format('connect {} | findstr "\connected\>"', this.device), true)
      this.connected := true

      this.Run("shell wm 1280x720")
      this.Run("shell media volume --set 0")
    }
  }

  static Run(command, is_setup := false) {
    if !this.connected && !is_setup
      this.Setup()

    shell := ComObject("Wscript.Shell")
    if this.connected
      ; 0 = run with hidden window, true: wait until the program finishes then return the program exit code
      return shell.Run(Format("{} /C adb.exe -s {} {}", A_ComSpec, this.device, command), 0, true)
    else
      return shell.Run(Format("{} /C adb.exe {}", A_ComSpec, command), 0, true)
  }

  ; variant of Run that will keep trying until it gets no error code
  static RunUntilSuccess(command, is_setup?) {
    ; while return code is non-zero:
    while this.Run(command, is_setup?)
      Sleep(3000)
  }

  static Click(X, Y) {
    this.Run(Format("shell input tap {} {}", X, Y))
  }

  ; screenshot the android device, optionally cropping the image with region if specified
  static TMP_IMAGE_PATH := Format("{}/screenshot.png", A_Temp)
  static Screenshot(region := []) {
    this.Run(Format("exec-out screencap -p > {}", this.TMP_IMAGE_PATH))

    if region.Length != 4
      buf := ImagePutBuffer({ file: this.TMP_IMAGE_PATH })
    else {
      UnpackRegionArray(region, &X1, &Y1, &W, &H)
      buf := ImagePutBuffer({
        file: this.TMP_IMAGE_PATH,
        crop: [X1, Y1, W, H]
      })
    }

    return buf
  }

  ; variant of TryClickImage that loop indefinitely until
  ; it clicks on any of the image specified
  static ClickImage(filename_or_filenames, region) {
    loop
      if this.TryClickImage(filename_or_filenames, region)
        break
  }


  ; click image with filename around region
  ; return true if the image is found and thus clicked
  static TryClickImage(filename_or_filenames, region) {
    if filename_or_filenames is Array {
      for filename in filename_or_filenames
        if this.TryClickImage(filename, region)
          return true

      return false
    }

    UnpackRegionArray(region, &X1, &Y1, &W, &H)
    screenshot := this.Screenshot(
      ; only get screenshot around the region
      [X1 - 10, Y1 - 10, W + 10, H + 10]
    )

    Sleep(1000)
    if screenshot.ImageSearch({
      file: Format("../assets/images/{}.png", filename_or_filenames)
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

  static OCR(region, scale := 1) {
    screenshot := this.Screenshot(region)
    hBitmap := ImagePutHBitmap({ buffer: screenshot, scale: scale })
    return OCR.FromBitmap(hBitmap, 'en-US').Text
  }

  ; variant of OCR that keeps running until result == match
  ; then click the region afterwards
  static OCR_Click(region, match, scale?, delay := 0) {
    while this.OCR(region, scale?) != match
      Sleep(3000)

    Sleep(delay)
    this.ClickRegion(region)
  }
}
