## Load and Save SVG files.

import chroma, flippy, flippy/paths, vmath, xmlparser, xmltree,
  strutils, strutils, chroma/blends

var tmp: Image

proc draw(img: Image, matStack: var seq[Mat3], xml: XmlNode) =
  case xml.tag:

    of "g":
      let fill = xml.attr("fill")
      let stroke = xml.attr("stroke")
      let strokeWidth = xml.attr("stroke-width")
      let transform = xml.attr("transform")

      if transform != "":
        if transform.startsWith("matrix("):
          let arr = transform[7..^2].split(",")
          assert arr.len == 6
          var m = mat3()
          m[0] = parseFloat(arr[0])
          m[1] = parseFloat(arr[1])
          m[3] = parseFloat(arr[2])
          m[4] = parseFloat(arr[3])
          m[6] = parseFloat(arr[4])
          m[7] = parseFloat(arr[5])
          matStack.add(matStack[^1] * m)
        else:
          echo "Unsupported transform: " & xml.tag
          var m = mat3()
          matStack.add(m)
          #raise newException(ValueError, "Unsupported transform: " & transform)

      for child in xml:
        if child.tag == "path":
          let d = child.attr("d")

          if fill != "none" and fill != "":
            let fillColor = parseHtmlColor(fill).rgba
            tmp.fill(rgba(0,0,0,0))
            tmp.fillPath(d, fillColor, mat = matStack[^1])
            img.blitWithBlendMode(tmp, Normal, vec2(0, 0))
            # if child.attr("id") == "path56":
            #   echo "path56.fill.png"
            #   tmp.save("path56.fill.png")

          if stroke != "none" and stroke != "":
            let strokeColor = parseHtmlColor(stroke).rgba
            let strokeWidth =
              if strokeWidth == "": 1.0 # Default stroke width is 1px
              else: parseFloat(strokeWidth)
            tmp.fill(rgba(0,0,0,0))
            tmp.strokePath(d, strokeColor, strokeWidth, mat = matStack[^1])
            img.blitWithBlendMode(tmp, Normal, vec2(0, 0))
            # if child.attr("id") == "path56":
            #   echo "path56.stroke.png"
            #   tmp.save("path56.stroke.png")

        else:
          img.draw(matStack, child)

      if transform != "":
        discard matStack.pop()

    else:
      echo "Unsupported tag: " & xml.tag
      #raise newException(ValueError, "Unsupported tag: " & xml.tag )

proc readSvg*(data: string): Image =
  ## Render SVG file and return the image.
  var xml = parseXml(data)
  assert xml.tag == "svg"
  var viewBox = xml.attr "viewBox"
  let box = viewBox.split(" ")
  assert parseInt(box[0]) == 0
  assert parseInt(box[1]) == 0
  let w = parseInt(box[2])
  let h = parseInt(box[3])
  result = newImage(w, h, 4)

  #result.fill(rgba(255, 255, 255, 255))

  tmp = result.copy()

  var matStack = @[mat3()]
  for n in xml:
    result.draw(matStack, n)
