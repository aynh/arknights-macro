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

UnpackRegionArray(region, &X1, &Y1, &W, &H) {
  X1 := region[1]
  Y1 := region[2]
  W := region[3]
  H := region[4]
}
