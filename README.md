# reduce-xml.lua

```bash
./reduce-xml.lua prefix suffix $KFS_SYNTAX_HIGHLIGHTING/data/syntax/*.xml
```

# prepare_env

```bash
./prepare_env syntax...
```

# syntax trace highliter

```sh
cmake -DCMAKE_BUILD_TYPE=Release -DKSYNTAXHIGHLIGHTING_USE_GUI=OFF -DQRC_SYNTAX=OFF -S ${KSyntaxHighlightingPath} -B ${buildPath}
cmake --build ${buildPath} -- kate-syntax-highlighter
cp ${buildPath}/bin/kate-syntax-highlighter ${binPath}
```
