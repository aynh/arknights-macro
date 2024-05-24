#Requires AutoHotkey v2.0

ArrayIncludes(arr, match) {
  for element in arr
    if element == match
      return true
}

ArrayJoin(arr, separator := ' ') {
  out := ""
  for idx, element in arr {
    out .= element
    if idx != arr.Length {
      out .= separator
    }
  }
  return out
}

ClickImage(image, X1, Y1, X2, Y2) {
  CoordMode 'Pixel', 'Screen'
  CoordMode 'Mouse', 'Screen'

  Sleep 1000
  if ImageSearch(
    &X, &Y,
    ; widen the region a bit for some tolerance
    X1 - 10, Y1 - 10, X2 + 10, Y2 + 10,
    Format("*80 images/{}.png", image)
  ) {
    Sleep(2500)
    ; click the middle instead of top left corner of the region
    X += (X2 - X1) / 2
    Y += (Y2 - Y1) / 2
    Click X, Y
    return true
  }

  return false
}
