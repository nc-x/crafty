{.this: self.}

import expr
import stmt
import types
import literaltype
import tokentype
import Token
import strutils
import runtimeerror
import environment
import sugar
import times


type
  Interpreter* = ref object of RootObj
    globals*: Environment
    environment*: Environment

  FuncType* = ref object of BaseType
    arity*: () -> int
    call*: (Interpreter, seq[BaseType]) -> BaseType

  Function* = ref object of FuncType
    declaration*: FuncStmt

# Forward Declaration
proc isTruthy(self: Interpreter, base: BaseType): bool
proc isEqual(a: BaseType, b: BaseType): bool
proc checkNumberOperand(self: Interpreter, operator: Token, operand: BaseType)
proc checkNumberOperands(self: Interpreter, operator: Token, left: BaseType, right: BaseType)
proc `$`(value: BaseType): string 
proc executeBlock(self: Interpreter, statements: seq[Stmt], environment: Environment)

# Proc

proc newFuncType*(arity: () -> int, call: (Interpreter, seq[BaseType]) -> BaseType): FuncType =
  FuncType(arity: arity, call: call)

proc newFunction*(d: FuncStmt): Function =
  var f = Function()
  f.declaration = d
  f.call = 
    proc(interpreter: Interpreter, arguments: seq[BaseType]): BaseType =
      var environment = newEnvironment(interpreter.globals)
      for i in 0 ..< f.declaration.parameters.len:
        environment.define(f.declaration.parameters[i].lexeme, arguments[i]) 
      
      interpreter.executeBlock(f.declaration.body, environment)
      return nil
  f.arity =
    proc(): int = return f.declaration.parameters.len

  return f

proc newInterpreter*(): Interpreter =
  var globals = newEnvironment()
  globals.define("clock", newFuncType(
    () => 0,
    (Interpreter, seq[BaseType] -> BaseType) => newStr(getClockStr())
  ))
  return Interpreter(globals: globals, environment: globals)

method evaluate*(self: Interpreter, expr: Expr): BaseType {.base.}=
  discard

method evaluate*(self: Interpreter, expr: Assign): BaseType =
  var value = evaluate(expr.value)

  environment.assign(expr.name, value)
  return value

method evaluate*(self: Interpreter, expr: Literal): BaseType =
  case expr.value.litKind
  of NumLit: return newNum(expr.value.n)
  of StrLit: return newStr(expr.value.s)
  of BoolLit: return newBool(expr.value.b)
  of NilLit: return newNil()


method evaluate*(self: Interpreter, expr: Grouping): BaseType =
  return evaluate(expr.expression)

method evaluate*(self: Interpreter, expr: Logical): BaseType =
  var left = evaluate(expr.left)

  if expr.operator.tkType == OR:
    if isTruthy(left): return left
  else:
    if not isTruthy(left): return left

  return evaluate(expr.right)

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

method evaluate*(self: Interpreter, expr: Call): BaseType =
  var callee = evaluate(expr.callee)

  var arguments: seq[BaseType]
  for argument in expr.arguments:
    arguments.add(self.evaluate(argument))
  
  if not(callee of FuncType):
    raise newRuntimeError(expr.paren, "Can only call functions and classes.")

  var function = FuncType(callee)
  if arguments.len != function.arity():
    raise newRuntimeError(expr.paren, "Expected " & $function.arity() & " arguments but got " & $arguments.len & ".")
  return function.call(self, arguments)

method evaluate*(self: Interpreter, expr: Variable): BaseType =
  return environment.get(expr.name)

method evaluate*(self: Interpreter, stmt: Stmt) {.base.} = discard

method evaluate*(self: Interpreter, stmt: ExprStmt) =
    discard evaluate(stmt.expression)

method evaluate*(self: Interpreter, stmt: IfStmt) =
  if isTruthy(evaluate(stmt.condition)):
    evaluate(stmt.thenBranch)
  elif stmt.elseBranch != nil:
    evaluate(stmt.elseBranch)

method evaluate*(self: Interpreter, stmt: PrintStmt) =
    var value = evaluate(stmt.expression)
    echo value

method evaluate*(self: Interpreter, stmt: FuncStmt) =
  var function = newFunction(stmt)
  environment.define(stmt.name.lexeme, function)

method evaluate*(self: Interpreter, stmt: VarStmt) =
  var value: BaseType
  if stmt.initializer != nil:
    value = evaluate(stmt.initializer)
  
  environment.define(stmt.name.lexeme, value)

method evaluate*(self: Interpreter, stmt: WhileStmt) =
    while isTruthy(evaluate(stmt.condition)):
      evaluate(stmt.body)

method evaluate*(self: Interpreter, stmt: BlockStmt) =
  executeBlock(stmt.statements, newEnvironment(environment))

proc executeBlock(self: Interpreter, statements: seq[Stmt], environment: Environment) =
  var previous = self.environment
  try:
    self.environment = environment
    for statement in statements:
      evaluate(statement)
  finally:
    self.environment = previous

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

  if value of Function:
    return "<fn " & Function(value).declaration.name.lexeme & ">"
