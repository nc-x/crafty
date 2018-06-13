import strformat

import token

type
  RuntimeError* = ref object of Exception
    token: Token

var hadRuntimeError* = false


proc newRuntimeError*(token: Token, msg: string): RuntimeError =
  return RuntimeError(token: token, msg: msg)

proc runtimeError*(error: RuntimeError) =
  echo &"{error.msg}\n[line {error.token.line}]"
  hadRuntimeError = true
