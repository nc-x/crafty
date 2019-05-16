import strformat

import token
import tokenType

var hadError* = false

# Forward Declaration
proc report(line: int, where: string, message: string)

# Proc
proc error*(line: int, message: string) =
  report(line, "", message)

proc error*(token: Token, message: string) =
  if token.tkType == EOF:
    report(token.line, " at end", message)
  else:
    report(token.line, " at '" & token.lexeme & "'", message)

proc report(line: int, where: string, message: string) =
  echo &"[line {$line}] Error{$where}: {$message}"
  hadError = true
