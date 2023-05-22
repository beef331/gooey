import gooey, mathtypes
import std/typetraits

type
  HorizontalGroupBase*[Base, T] = ref object of Base
    entries*: T
    margin*: float32
    rightToLeft*: bool

proc usedSize*[Base, T](horz: HorizontalGroupBase[Base, T]): Vec2 =
  mixin usedSize
  result = typeof(horz.size).init(float32(tupleLen(T) - 1) * horz.margin, 0f)
  for field in horz.entries.fields:
    let size = usedSize(field)
    result.x = size.x
    result.y = max(size.y, result.y)

proc layout*[Base, T](horz: HorizontalGroupBase[Base, T], parent: Base, offset, screenSize: Vec3) =
  mixin layout
  horz.size = usedSize(horz)
  Base(horz).layout(parent, offset, screenSize)
  var offset = typeof(offset).init(0, 0, 0)
  for field in horz.entries.fields:
    field.layout(horz, offset, screenSize)
    offset.x += horz.margin + field.size.x

proc interact*[Base, T](horz: HorizontalGroupBase[Base, T], state: var UiState) =
  mixin interact
  interact(horz.entries, state)

proc upload*[Base, T](horz: HorizontalGroupBase[Base, T], state: UiState, target: var auto) =
  mixin upload
  upload(horz.entries, state, target)
