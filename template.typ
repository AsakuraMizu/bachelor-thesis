/// 待填内容占位块，在 PDF 中以橙色背景显示，便于导师审阅时识别
#let todo(body) = block(
  fill: rgb("#fff3cd"),
  stroke: (left: 3pt + rgb("#fd7e14")),
  inset: (left: 8pt, top: 6pt, bottom: 6pt, right: 6pt),
  width: 100%,
  text(fill: rgb("#856404"))[*【待完善】* #body],
)
