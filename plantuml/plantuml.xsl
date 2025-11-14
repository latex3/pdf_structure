<xsl:stylesheet version="3.0"
		xmlns:xs="http://www.w3.org/2001/XMLSchema"
		xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		xmlns:p="data:,plantunl"
		>
<xsl:output method="text"/>

<xsl:param name="rootelem"/>
<xsl:param name="occurrence" select="1"/>
<xsl:param name="maxdepth" select="1000"/>
<xsl:param name="maxsiblings" select="1000"/>
<xsl:param name="elidecontent"/>
<xsl:param name="maxattlength" select="20"/>

<xsl:variable name="elide-elems" select="tokenize($elidecontent,'[ ,]+')"/>
<xsl:variable name="maxsiblingsnum" select="xs:int($maxsiblings)"/>

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

<xsl:function name="p:attvalue">
  <xsl:param name="atnode"/>
  <xsl:choose>
    <xsl:when test="matches($atnode,'^[0-9][0-9.]*$')">
      <xsl:value-of select="$atnode"/>
    </xsl:when>
    <xsl:when test="matches($atnode,'^\{.*\}$')">
      <xsl:value-of select="replace(translate($atnode,'{}','[]'),', ',' ')"/>
    </xsl:when>
    <xsl:otherwise>
      <xsl:text>"</xsl:text>
      <xsl:value-of select="substring(replace($atnode,'[{}|]',''),0,xs:int($maxattlength))"/>
      <xsl:text>"</xsl:text>
    </xsl:otherwise>
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
	    <xsl:apply-templates select="StructTreeRoot/*[position() le $maxsiblingsnum]"/>
	    <xsl:if test="*[position() gt $maxsiblingsnum]">
	      <xsl:text>&#10;+</xsl:text>
	      <xsl:text> **...** | . | .</xsl:text>
	    </xsl:if>
      </xsl:otherwise>
    </xsl:choose>
      }
}
@endsalt
....
</xsl:template>

<xsl:template match="*">
  <xsl:param name="level" select="xs:int(1)"/>
  <xsl:text>&#10;</xsl:text>
  <xsl:for-each select="xs:int(1) to xs:int($level)">+</xsl:for-each>
  <xsl:text> **</xsl:text>
  <xsl:value-of select="local-name()"/>
  <xsl:text>** | </xsl:text>
  <xsl:choose>
    <xsl:when test="empty(@* except (@rolemaps-to,@rolemapped-from))">.</xsl:when>
    <xsl:otherwise>
      <xsl:for-each select="(@* except (@rolemaps-to,@rolemapped-from))[normalize-space(.)]">
	<xsl:value-of select="'**',p:attname(local-name()),'**=',
			     p:attvalue(.), 
			      ' '"
		      separator=""/>
      </xsl:for-each>
    </xsl:otherwise>
  </xsl:choose>
  <xsl:choose>
    <xsl:when test="@rolemaps-to">
      <xsl:value-of select="' | maps to **',@rolemaps-to,'**'" separator=""/>
    </xsl:when>
    <xsl:when test="@rolemapped-from">
      <xsl:value-of select="' | mapped from **',replace(@rolemapped-from,'.*:',''),'**'" separator=""/>
    </xsl:when>
    <xsl:otherwise>
        <xsl:text> | .</xsl:text>
    </xsl:otherwise>
  </xsl:choose>
  <xsl:choose>
    <xsl:when test="local-name()=$elide-elems or
		    (exists(*) and $level=xs:int($maxdepth))">
      <xsl:text>&#10;+</xsl:text>
      <xsl:for-each select="xs:int(1) to xs:int($level)">+</xsl:for-each>
      <xsl:text> **...** | . | .</xsl:text>
    </xsl:when>
    <xsl:otherwise>
      <xsl:apply-templates select="*[position() le $maxsiblingsnum]">
	<xsl:with-param name="level" select="xs:int($level+1)"/>
      </xsl:apply-templates>
      <xsl:if test="*[position() gt $maxsiblingsnum]">
	<xsl:text>&#10;+</xsl:text>
	<xsl:for-each select="xs:int(1) to xs:int($level)">+</xsl:for-each>
	<xsl:text> **...** | . | .</xsl:text>
      </xsl:if>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

</xsl:stylesheet>
