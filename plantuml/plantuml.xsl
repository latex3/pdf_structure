<xsl:stylesheet version="3.0"
		xmlns:xs="http://www.w3.org/2001/XMLSchema"
		xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		>
<xsl:output method="text"/>


<xsl:template match="PDF">
[plantuml]
....
@startsalt
skinparam lengthAdjust spacingAndGlyphs
{
    {T!
    <xsl:apply-templates select="StructTreeRoot/*"/>
    }
}
@endsalt
....
</xsl:template>

<xsl:template match="*">
  <xsl:param name="level" select="1"/>
  <xsl:text>&#10;</xsl:text>
  <xsl:for-each select="xs:int(1) to xs:int($level)">+</xsl:for-each>
  <xsl:text> **</xsl:text>
  <xsl:value-of select="local-name()"/>
  <xsl:text>** </xsl:text>
  <xsl:text> | .</xsl:text>
  <xsl:apply-templates select="*">
    <xsl:with-param name="level" select="$level+1"/>
  </xsl:apply-templates>
</xsl:template>

</xsl:stylesheet>
