# Print structure element hierarchy for Tagged PDF

show-pdf-tags version 1.4

Print a plain text or XML tree representing the structure of tagged PDF files.

Usage:

    show-pdf-tags <options> <filename>.pdf

The tree output format is documented in show-pdf-tags-format.pdf.

The XML format shows (mostly) the same information and may be validated with
the RelaxNG schema included in the distribution.

The options are

```
Options
  --help|-h        show this help
  --version|-v     show the current version
  --tree (default) show as tree
  --xml            show as XML
  --table          show Lua table structure
  --map            Follow role mapping (xml printer)
  --w3c-           Add - to w3c namespaces to force browser tree display
```

License: MIT License
by the LaTeX Project Team
