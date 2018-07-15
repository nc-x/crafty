import expr
import token

type
  Stmt* = ref object of RootObj
    
  BlockStmt* = ref object of Stmt
    statements*: seq[Stmt]

  ClassStmt* = ref object of Stmt
    name*: Token
    methods*: seq[FuncStmt]

  ExprStmt* = ref object of Stmt
    expression*: Expr

  FuncStmt* = ref object of Stmt
    name*: Token
    parameters*: seq[Token]
    body*: seq[Stmt]

  IfStmt* = ref object of Stmt
    condition*: Expr
    thenBranch*: Stmt
    elseBranch*: Stmt

  PrintStmt* = ref object of Stmt
    expression*: Expr

  ReturnStmt* = ref object of Stmt
    keyword*: Token
    value*: Expr

  VarStmt* = ref object of Stmt
    name*: Token
    initializer*: Expr

  WhileStmt* = ref object of Stmt
    condition*: Expr
    body*: Stmt

proc newBlockStmt*(s: seq[Stmt]): BlockStmt =
  return BlockStmt(statements: s)

proc newClassStmt*(n: Token, m: seq[FuncStmt]): ClassStmt =
  return ClassStmt(name: n, methods: m)

proc newExprStmt*(e: Expr): ExprStmt =
  return ExprStmt(expression: e)

proc newIfStmt*(c: Expr, t: Stmt, e: Stmt): IfStmt =
  return IfStmt(condition: c, thenBranch: t, elseBranch: e)

proc newFuncStmt*(n: Token, p: seq[Token], b: seq[Stmt]): FuncStmt =
  return FuncStmt(name: n, parameters: p, body: b)

proc newPrintStmt*(e: Expr): PrintStmt =
  return PrintStmt(expression: e)

proc newReturnStmt*(k: Token, v: Expr): ReturnStmt =
  return ReturnStmt(keyword: k, value: v)

proc newVarStmt*(n: Token, i: Expr): VarStmt =
  return VarStmt(name: n, initializer: i)

proc newWhileStmt*(c: Expr, b: Stmt): WhileStmt =
  return WhileStmt(condition: c, body: b)
