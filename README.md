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
lib=$(readlink -e ${buildPath}/bin/libKF5SyntaxHighlighting.so)
strip ${buildPath}/bin/kate-syntax-highlighter $lib
cp ${buildPath}/bin/kate-syntax-highlighter ${binPath}
cp $lib ${binPath}/libKF5SyntaxHighlighting.so
echo "#\!/usr/bin/sh
LD_PRELOAD=${binPath}/libKF5SyntaxHighlighting.so ${binPath}/kate-syntax-highlighter \"\$@\"
" > ${binPath}/kate-syntax-highlighter.sh
```
