{.this: self.}

import expr
import stmt
import literaltype
import tokentype
import Token
import strutils
import runtimeerror

type
  Interpreter* = ref object of RootObj

  BaseType = ref object of RootObj

  NumType = ref object of BaseType
    value: float64

  StrType = ref object of BaseType
    value: string

  BoolType = ref object of BaseType
    value: bool
  
  NilType = ref object of BaseType

# Forward Declaration
proc isTruthy(self: Interpreter, base: BaseType): bool
proc isEqual(a: BaseType, b: BaseType): bool
proc checkNumberOperand(self: Interpreter, operator: Token, operand: BaseType)
proc checkNumberOperands(self: Interpreter, operator: Token, left: BaseType, right: BaseType)
proc `$`(value: BaseType): string 

# Proc

proc newInterpreter*(): Interpreter =
  return Interpreter()

proc newNum(v: float64): NumType =
  return NumType(value: v)

proc newStr(v: string): StrType =
  return StrType(value: v)

proc newBool(v: bool): BoolType =
  return BoolType(value: v)

proc newNil(): NilType =
  return NilType()

method evaluate*(self: Interpreter, expr: Expr): BaseType {.base.}=
  discard

method evaluate*(self: Interpreter, expr: Literal): BaseType =
  case expr.value.litKind
  of NumLit: return newNum(expr.value.n)
  of StrLit: return newStr(expr.value.s)
  of BoolLit: return newBool(expr.value.b)
  of NilLit: return newNil()


method evaluate*(self: Interpreter, expr: Grouping): BaseType =
  return evaluate(expr.expression)

method evaluate*(self: Interpreter, expr: Unary): BaseType =
  var right = evaluate(expr.right)

  case expr.operator.tkType
  of BANG:
    return newBool(not isTruthy(right))
  of MINUS:
    checkNumberOperand(expr.operator, right)
    return newNum(-NumType(right).value)
  else:
    discard
  
  return nil

proc isTruthy(self: Interpreter, base: BaseType): bool =
  if base of NilType:
    return false
  if base of BoolType:
    return BoolType(base).value
  return true 

method evaluate*(self: Interpreter, expr: Binary): BaseType =
    var left = evaluate(expr.left)
    var right = evaluate(expr.right)

    case expr.operator.tkType
    of GREATER:
      checkNumberOperands(expr.operator, left, right)
      return newBool(NumType(left).value > NumType(right).value)
    of GREATER_EQUAL:
      checkNumberOperands(expr.operator, left, right)
      return newBool(NumType(left).value >= NumType(right).value)
    of LESS:
      checkNumberOperands(expr.operator, left, right)
      return newBool(NumType(left).value < NumType(right).value)
    of LESS_EQUAL:
      checkNumberOperands(expr.operator, left, right)
      return newBool(NumType(left).value <= NumType(right).value)
    of BANG_EQUAL:
      return newBool(not isEqual(left, right))
    of EQUAL_EQUAL:
      return newBool(isEqual(left, right))
    of MINUS:
      checkNumberOperands(expr.operator, left, right)
      return newNum(NumType(left).value - NumType(right).value)
    of SLASH:
      checkNumberOperands(expr.operator, left, right)
      return newNum(NumType(left).value / NumType(right).value)
    of STAR:
      checkNumberOperands(expr.operator, left, right)
      return newNum(NumType(left).value * NumType(right).value)
    of PLUS:
      if left of NumType and right of NumType:
        return newNum(NumType(left).value + NumType(right).value)
      if left of StrType and right of StrType:
        return newStr(StrType(left).value & StrType(right).value)
      raise newRuntimeError(expr.operator, "Operands must be either two number or two strings.")    
    else:
      discard
    
    return nil
    
proc isEqual(a: BaseType, b: BaseType): bool =
  if a of NilType and b of NilType: return true

  if a of BoolType and b of BoolType:
    return BoolType(a).value == BoolType(b).value
  
  if a of NumType and b of NumType:
    return NumType(a).value == NumType(b).value

  if a of StrType and b of StrType:
    return StrType(a).value == StrType(b).value

  return false

proc checkNumberOperand(self: Interpreter, operator: Token, operand: BaseType) =
  if operand of NumType: return
  raise newRuntimeError(operator, "Operator must be a number.")

proc checkNumberOperands(self: Interpreter, operator: Token, left: BaseType, right: BaseType) =
  if left of NumType and right of NumType: return

  raise newRuntimeError(operator, "Operands must be numbers.")

method evaluate*(self: Interpreter, stmt: Stmt) {.base.} = discard

method evaluate*(self: Interpreter, stmt: ExprStmt) =
    discard evaluate(stmt.expression)

method evaluate*(self: Interpreter, stmt: PrintStmt) =
    var value = evaluate(stmt.expression)
    echo value

proc interpret*(self: Interpreter, statements: seq[Stmt]) =
  try:
    for statement in statements:
      evaluate(statement)
  except RuntimeError as e:
    runtimeError(e)

proc `$`(value: BaseType): string =
  if value of NilType: return "nil"

  if value of NumType:
    var text = $NumType(value).value
    if text.endsWith(".0"):
      text = text[0 .. ^3]
    return text
  
  if value of StrType:
    return StrType(value).value
  
  if value of BoolType:
    return $BoolType(value).value
