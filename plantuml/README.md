# PlantUML tree diagram generation

This XML stylesheet generates [PlantUML](https://plantuml.com/) tree widget diagram scripts from the XML output created by the [show-pdf-tags](../show-pdf-tags/show-pdf-tags.lua) LUA script. PlantUML tree widget diagrams are part of [Salt (wireframe) diagrams](https://plantuml.com/salt#759fb83534bc53b0). This provides a simple non-technical visualization of the PDF tag tree structure.

This XML stylesheet is XSLT v3, so standard XML tools may not work. The free Java-based SaxonJ-HE tool available from <https://github.com/Saxonica/Saxon-HE/> can be used as follows (all platforms, requires Java, change Saxon version number as appropriate):

```sh
java -jar saxon-he-12.9.jar -xsl:plantuml.xsl file.xml > file.puml
```

Saxon command line options are [documented here](https://www.saxonica.com/documentation12/index.html#!using-xsl/commandline).

The PlantUML script output is enclosed in [AsciiDoctor-diagram](https://docs.asciidoctor.org/diagram-extension/latest/diagram_types/plantuml/) / [Metanorma](https://www.metanorma.org/author/topics/blocks/diagrams/#plantuml) markup for easy inclusion into documentation, which will need to be removed for previewing.

PlantUML scripts can be previewed with the [online PlantUML tool](https://www.plantuml.com/plantuml/uml/SoWkIImgAKxCAU6gvb9Gg0xXKW02RGKjhQ3y_18jBGWNnFVBJqbLS8I9W8MSCp9pKXJoqnIGv6gvQhaSKlDIG4O20000) or in [VSCode](https://code.visualstudio.com/) using the [PlantUML extension](https://marketplace.visualstudio.com/items?itemName=jebbs.plantuml).

License: MIT License
by the LaTeX Project Team
