<xsl:stylesheet version="3.0"
		xmlns:xs="http://www.w3.org/2001/XMLSchema"
		xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		xmlns:p="data:,plantuml"
		exclude-result-prefixes="xs p"
		>
<xsl:output method="text"/>

<xsl:param name="rootelem"/>
<xsl:param name="occurrence" select="1"/>
<xsl:param name="maxdepth" select="1000"/>
<xsl:param name="maxsiblings" select="1000"/>
<xsl:param name="elidecontent"/>
<xsl:param name="omitatts"/>
<xsl:param name="showrolemap" select="'yes'"/>
<xsl:param name="showemptyatts" select="'no'"/>
<xsl:param name="maxattlength" select="20"/>
<xsl:param name="nsprefix"/>
<xsl:param name="nsurl"/>
<xsl:param name="descname"/>
<xsl:param name="destext"/>
<xsl:param name="namestyle" select="0"/>
<!--
 style  with role-map               without
    0   latex:section -> pdf2:H1     pdf2:H1
    1   latex:section -> H1          pdf2:H1
    2   section -> H1                H1
    3   section                      H1
    4   H1                           H1
-->
<xsl:param name="maxstringlength" select="0"/>

<xsl:variable name="elide-elems" select="tokenize($elidecontent,'[ ,]+')"/>
<xsl:variable name="omit-atts" select="tokenize($omitatts,'[ ,]+')"/>
<xsl:variable name="show-empty" select="matches($showemptyatts,'true|yes')" as="xs:boolean"/>
<xsl:variable name="maxsiblingsnum" select="xs:int($maxsiblings)"/>
<xsl:variable name="namestylenum" select="xs:int($namestyle)"/>
<xsl:variable name="maxstringlengthnum" select="xs:int($maxstringlength)"/>

<xsl:variable name="nsprefixseq" select="tokenize($nsprefix,'\s+')"/>
<xsl:variable name="nsurlseq" select="tokenize($nsurl,'\s+')"/>

<xsl:variable  name="namespacemap">
  <xsl:for-each select="distinct-values(//*/namespace::*)">
    <n uri="{.}">
      <xsl:choose>
	<xsl:when test=".=$nsurlseq">
	  <xsl:value-of select="$nsprefixseq[index-of($nsurlseq,current())]"/>
	</xsl:when>
	<xsl:when test=".='http://www.w3.org/XML/1998/namespace'">xml</xsl:when>
	<xsl:when test=".='http://iso.org/pdf/ssn'">pdf1</xsl:when>
	<xsl:when test=".='http://iso.org/pdf2/ssn'">pdf2</xsl:when>
	<xsl:when test=".='http://www.w3.org/1998/Math/MathML'">mml</xsl:when>
	<xsl:when test=".='https://www.latex-project.org/ns/dflt'">latex</xsl:when>
	<xsl:otherwise>
	  <xsl:value-of select="'n',position()" separator=""/>
	</xsl:otherwise>
      </xsl:choose>
    </n>
  </xsl:for-each>
</xsl:variable>

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
    <xsl:when test="$at='af'">AF</xsl:when>
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
    <xsl:when test="local-name($atnode)=
		    ('TextAlign','Placement','WritingMode','ListNumbering','TextDecorationType','TextPosition')
		    and matches($atnode,'^[A-Z][a-z]*$')">
      <xsl:value-of select="'/',$atnode" separator=""/>
    </xsl:when>
    <xsl:when test="matches($atnode,'^\{.*\}$')">
      <xsl:value-of select="replace(translate($atnode,'{}','[]'),', ',' ')"/>
    </xsl:when>
    <xsl:otherwise>
      <xsl:text>"</xsl:text>
      <xsl:variable name="a" select="replace($atnode,'[{}|]','')"/>
      <xsl:value-of select="substring($a,0,xs:int($maxattlength))"/>
      <xsl:if test="string-length($a) gt xs:int($maxattlength)">...</xsl:if>
      <xsl:text>"</xsl:text>
    </xsl:otherwise>
  </xsl:choose>
</xsl:function>

<xsl:template match="PDF">
  <xsl:message select="$namespacemap"/>
[plantuml]
....
'
' <xsl:value-of select="replace(base-uri(),'.*/|\.*[a-z]+$',''),
  $rootelem,
  $occurrence[$rootelem]
  "/>
'
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
  <xsl:if test="@rolemapped-from and $namestylenum=(0,1)">
    <xsl:variable name="nu" select="string(namespace::orig-ns)"/>
    <xsl:value-of select="$namespacemap/n[@uri=$nu], ':'" separator=""/>
  </xsl:if>
  <xsl:if test="@rolemapped-from and $namestylenum=(0,1,2,3,4)">
    <xsl:value-of select="'**',substring-after(@rolemapped-from,':'),'**'" separator=""/>
  </xsl:if>
  <xsl:if test="@rolemapped-from and $namestylenum=(0,1,2)">
    <xsl:text>**-&gt;**</xsl:text>
  </xsl:if>
  <xsl:if test="(@rolemapped-from and $namestylenum=(0)) or not(@rolemapped-from) and  $namestylenum=(0,1)">
    <xsl:value-of select="$namespacemap/n[@uri=namespace-uri(current())], ':'" separator=""/>
  </xsl:if>
  <xsl:value-of select="'**',local-name(),'**'" separator=""/>

  <xsl:choose>
    <xsl:when test="empty((@* except (@rolemaps-to,@rolemapped-from,@referenced-as))[not(p:attname(local-name(.))=$omit-atts)][$show-empty or normalize-space(.)])">
      <xsl:text> </xsl:text>
    </xsl:when>
    <xsl:otherwise>
      <xsl:for-each select="(@* except (@rolemaps-to,@rolemapped-from,@referenced-as))[$show-empty or normalize-space(.)]">
	<xsl:variable name="n" select="p:attname(local-name())"/>
	<xsl:if test="not($n=$omit-atts)">
	  <xsl:value-of select="' **',$n,'**=',p:attvalue(.),' '" separator=""/>
	</xsl:if>
      </xsl:for-each>
    </xsl:otherwise>
  </xsl:choose>
  <xsl:text> | </xsl:text>
  <!-- {} in string content messes up the layout or breaks the plantuml editor if mis-matched -->
  <xsl:variable name="t" select="replace(normalize-space(.),'[{}]','...')"/>
  <xsl:choose>
    <xsl:when test="not(*) and $t and ($maxstringlengthnum gt 0)">
      <xsl:value-of select="'&quot;',substring($t,0,$maxstringlengthnum)" separator=""/>
      <xsl:if test="string-length($t) gt xs:int($maxstringlengthnum)">...</xsl:if>
      <xsl:text>"</xsl:text>
    </xsl:when>
    <xsl:otherwise>
      <xsl:text>.</xsl:text>
    </xsl:otherwise>
  </xsl:choose>
 <xsl:choose>      
    <xsl:when test="local-name()=$elide-elems or
		    (exists(*) and $level=xs:int($maxdepth))">
      <xsl:text>&#10;+</xsl:text>
      <xsl:for-each select="xs:int(1) to xs:int($level)">+</xsl:for-each>
      <xsl:text> **...** | . </xsl:text>
    </xsl:when>
    <xsl:otherwise>
      <xsl:apply-templates select="*[position() le $maxsiblingsnum]">
	<xsl:with-param name="level" select="xs:int($level+1)"/>
      </xsl:apply-templates>
      <xsl:if test="*[position() gt $maxsiblingsnum]">
	<xsl:text>&#10;+</xsl:text>
	<xsl:for-each select="xs:int(1) to xs:int($level)">+</xsl:for-each>
	<xsl:text> **...** | . </xsl:text>
      </xsl:if>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

</xsl:stylesheet>
