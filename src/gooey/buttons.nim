import gooey, mathtypes

type ButtonBase*[Base] = ref object of Base
  clickCb*: proc()

proc layout*[Base](button: ButtonBase[Base], parent: Base, offset, screenSize: Vec3) =
  mixin layout
  Base(button).layout(parent, offset, screenSize)

proc onClick*[Base](button: ButtonBase[Base], uiState: var UiState) =
  if button.clickCb != nil:
    button.clickCb()
