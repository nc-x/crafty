import token
import literalType

type
  Expr* = ref object of RootObj
    
  Binary* = ref object of Expr
    left*: Expr
    operator*: Token
    right*: Expr

  Grouping* = ref object of Expr
    expression*: Expr
  
  Literal* = ref object of Expr
    value*: LiteralType
  
  Unary* = ref object of Expr
    operator*: Token
    right*: Expr

  Variable* = ref object of Expr
    name*: Token

proc newBinary*(left: Expr, operator: Token, right: Expr): Binary=
  result = Binary(left: left, operator: operator, right: right)

proc newGrouping*(expression: Expr): Grouping=
  result = Grouping(expression: expression)

proc newLiteral*(value: LiteralType): Literal=
  result = Literal(value: value)

proc newUnary*(operator: Token, right: Expr): Unary=
  result = Unary(operator: operator, right: right)

proc newVariable*(name: Token): Variable =
  result = Variable(name: name)