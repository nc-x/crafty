type
  BaseType* = ref object of RootObj

  NumType* = ref object of BaseType
    value*: float64

  StrType* = ref object of BaseType
    value*: string

  BoolType* = ref object of BaseType
    value*: bool
  
  NilType* = ref object of BaseType

proc newNum*(v: float64): NumType =
  return NumType(value: v)

proc newStr*(v: string): StrType =
  return StrType(value: v)

proc newBool*(v: bool): BoolType =
  return BoolType(value: v)

proc newNil*(): NilType =
  return NilType()
