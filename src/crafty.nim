import os
import craftypkg / [ error, scanner, token ]

proc run(source: string) =
  var scanner = newScanner(source)
  var tokens = scanner.scanTokens()

  for tok in tokens:
      echo tok

proc runFile(path: string) =
  var content = readFile(path)
  run(content)

  if(hadError): quit(65)

proc runPrompt() =
  while true:
    stdout.write "> "
    run(stdin.readLine())

proc main() =
  var args = commandLineParams()
  if args.len > 1:
    echo "Usage: crafty [script]"
  elif args.len == 1:
    runFile(args[0])
  else:
    runPrompt()

main()
