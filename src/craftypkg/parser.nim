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
proc unary(self: var Parser): Expr
proc primary(self: var Parser): Expr
proc consume(self: var Parser, tktype: TokenType, message: string): Token
proc error(self: var Parser, token: Token, message: string): ParseError
proc synchronize(self: var Parser)
proc parseBlock(self: var Parser): seq[Stmt]
proc statement(self: var Parser): Stmt
proc printStatement(self: var Parser): Stmt
proc expressionStatement(self: var Parser): Stmt
proc declaration(self: var Parser): Stmt
proc varDeclaration(self: var Parser): Stmt
proc parse*(self: var Parser): seq[Stmt]

# Proc

proc assignment(self: var Parser): Expr =
  var expr = equality()

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

  return primary()

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

proc statement(self: var Parser): Stmt =
  if match(PRINT):
    return printStatement()
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

proc declaration(self: var Parser): Stmt =
  try:
    if match(VAR):
      return varDeclaration()
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
