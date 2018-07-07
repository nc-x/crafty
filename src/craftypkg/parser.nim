{.this: self.}

import token
import tokentype
import expr
import literaltype
import stmt
from error import nil

type
  Parser* = object
    tokens*: seq[Token]
    current*: int

  ParseError* = ref object of Exception

proc newParser*(tokens: seq[Token]): Parser =
  return Parser(tokens: tokens, current: 0)

# Forward Declaration
proc andExpr(self: var Parser): Expr
proc orExpr(self: var Parser): Expr
proc assignment(self: var Parser): Expr
proc expression(self: var Parser): Expr
proc equality(self: var Parser): Expr
proc match(self: var Parser, types: varargs[TokenType]): bool
proc check(self: var Parser, tokentype: TokenType): bool
proc advance(self: var Parser): Token
proc peek(self: var Parser): Token
proc isAtEnd(self: var Parser): bool
proc previous(self: var Parser): Token
proc comparison(self: var Parser): Expr
proc addition(self: var Parser): Expr
proc multiplication(self: var Parser): Expr
proc call(self: var Parser): Expr
proc unary(self: var Parser): Expr
proc primary(self: var Parser): Expr
proc consume(self: var Parser, tktype: TokenType, message: string): Token
proc error(self: var Parser, token: Token, message: string): ParseError
proc synchronize(self: var Parser)
proc parseBlock(self: var Parser): seq[Stmt]
proc ifStatement(self: var Parser): Stmt
proc whileStatement(self: var Parser): Stmt
proc forStatement(self: var Parser): Stmt
proc statement(self: var Parser): Stmt
proc printStatement(self: var Parser): Stmt
proc expressionStatement(self: var Parser): Stmt
proc declaration(self: var Parser): Stmt
proc varDeclaration(self: var Parser): Stmt
proc parse*(self: var Parser): seq[Stmt]

# Proc

proc andExpr(self: var Parser): Expr =
  var expr = equality()

  while match(AND):
    var operator = previous()
    var right = equality()
    expr = newLogical(expr, operator, right)

  return expr

proc orExpr(self: var Parser): Expr =
  var expr = andExpr()

  while match(OR):
    var operator = previous()
    var right = andExpr()
    expr = newLogical(expr, operator, right)

  return expr

proc assignment(self: var Parser): Expr =
  var expr = orExpr()

  if match(EQUAL):
    var equals = previous()
    var value = assignment()

    if expr of Variable:
      var name = Variable(expr).name
      return newAssign(name, value)
    
    error.error(equals, "Invalid assignment target.")

  return expr

proc expression(self: var Parser): Expr =
  return assignment()

proc equality(self: var Parser): Expr =
  var expr = comparison()
  
  while match(BANG_EQUAL, EQUAL_EQUAL):
    var operator = previous()
    var right = comparison()
    expr = newBinary(expr, operator, right)

  return expr

proc match(self: var Parser, types: varargs[TokenType]): bool =
  for ty in types:
    if check(ty):
      discard advance()
      return true
  
  return false

proc check(self: var Parser, tokentype: TokenType): bool =
  if isAtEnd(): return false
  return peek().tkType == tokenType

proc advance(self: var Parser): Token =
  if not isAtEnd(): current += 1
  return previous()

proc isAtEnd(self: var Parser): bool =
  return peek().tkType == EOF

proc peek(self: var Parser): Token =
  return tokens[current]

proc previous(self: var Parser): Token =
  return tokens[current - 1]

proc comparison(self: var Parser): Expr =
  var expr = addition()

  while match(GREATER, GREATER_EQUAL, LESS, LESS_EQUAL):
    var operator = previous()
    var right = addition()

    expr = newBinary(expr, operator, right)

  return expr

proc addition(self: var Parser): Expr =
  var expr = multiplication()

  while match(MINUS, PLUS):
    var operator = previous()
    var right = multiplication()
    
    expr = newBinary(expr, operator, right)
  
  return expr


proc multiplication(self: var Parser): Expr =
  var expr = unary()

  while match(SLASH, STAR):
    var operator = previous()
    var right = unary()

    expr = newBinary(expr, operator, right)

  return expr

proc unary(self: var Parser): Expr =
  if match(BANG, MINUS):
    var operator = previous()
    var right = unary()

    return newUnary(operator, right)

  return call()

proc finishCall(self: var Parser, callee: Expr): Expr =
  var arguments: seq[Expr]

  if not check(RIGHT_PAREN):
    arguments.add(expression())

    while match(COMMA):
      if arguments.len >= 8:
        error.error(peek(), "Cannot have more than 8 arguments.")
      arguments.add(expression())
  
  var paren = consume(RIGHT_PAREN, "Expect ')' after arguments.")

  return newCall(callee, paren, arguments)

proc call(self: var Parser): Expr =
  var expr = primary()

  while true:
    if match(LEFT_PAREN):
      expr = finishCall(expr)
    else:
      break

  return expr

proc primary(self: var Parser): Expr =
  if match(FALSE): return newLiteral(newBoolLit(false))
  if match(TRUE): return newLiteral(newBoolLit(true))
  if match(NIL): return newLiteral(newNilLit())

  if match(NUMBER, STRING):
    return newLiteral(previous().literal)

  if match(IDENTIFIER):
    return newVariable(previous())
  
  if match(LEFT_PAREN):
    var expr = expression()
    discard consume(RIGHT_PAREN, "Expect ')' after expression")
    return newGrouping(expr)
  
  raise error(peek(), "Expect expression.")

proc consume(self: var Parser, tktype: TokenType, message: string): Token =
  if check(tktype): return advance()

  raise error(peek(), message)

proc error(self: var Parser, token: Token, message: string): ParseError =
  error.error(token, message)

  return ParseError()

proc synchronize(self: var Parser) =
  discard advance()

  while not isAtEnd():
    if previous().tkType == SEMICOLON: return

    case peek().tkType
    of CLASS, FUN, VAR, FOR, IF, WHILE, PRINT, RETURN: return
    else: discard

    discard advance()

proc parseBlock(self: var Parser): seq[Stmt] =
  var statements: seq[Stmt]

  while not check(RIGHT_BRACE) and not isAtEnd():
    statements.add(declaration())

  discard consume(RIGHT_BRACE, "Expect '}' after block.")
  return statements

proc ifStatement(self: var Parser): Stmt =
  discard consume(LEFT_PAREN, "Expect '(' after 'if'.")
  var condition = expression()
  discard consume(RIGHT_PAREN, "Expect ')' after if condition.")

  var thenBranch = statement()
  var elseBranch: Stmt = nil

  if match(ELSE):
    elseBranch = statement()

  return newIfStmt(condition, thenBranch, elseBranch)

proc whileStatement(self: var Parser): Stmt =
  discard consume(LEFT_PAREN, "Expect '(' after 'while'.")
  var condition = expression()
  discard consume(RIGHT_PAREN, "Expect ')' after condition.")
  var body = statement()

  return newWhileStmt(condition, body)

proc forStatement(self: var Parser): Stmt =
  discard consume(LEFT_PAREN, "Expect '(' after 'for'.")

  var initializer: Stmt
  if match(SEMICOLON):
    initializer = nil
  elif match(VAR):
    initializer = varDeclaration()
  else:
    initializer = expressionStatement()

  var condition: Expr = nil
  if not check(SEMICOLON):
    condition = expression()
  
  discard consume(SEMICOLON, "Expect ';' after loop condition.")

  var increment: Expr = nil
  if not check(RIGHT_PAREN):
    increment = expression()
  discard consume(RIGHT_PAREN, "Expect ')' after for clauses.")

  var body = statement()

  if increment != nil:
    body = newBlockStmt(@[body, newExprStmt(increment)])

  if condition == nil:
    condition = newLiteral(newBoolLit(true))
  body = newWhileStmt(condition, body)

  if initializer != nil:
    body = newBlockStmt(@[initializer, body])

  return body

proc statement(self: var Parser): Stmt =
  if match(FOR):
    return forStatement()
  if match(IF):
    return ifStatement()
  if match(PRINT):
    return printStatement()
  if match(WHILE):
    return whileStatement()
  if match(LEFT_BRACE):
    return newBlockStmt(parseBlock())

  return expressionStatement()

proc printStatement(self: var Parser): Stmt =
  var value = expression()
  discard consume(SEMICOLON, "Expect ';' after value.")
  return newPrintStmt(value)

proc expressionStatement(self: var Parser): Stmt =
  var expr = expression()
  discard consume(SEMICOLON, "Expect ';' after expression.")
  return newExprStmt(expr)

proc function(self: var Parser, kind: string): FuncStmt =
  var name = consume(IDENTIFIER, "Expect " & kind & " name.")
  discard consume(LEFT_PAREN, "Expect '(' after " & kind & " name.")

  var parameters: seq[Token]
  if not check(RIGHT_PAREN):
    parameters.add(consume(IDENTIFIER, "Expect parameter name."))

    while match(COMMA):
      if parameters.len >= 8:
        error.error(peek(), "Cannot have more than 8 parameters.")
      parameters.add(consume(IDENTIFIER, "Expect parameter name."))
    
  discard consume(RIGHT_PAREN, "Expect ')' after parameters.")

  discard consume(LEFT_BRACE, "Expect '{' before " & kind & " body.")
  var body = parseBlock()
  return newFuncStmt(name, parameters, body)

proc declaration(self: var Parser): Stmt =
  try:
    if match(FUN): return function("function")
    if match(VAR): return varDeclaration()
    return statement()
  except ParseError:
    synchronize()
    return nil

proc varDeclaration(self: var Parser): Stmt =
  var name = consume(IDENTIFIER, "Expect variable name")

  var initializer: Expr
  if match(EQUAL):
    initializer = expression()
  else:
    initializer = newLiteral(newNilLit())
    
  discard consume(SEMICOLON, "Expect ';' after variable declaration.")
  return newVarStmt(name, initializer)


proc parse*(self: var Parser): seq[Stmt] =
  var statements: seq[Stmt]
  while not isAtEnd():
    statements.add(declaration())
  
  return statements
