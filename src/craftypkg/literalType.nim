type
  LitKind* = enum
    NumLit,
    StrLit,
    NilLit,
    BoolLit
  
  LiteralType* = object
    case litKind*: LitKind
    of NumLit: n*: float64
    of StrLit: s*: string
    of BoolLit: b*: bool
    of NilLit: discard

proc newNumLit*(n: float64): LiteralType =
  return LiteralType(litKind: NumLit, n: n)

proc newStrLit*(s: string): LiteralType =
  return LiteralType(litKind: StrLit, s: s)

proc newBoolLit*(b: bool): LiteralType =
  return LiteralType(litKind: BoolLit, b: b)

proc newNilLit*(): LiteralType =
  return LiteralType(litKind: NilLit)

proc `$`*(lt: LiteralType): string =
  case lt.litKind
  of NumLit: return $lt.n
  of StrLit: return lt.s
  of BoolLit: return $lt.b
  of NilLit: return "nil"
  