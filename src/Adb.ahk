#Requires AutoHotkey v2.0

#Include <ImagePut>
#Include <OCR>

#Include Helper.ahk

class Adb {
  static connected := false
  static device := "127.0.0.1:5555"

  static Setup(device := this.device) {
    while not (
      this.connected := this.Run(
        Format('devices | findstr "\{}\>" | findstr "\device\>"', device), true
      )
    ) {
      this.Run(Format("connect {}", device), true)
      Sleep(1000)
    }

    this.device := device
  }

  static Run(command, is_setup := false) {
    if !this.connected && !is_setup
      this.Setup()

    shell := ComObject("Wscript.Shell")
    if this.connected
      ; 0 = run with hidden window, true: wait until the program finishes then return the program exit code
      exit_code := shell.Run(Format("{} /C adb.exe -s {} {}", A_ComSpec, this.device, command), 0, true)
    else
      exit_code := shell.Run(Format("{} /C adb.exe {}", A_ComSpec, command), 0, true)

    ; exit code of 0 means success
    return exit_code == 0
  }

  static Click(XY*) {
    this.Run(Format("shell input tap {} {}", XY[1], XY[2]))
  }

  static PressBack() {
    this.Run("shell input keyevent 4")
  }

  ; screenshot the android device, optionally cropping the image with region if specified
  static TMP_IMAGE_PATH := Format("{}/screenshot.png", A_Temp)
  static Screenshot(region := [], retake := true) {
    static should_retake := true
    if should_retake || retake {
      should_retake := false
      this.Run(Format("exec-out screencap -p > {}", this.TMP_IMAGE_PATH))
      SetTimer(() => should_retake := true, -5000)
    }

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

    if this.ImageSearch(region, filename_or_filenames) {
      this.ClickRegion(region)
      return true
    }

    return false
  }

  static ImageSearch(region, filename) {
    Sleep(1000)
    UnpackRegionArray(region, &X1, &Y1, &W, &H)
    screenshot := this.Screenshot(
      ; only get screenshot around the region
      [X1 - 10, Y1 - 10, W + 10, H + 10]
    )

    return screenshot.ImageSearch({
      file: Format("../assets/images/{}.png", filename)
    })
  }

  static ClickRegion(region) {
    UnpackRegionArray(region, &X1, &Y1, &W, &H)
    this.Click(X1 + W / 2, Y1 + H / 2) ; clicks the middle of region
  }

  static OCR(region, scale := 1, retake_screenshot := false) {
    screenshot := this.Screenshot(region, retake_screenshot)
    hBitmap := ImagePutHBitmap({ buffer: screenshot, scale: scale })
    return OCR.FromBitmap(hBitmap, 'en-US').Text
  }

  ; variant of OCR that keeps running until it gets non-empty value
  static OCR_NonEmpty(region, scale?) {
    loop {
      if value := this.OCR(region, scale?, true)
        return value

      Sleep(1000)
    }
  }

  ; variant of OCR that keeps running until result == match
  ; then click the region afterwards
  static OCR_Click(region, match, scale?, delay := 0) {
    while this.OCR(region, scale?, true) != match
      Sleep(1000)

    Sleep(delay)
    this.ClickRegion(region)
  }
}
