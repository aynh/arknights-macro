#Requires AutoHotkey v2.0

#Include <ImagePut>
#Include <OCR>

#Include Error.ahk
#Include Utilities.ahk

class Adb {
  static connected := false
  static device := "127.0.0.1:5555"

  static should_stop := false
  static Stop() {
    this.should_stop := true
  }

  static Setup(device := this.device) {
    this.Run(Format("disconnect {}", device), true)

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
    if this.should_stop {
      this.should_stop := false
      throw AdbStop()
    } else if !this.connected && !is_setup
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

  static SetVolume(to) {
    this.Run(Format("shell media volume --show --set {}", to))
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
      buf := ImagePutBuffer({
        file: this.TMP_IMAGE_PATH,
        crop: region
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
    this.Click(X1 + W / 2, Y1 + H / 2) ; click the middle of region
  }

  static OCR(region, scale := 1, retake_screenshot := false) {
    screenshot := this.Screenshot(region, retake_screenshot)
    hBitmap := ImagePutHBitmap({ buffer: screenshot, scale: scale })
    return Trim(OCR.FromBitmap(hBitmap, 'en-US').Text)
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
  static OCR_WaitUntilMatch(region, match, scale?) {
    while this.OCR(region, scale?, true) != match
      Sleep(1000)
  }

  ; variant of OCR that will click the region if the result matches
  static OCR_Click(region, match, scale?) {
    this.OCR_WaitUntilMatch(region, match, scale?)
    this.ClickRegion(region)
  }

  ; variant of OCR_Click that will return instead of
  ; running indefinitely until it found a match
  static OCR_TryClick(region, match, scale?) {
    if this.OCR(region, scale?, true) != match
      return false

    this.ClickRegion(region)
    return true
  }
}
