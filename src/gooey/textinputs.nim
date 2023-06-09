import gooey, mathtypes

type TextInputBase*[Base] = ref object of Base
  text*: string
  watchValue*: proc(): string
  onChange*: proc(str: string)

proc layout*[Base](input: TextInputBase[Base], parent: Base, offset: Vec3, state: UiState) =
  mixin layout
  Base(input).layout(parent, offset, state)
  if input.watchValue != nil:
    input.text = input.watchValue()

proc onTextInput*[Base](input: TextInputBase[Base], uiState: var UiState) =
  case uiState.input.kind
  of textInput:
    input.text &= uiState.input.str
  of textDelete:
    input.text.setLen(max(input.text.high, 0))

  of textNewLine:
    input.text.add '\n'

  else: discard

  case uiState.input.kind
  of TextEditFields:
    if input.onChange != nil:
      input.onChange(input.text)
  else: discard
