{.this: self.}

import strutils
import tables

import token
import tokenType
import literalType
import error

type
  Scanner = object
    source: string
    tokens: seq[Token]
    start: int
    current: int
    line: int
    keywords: Table[string, TokenType]

proc newScanner*(source: string): Scanner =
  return Scanner(
    source: source,
    start: 0,
    current: 0,
    line: 1,
    keywords: {
    "and" : AND,
    "class": CLASS,
    "else": ELSE,
    "false": FALSE,
    "for": FOR,
    "fun": FUN,
    "if": IF,
    "nil": NIL,
    "or": OR,
    "print": PRINT,
    "return": RETURN,
    "super": SUPER,
    "this": THIS,
    "true": TRUE,
    "var": VAR,
    "while": WHILE,
    }.toTable())

# Forward Declaration
proc isAtEnd(self: Scanner): bool
proc scanToken(self: var Scanner)
proc advance(self: var Scanner): char 
proc addToken(self: var Scanner, tkType: TokenType)
proc addToken(self: var Scanner, tkType: TokenType, literal: LiteralType)
proc match(self: var Scanner, expected: char): bool 
proc peek(self: Scanner): char
proc tok_string(self: var Scanner)
proc isDigit(c: char): bool
proc tok_number(self: var Scanner)
proc peekNext(self: var Scanner): char
proc tok_identifier(self: var Scanner)
proc isAlpha(c: char): bool
proc isAlphaNumeric(c: char): bool

# Procs

proc scanTokens*(self: var Scanner): seq[Token] =
  while not isAtEnd():
    start = current
    scanToken()

  tokens.add(newToken(EOF, "", newNilLit(), line))
  return tokens

proc isAtEnd(self: Scanner): bool =
  return current >= source.len()

proc scanToken(self: var Scanner) =
  var c = advance()

  case c
  of '(': addToken(LEFT_PAREN)
  of ')': addToken(RIGHT_PAREN)
  of '{': addToken(LEFT_BRACE)
  of '}': addToken(RIGHT_BRACE)
  of ',': addToken(COMMA)
  of '.': addToken(DOT)
  of '-': addToken(MINUS)
  of '+': addToken(PLUS)
  of ';': addToken(SEMICOLON)
  of '*': addToken(STAR)
  of '!': addToken(if match('='): BANG_EQUAL else: BANG)
  of '=': addToken(if match('='): EQUAL_EQUAL else: EQUAL)
  of '<': addToken(if match('='): LESS_EQUAL else: LESS)
  of '>': addToken(if match('='): GREATER_EQUAL else: GREATER)
  of '/':
    if match('/'):
      while peek() != '\n' and not isAtEnd(): discard advance()
    else:
      addToken(SLASH)
  of ' ', '\r', '\t': discard
  of '\n': line += 1

  of '"': tok_string()

  else:
    if isDigit(c):
          tok_number()
    elif isAlpha(c):
      tok_identifier()
    else:
      error(line, "Unexpected Character " & c)
    

proc advance(self: var Scanner): char =
  current += 1
  return source[current-1]

proc addToken(self: var Scanner, tkType: TokenType) =
  addToken(tkType, newNilLit())

proc addToken(self: var Scanner, tkType: TokenType, literal: LiteralType) =
  var text = source[start ..< current]
  tokens.add(newToken(tkType, text, literal, line))

proc match(self: var Scanner, expected: char): bool =
  if isAtEnd(): return false
  if source[current] != expected: return false

  current += 1
  return true

proc peek(self: Scanner): char =
  if isAtEnd(): return '\0'
  return source[current]

proc tok_string(self: var Scanner) =
  while peek() != '"' and not isAtEnd():
    if peek() == '\n': line += 1
    discard advance()

  if isAtEnd():
    error(line, "Unterminated string")
    return
  
  discard advance()

  let value = source[start+1 ..< current-1]
  addToken(STRING, newStrLit(value))

proc isDigit(c: char): bool =
  return c >= '0' and c <= '9'

proc tok_number(self: var Scanner) =
  while isDigit(peek()): discard advance()

  if peek() == '.' and isDigit(peekNext()):
    discard advance()

    while isDigit(peek()): discard advance()

  addToken(NUMBER, newNumLit(parseFloat(source[start ..< current])))

proc peekNext(self: var Scanner): char =
  if current + 1 >= source.len: return '\0'
  return source[current + 1] 

proc tok_identifier(self: var Scanner) =
  while isAlphaNumeric(peek()): discard advance()

  var text = source[start ..< current]

  if keywords.contains(text): addToken(keywords[text])
  else: addToken(IDENTIFIER) 
  
proc isAlpha(c: char): bool =
  return (c >= 'a' and c <= 'z') or
           (c >= 'A' and c <= 'Z') or
            c == '_'

proc isAlphaNumeric(c: char): bool =
  return isAlpha(c) or isDigit(c);
