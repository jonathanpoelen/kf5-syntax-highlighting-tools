# graph.sh

```bash
graph.sh $KFS_SYNTAX_HIGHLIGHTING/data/syntax/xxxx.xml | dot -Tpng -o output.png
```

# reduce-xml.lua

```bash
reduce-xml.lua prefix suffix $KFS_SYNTAX_HIGHLIGHTING/data/syntax/*.xml
```

# prepare_env

```bash
d=$PWD
cd $KFS_SYNTAX_HIGHLIGHTING
$d/prepare_env
```