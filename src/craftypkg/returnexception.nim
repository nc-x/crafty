import types

type
  ReturnException* = ref object of Exception
    value*: BaseType

proc newReturnException*(v: BaseType): ReturnException =
  return ReturnException(value: v)
