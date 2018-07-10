import expr, hashes, literaltype, token

method hash*(x: Expr): Hash {.base.} = discard

proc hash*(x: LiteralType): Hash =
  case x.litKind
  of NumLit: result = x.n.hash
  of StrLit: result = x.s.hash
  of BoolLit: result = x.b.hash
  of NilLit: result = "nil".hash
  result = !$result

proc hash*(x: Token): Hash =
  result = x.tkType.hash !& x.lexeme.hash !& x.literal.hash !& x.line.hash
  result = !$result

method hash*(x: Assign): Hash =
  result = x.name.hash !& x.value.hash
  result = !$result

method hash*(x: Binary): Hash =
  result = x.left.hash !& x.operator.hash !& x.right.hash
  result = !$result

method hash*(x: Call): Hash =
  result = x.callee.hash !& x.paren.hash !& x.arguments.hash
  result = !$result

method hash*(x: Grouping): Hash =
  result = x.expression.hash
  result = !$result

method hash*(x: Literal): Hash =
  result = x.value.hash
  result = !$result

method hash*(x: Logical): Hash =
  result = x.left.hash !& x.operator.hash !& x.right.hash
  result = !$result

method hash*(x: Unary): Hash =
  result = x.operator.hash !& x.right.hash
  result = !$result

method hash*(x: Variable): Hash =
  result = x.name.hash
  result = !$result
