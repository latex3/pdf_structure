# Tagged PDF structure

This repo supports:

* a [luatex command line utility](./show-pdf-tags/) to extract and create representations of Tagged PDF structure element hierarchies as ASCII trees, XML, etc. The XML has an associated [RelaxNG schema](./RelaxNG/).

* an [XML stylesheet](./plantuml/) to transform the XML tree of Tagged PDF structure element hierarchies into simplified PlantUML tree widget (salt) visualization diagrams that can be included in AsciiDoctor and Metanorma documentation.

## Environment

These utilities can be used as standalone command line tools in Linux and Mac environments:

```sh
# Linux
sudo apt install texlive-binaries

# Mac
brew install mactex    # Warning! this is big (6.9GB) and slow to install!

git clone https://github.com/latex3/pdf_structure.git
cd show-pdf-tags

luatex show-pdf-tags.lua --help
luatex show-pdf-tags.lua --tree file.pdf
luatex show-pdf-tags.lua --xml file.pdf > file.xml

java -jar saxon-he-12.9.jar -xsl:../plantuml/plantuml.xsl file.xml > file.puml
```

License: MIT License
by the LaTeX Project Team
