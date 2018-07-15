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
import returnexception
import tables
import resolver
import interpreterObj
import objhashes

type
  FuncType* = ref object of BaseType
    arity*: () -> int
    call*: (Interpreter, seq[BaseType]) -> BaseType

  Function* = ref object of FuncType
    declaration*: FuncStmt
    closure*: Environment
    isInitializer*: bool

  ClassType* = ref object of FuncType
    name*: string
    superclass: ClassType
    methods*: Table[string, Function]

  ClassInstance* = ref object of BaseType
    class*: ClassType
    fields*: Table[string, BaseType]

# Forward Declaration
proc newFunction*(declaration: FuncStmt, closure: Environment, isInitializer: bool): Function
proc isTruthy(self: Interpreter, base: BaseType): bool
proc isEqual(a: BaseType, b: BaseType): bool
proc checkNumberOperand(self: Interpreter, operator: Token, operand: BaseType)
proc checkNumberOperands(self: Interpreter, operator: Token, left: BaseType, right: BaseType)
proc `$`(value: BaseType): string 
proc executeBlock(self: Interpreter, statements: seq[Stmt], environment: Environment)

# Proc
proc newClassInstance*(c: ClassType): ClassInstance =
  ClassInstance(class: c, fields: initTable[string, BaseType]())

proc `bind`(self: Function, instance: ClassInstance): Function =
  var environment = newEnvironment(closure)
  environment.define("this", instance)
  return newFunction(declaration, environment, isInitializer)

proc findMethod(self: ClassType, instance: ClassInstance, name: string): Function =
  if methods.contains(name):
    return methods[name].`bind`(instance)

  if superclass != nil:
    return superclass.findMethod(instance, name)

  return nil

proc get*(self: ClassInstance, name: Token): BaseType =
  if fields.contains(name.lexeme):
    return fields[name.lexeme]
  
  var m = class.findMethod(self, name.lexeme)
  if m != nil: return m

  raise newRuntimeError(name, "Undefined property '" & name.lexeme & "'.")

proc set*(self: ClassInstance, name: Token, value: BaseType) =
  if fields.contains(name.lexeme):
    fields.del(name.lexeme)
  fields.add(name.lexeme, value)

proc newClass*(n: string, superclass: ClassType, m: Table[string, Function]): ClassType =
  var c = ClassType(name: n, methods: m)
  c.superclass = superclass
  c.call = 
    proc(interpreter: Interpreter, arguments: seq[BaseType]): BaseType =
      var instance = newClassInstance(c)
      var initializer = c.methods.getOrDefault("init", nil)
      if initializer != nil:
        discard initializer.`bind`(instance).call(interpreter, arguments)
      return instance
  c.arity =
    proc(): int =
      var initializer = c.methods.getOrDefault("init", nil)
      if initializer == nil: return 0      
      return initializer.arity()
  
  return c

proc newFuncType*(arity: () -> int, call: (Interpreter, seq[BaseType]) -> BaseType): FuncType =
  FuncType(arity: arity, call: call)

proc newFunction*(declaration: FuncStmt, closure: Environment, isInitializer: bool): Function =
  var f = Function()
  f.isInitializer = isInitializer
  f.closure = closure
  f.declaration = declaration
  f.call = 
    proc(interpreter: Interpreter, arguments: seq[BaseType]): BaseType =
      var environment = newEnvironment(f.closure)
      for i in 0 ..< f.declaration.parameters.len:
        environment.define(f.declaration.parameters[i].lexeme, arguments[i]) 
      try:
        interpreter.executeBlock(f.declaration.body, environment)
      except ReturnException as r:
        if isInitializer: return f.closure.getAt(0, "this")
        return r.value

      if isInitializer: return f.closure.getAt(0, "this")
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
  return Interpreter(globals: globals, environment: globals, locals: initTable[Expr, int]())

method evaluate*(self: Interpreter, expr: Expr): BaseType {.base.}=
  discard

method evaluate*(self: Interpreter, expr: Assign): BaseType =
  var value = evaluate(expr.value)

  if locals.contains(expr):
    var distance = locals[expr]
    environment.assignAt(distance, expr.name, value)
  else:
    globals.assign(expr.name, value)
    
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

proc lookUpVariable(self: Interpreter, name: Token, expr: Expr): BaseType =
  if locals.contains(expr):
    var distance = locals[expr]
    return environment.getAt(distance, name.lexeme)
  else:
    return globals.get(name)

method evaluate*(self: Interpreter, expr: Variable): BaseType =
  return lookUpVariable(expr.name, expr)

method evaluate*(self: Interpreter, expr: GetExpr): BaseType =
    var obj = evaluate(expr.obj)
    if obj of ClassInstance:
      return ClassInstance(obj).get(expr.name)
    
    raise newRuntimeError(expr.name, "Only instances have properties.")

method evaluate*(self: Interpreter, expr: SetExpr): BaseType =
  var obj = evaluate(expr.obj)
  if not(obj of ClassInstance):
    raise newRuntimeError(expr.name, "Only instances have fields.")
  var value = evaluate(expr.value)
  ClassInstance(obj).set(expr.name, value)
  return value

method evaluate*(self: Interpreter, expr: SuperExpr): BaseType =
  var distance = locals[expr]
  var superclass = ClassType(environment.getAt(distance, "super"))

  var obj = ClassInstance(environment.getAt(distance-1, "this"))

  var `method` = superclass.findMethod(obj, expr.method.lexeme)
  if `method` == nil:
    raise newRuntimeError(expr.method, "Undefined property '" & expr.`method`.lexeme & '.')

  return `method`

method evaluate*(self: Interpreter, expr: ThisExpr): BaseType =
  return lookUpVariable(expr.keyword, expr)

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
  var function = newFunction(stmt, environment, false)
  environment.define(stmt.name.lexeme, function)

method evaluate*(self: Interpreter, stmt: ReturnStmt) =
    var value: BaseType = nil
    if stmt.value != nil:
      value = evaluate(stmt.value)
    raise newReturnException(value)

method evaluate*(self: Interpreter, stmt: VarStmt) =
  var value: BaseType = nil
  if stmt.initializer != nil:
    value = evaluate(stmt.initializer)
  
  environment.define(stmt.name.lexeme, value)

method evaluate*(self: Interpreter, stmt: WhileStmt) =
    while isTruthy(evaluate(stmt.condition)):
      evaluate(stmt.body)

method evaluate*(self: Interpreter, stmt: ClassStmt) =
    var superclass: BaseType = nil
    if stmt.superclass != nil:
      superclass = evaluate(stmt.superclass)
      if not (superclass of ClassType):
        raise newRuntimeError(stmt.superclass.name, "Superclass must be a class.")

    environment.define(stmt.name.lexeme, nil)

    if stmt.superclass != nil:
      environment = newEnvironment(environment)
      environment.define("super", superclass)

    var methods = initTable[string, Function]()
    for m in stmt.methods:
      var function = newFunction(m, environment, m.name.lexeme == "init")
      if methods.contains(m.name.lexeme): methods.del(m.name.lexeme)
      methods.add(m.name.lexeme, function)

    var class = newClass(stmt.name.lexeme, ClassType(superclass), methods)
    
    if superclass != nil:
      environment = environment.enclosing
    
    environment.assign(stmt.name, class)

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

  if value of ClassType:
    return "<class " & ClassType(value).name & ">"

  if value of ClassInstance:
    return "<instance of class " & ClassInstance(value).class.name & ">"
