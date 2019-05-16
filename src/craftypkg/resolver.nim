{.this: self.}

import tables
import stmt
import expr
import token
import error
import objhashes
import interpreterObj
import literalType

type
  Resolver* = ref object of RootObj
    interpreter: Interpreter
    scopes: seq[Table[string, bool]]
    currentFunction: FunctionType
    currentClass: ClassType

  FunctionType = enum
    NONE, FUNCTION, INITIALIZER, METHOD

  ClassType {.pure.} = enum
    NONE, CLASS, SUBCLASS

proc newResolver*(i: Interpreter): Resolver =
  Resolver(interpreter: i, currentFunction: NONE, currentClass: ClassType.NONE)

method resolve(self: var Resolver, stmt: Stmt) {.base.} = discard
method resolve(self: var Resolver, expr: Expr) {.base.} = discard

proc resolve*(self: var Resolver, statements: seq[Stmt]) =
  for statement in statements:
    resolve(statement)

proc beginScope(self: var Resolver) =
  scopes.add(initTable[string, bool]())

proc endScope(self: var Resolver) =
  discard scopes.pop()

proc declare(self: var Resolver, name: Token) =
  if scopes.len == 0: return
  if scopes[scopes.len-1].contains(name.lexeme): error.error(name, "Variable with this name already declared in this scope.")
  scopes[scopes.len-1].add(name.lexeme, false)

proc define(self: var Resolver, name: Token) =
  if scopes.len == 0: return
  if scopes[scopes.len-1].contains(name.lexeme):
    scopes[scopes.len-1].del(name.lexeme)
  scopes[scopes.len-1].add(name.lexeme, true)

proc resolveLocal(self: var Resolver, expr: Expr, name: Token) =
  for i in countdown(scopes.len-1, 0):
    if scopes[i].contains(name.lexeme):
      interpreter.resolve(expr, scopes.len - 1 - i)
      return

proc resolveFunction(self: var Resolver, function: FuncStmt, fnType: FunctionType) =
  var enclosingFunction = currentFunction
  currentFunction = fnType
  beginScope()
  for param in function.parameters:
    declare(param)
    define(param)
  resolve(function.body)
  endScope()
  currentFunction = enclosingFunction

method resolve(self: var Resolver, stmt: BlockStmt) =
  beginScope()
  resolve(stmt.statements)
  endScope()

method resolve(self: var Resolver, stmt: VarStmt) =
  declare(stmt.name)
  if stmt.initializer != nil:
    resolve(stmt.initializer)
  define(stmt.name)

method resolve(self: var Resolver, expr: Variable) =
  if not (scopes.len == 0) and scopes[scopes.len-1].getOrDefault(expr.name.lexeme, true) == false:
    error.error(expr.name, "Cannot read local variable in its own initializer.")
  resolveLocal(expr, expr.name)

method resolve(self: var Resolver, expr: Assign) =
  resolve(expr.value)
  resolveLocal(expr, expr.name)

method resolve(self: var Resolver, stmt: FuncStmt) =
  declare(stmt.name)
  define(stmt.name)
  resolveFunction(stmt, FUNCTION)

method resolve(self: var Resolver, stmt: ExprStmt) =
  resolve(stmt.expression)

method resolve(self: var Resolver, stmt: IfStmt) =
  resolve(stmt.condition)
  resolve(stmt.thenBranch)
  if stmt.elseBranch != nil: resolve(stmt.elseBranch)

method resolve(self: var Resolver, stmt: PrintStmt) =
  resolve(stmt.expression)

method resolve(self: var Resolver, stmt: ReturnStmt) =
  if (currentFunction == NONE):
    error.error(stmt.keyword, "Cannot return from top-level code.")
  if stmt.value != nil:
    if currentFunction == INITIALIZER:
      error.error(stmt.keyword, "Cannot return a value from an initializer.")
    resolve(stmt.value)

method resolve(self: var Resolver, stmt: WhileStmt) =
  resolve(stmt.condition)
  resolve(stmt.body)

method resolve(self: var Resolver, stmt: ClassStmt) =
  var enclosingClass = currentClass
  currentClass = ClassType.CLASS
  declare(stmt.name)

  if stmt.superclass != nil:
    currentClass = ClassType.SUBCLASS
    resolve(stmt.superclass)

  define(stmt.name)

  if stmt.superclass != nil:
    beginScope()
    scopes[scopes.len-1].add("super", true)

  beginScope()
  scopes[scopes.len-1].add("this", true)

  for m in stmt.methods:
    var declaration = METHOD
    if m.name.lexeme == "init":
      declaration = INITIALIZER
    resolveFunction(m, declaration)

  endScope()

  if stmt.superclass != nil: endScope()

  currentClass = enclosingClass

method resolve(self: var Resolver, expr: Binary) =
  resolve(expr.left)
  resolve(expr.right)

method resolve(self: var Resolver, expr: Call) =
  resolve(expr.callee)
  for argument in expr.arguments:
    resolve(argument)

method resolve(self: var Resolver, expr: Grouping) =
  resolve(expr.expression)

method resolve(self: var Resolver, expr: Literal) =
  discard

method resolve(self: var Resolver, expr: Logical) =
  resolve(expr.left)
  resolve(expr.right)

method resolve(self: var Resolver, expr: Unary) =
  resolve(expr.right)

method resolve(self: var Resolver, expr: GetExpr) =
  resolve(expr.obj)

method resolve(self: var Resolver, expr: SetExpr) =
  resolve(expr.value)
  resolve(expr.obj)

method resolve(self: var Resolver, expr: ThisExpr) =
  if currentClass == ClassType.NONE:
    error.error(expr.keyword, "Cannot use 'this' outside of a class.")
  resolveLocal(expr, expr.keyword)

method resolve(self: var Resolver, expr: SuperExpr) =
  if currentClass == ClassType.NONE:
    error.error(expr.keyword, "Cannot use 'super' outside of a class.")
  elif currentClass != ClassType.SUBCLASS:
    error.error(expr.keyword, "Cannot use 'super' in a class with no superclass.")
  resolveLocal(expr, expr.keyword)
