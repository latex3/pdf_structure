<xsl:stylesheet version="3.0"
		xmlns:xs="http://www.w3.org/2001/XMLSchema"
		xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		xmlns:p="data:,plantunl"
		>
<xsl:output method="text"/>

<xsl:param name="rootelem"/>
<xsl:param name="occurrence" select="1"/>
<xsl:param name="maxdepth"/>
<xsl:param name="elidecontent"/>

<xsl:variable name="elide-elems" select="tokenize($elidecontent,'[ ,]+')"/>

<xsl:function name="p:attname">
  <xsl:param name="at"/>
  <xsl:choose>
    <xsl:when test="$at='id'">ID</xsl:when>
    <xsl:when test="$at='class'">C</xsl:when>
    <xsl:when test="$at='revision'">R</xsl:when>
    <xsl:when test="$at='title'">T</xsl:when>
    <xsl:when test="$at='expansion'">E</xsl:when>
    <xsl:when test="$at='phoneme'">Phoneme</xsl:when>
    <xsl:when test="$at='phonetic-alphabet'">PhoneticAlphabet</xsl:when>
    <xsl:when test="$at='title'">AF</xsl:when>
    <xsl:when test="$at='lang'">Lang</xsl:when>
    <xsl:when test="$at='actualtext'">ActualText</xsl:when>
    <xsl:when test="$at='alt'">Alt</xsl:when>
    <xsl:otherwise><xsl:value-of select="$at"/></xsl:otherwise>
  </xsl:choose>
</xsl:function>

<xsl:template match="PDF">
[plantuml]
....
@startsalt
skinparam lengthAdjust spacingAndGlyphs
{
    {T!
    <xsl:choose>
      <xsl:when test="$rootelem">
	<xsl:apply-templates select="/descendant::*[local-name(.)=$rootelem][xs:int($occurrence)]"/>
      </xsl:when>
      <xsl:otherwise>
	    <xsl:apply-templates select="StructTreeRoot/*"/>
      </xsl:otherwise>
    </xsl:choose>
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
  <xsl:text>** | </xsl:text>
  <xsl:choose>
    <xsl:when test="empty(@*)">.</xsl:when>
    <xsl:otherwise>
      <xsl:for-each select="@*[normalize-space(.)]">
	<xsl:value-of select="'**',p:attname(local-name()),'**=',
			      substring(replace(.,'[{}]',''),0,20),
			      ' '"
		      separator=""/>
      </xsl:for-each>
    </xsl:otherwise>
  </xsl:choose>
  <xsl:text> | .</xsl:text>
  <xsl:choose>
    <xsl:when test="local-name()=$elide-elems">
      <xsl:text>&#10;+</xsl:text>
      <xsl:for-each select="xs:int(1) to xs:int($level)">+</xsl:for-each>
      <xsl:text> **. . .** | .</xsl:text>
    </xsl:when>
    <xsl:otherwise>
      <xsl:apply-templates select="*">
	<xsl:with-param name="level" select="$level+1"/>
      </xsl:apply-templates>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

</xsl:stylesheet>
