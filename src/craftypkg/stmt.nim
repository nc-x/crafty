import expr
import token

type
  Stmt* = ref object of RootObj
    
  BlockStmt* = ref object of Stmt
    statements*: seq[Stmt]

  ExprStmt* = ref object of Stmt
    expression*: Expr

  PrintStmt* = ref object of Stmt
    expression*: Expr

  VarStmt* = ref object of Stmt
    name*: Token
    initializer*: Expr

proc newBlockStmt*(s: seq[Stmt]): BlockStmt =
  return BlockStmt(statements: s)

proc newExprStmt*(e: Expr): ExprStmt =
  return ExprStmt(expression: e)

proc newPrintStmt*(e: Expr): PrintStmt =
  return PrintStmt(expression: e)

proc newVarStmt*(n: Token, i: Expr): VarStmt =
  return VarStmt(name: n, initializer: i)
