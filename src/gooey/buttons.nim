import gooey, mathtypes

type ButtonBase*[Base] = ref object of Base
  clickCb*: proc()

proc layout*[Base](button: ButtonBase[Base], parent: Base, offset: Vec3, state: UiState) =
  mixin layout
  Base(button).layout(parent, offset, state)

proc onClick*[Base](button: ButtonBase[Base], uiState: var UiState) =
  if button.clickCb != nil:
    button.clickCb()
