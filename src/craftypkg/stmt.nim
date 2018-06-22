import expr
import token

type
  Stmt* = ref object of RootObj
    
  BlockStmt* = ref object of Stmt
    statements*: seq[Stmt]

  ExprStmt* = ref object of Stmt
    expression*: Expr

  IfStmt* = ref object of Stmt
    condition*: Expr
    thenBranch*: Stmt
    elseBranch*: Stmt

  PrintStmt* = ref object of Stmt
    expression*: Expr

  VarStmt* = ref object of Stmt
    name*: Token
    initializer*: Expr

  WhileStmt* = ref object of Stmt
    condition*: Expr
    body*: Stmt

proc newBlockStmt*(s: seq[Stmt]): BlockStmt =
  return BlockStmt(statements: s)

proc newExprStmt*(e: Expr): ExprStmt =
  return ExprStmt(expression: e)

proc newIfStmt*(c: Expr, t: Stmt, e: Stmt): IfStmt =
  return IfStmt(condition: c, thenBranch: t, elseBranch: e)

proc newPrintStmt*(e: Expr): PrintStmt =
  return PrintStmt(expression: e)

proc newVarStmt*(n: Token, i: Expr): VarStmt =
  return VarStmt(name: n, initializer: i)

proc newWhileStmt*(c: Expr, b: Stmt): WhileStmt =
  return WhileStmt(condition: c, body: b)
