#Requires AutoHotkey v2.0

#Include <OCR>

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

ClickImage(image_name, region) {
  CoordMode 'Pixel', 'Screen'
  CoordMode 'Mouse', 'Screen'
  SendMode 'Event'
  SetDefaultMouseSpeed 50

  UnpackRegionArray(region, &X1, &Y1, &X2, &Y2)

  Sleep 1000
  if ImageSearch(
    &X, &Y,
    ; widen the region a bit for some tolerance
    X1 - 10, Y1 - 10, X2 + 10, Y2 + 10,
    Format("*80 ../assets/images/{}.png", image_name)
  ) {
    ; click the middle instead of top left corner of the region
    X += (X2 - X1) / 2
    Y += (Y2 - Y1) / 2
    Click X, Y
    return true
  }

  return false
}

OCR_Region(region, scale?) {
  UnpackRegionArray(region, &X1, &Y1, &X2, &Y2)

  return OCR.FromRect(
    X1, Y1,
    ; OCR.FromRect uses width and height as 3rd and 4th
    ; parameter instead of the usual x2 y2
    X2 - X1, Y2 - Y1,
    'en', scale
  ).Text
}

UnpackRegionArray(region, &X1, &Y1, &X2, &Y2) {
  X1 := region[1]
  Y1 := region[2]
  X2 := region[3]
  Y2 := region[4]
}
