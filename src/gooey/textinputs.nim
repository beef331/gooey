import gooey, mathtypes

type TextInputBase*[Base] = ref object of Base
  text*: string
  watchValue*: proc(): string
  onChange*: proc(str: string)

proc layout*[Base](input: TextInputBase[Base], parent: Base, offset: Vec3, state: UiState) =
  mixin layout
  Base(button).layout(parent, offset, state)
  if input.watchValue != nil:
    input.text = input.watchValue()

proc onTextInput*[Base](input: TextInputBase[Base], uiState: var UiState) =
  case uiState.input.kind
  of textInput:
    if uiState.input.text != input.text:
      input.text = text
      onChange(input.text)
  else: discard
