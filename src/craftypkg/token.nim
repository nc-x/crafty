import tokenType
import literalType
import strformat

type
  Token* = object
    tkType*: TokenType
    lexeme*: string
    literal*: LiteralType
    line*: int

proc newToken*(tkType: TokenType, lexeme: string, literal: LiteralType, line: int): Token =
  return Token(tkType: tkType, lexeme: lexeme, literal: literal, line: line)

proc `$`*(self: Token): string =
  return &"Line: {self.line}, TokenType: {self.tkType}, Lexeme: {self.lexeme}, Literal: {$self.literal}"