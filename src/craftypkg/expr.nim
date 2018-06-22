import token
import literalType

type
  Expr* = ref object of RootObj
    
  Assign* = ref object of Expr
    name*: Token
    value*: Expr

  Binary* = ref object of Expr
    left*: Expr
    operator*: Token
    right*: Expr

  Grouping* = ref object of Expr
    expression*: Expr
  
  Literal* = ref object of Expr
    value*: LiteralType
  
  Logical* = ref object of Expr
    left*: Expr
    operator*: Token
    right*: Expr

  Unary* = ref object of Expr
    operator*: Token
    right*: Expr

  Variable* = ref object of Expr
    name*: Token

proc newAssign*(name: Token, value: Expr): Assign=
  result = Assign(name: name, value: value)

proc newBinary*(left: Expr, operator: Token, right: Expr): Binary=
  result = Binary(left: left, operator: operator, right: right)

proc newGrouping*(expression: Expr): Grouping=
  result = Grouping(expression: expression)

proc newLiteral*(value: LiteralType): Literal=
  result = Literal(value: value)

proc newLogical*(l: Expr, o: Token, r: Expr): Logical=
  result = Logical(left: l, operator: o, right: r)

proc newUnary*(operator: Token, right: Expr): Unary=
  result = Unary(operator: operator, right: right)

proc newVariable*(name: Token): Variable =
  result = Variable(name: name)
