Script kit for easy testing and compiling of ksyntaxhighlighter6

# prepare_env

Creates a build folder with built script, utility script and symbolic links to the real repository.
The paths are hard-coded in `base` and `d`.

If environment variable `W` exists, worktree `w` will be used as base.

```bash
./prepare_env syntax...
```

# prepare_syntax

Adds syntax to an environment

```bash
./prepare_env syntax...
```

# reduce-xml.lua

```bash
./reduce-xml.lua prefix suffix $KFS_SYNTAX_HIGHLIGHTING/data/syntax/*.xml
```
