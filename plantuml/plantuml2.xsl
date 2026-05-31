<!--
    Process the output from
    show-pdf-tags - -xml - -map
    to make PlantUML diagrams and associated tables for
    PDF Association Tag Tree Diagrams


David Carlisle
Licence: MIT
-->


<xsl:stylesheet version="3.0"
		xmlns:xs="http://www.w3.org/2001/XMLSchema"
		xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		xmlns:p="data:,plantuml"
		exclude-result-prefixes="xs p"
		>
<xsl:output method="text"/>

<xsl:param name="rootelem"/>
<xsl:param name="occurrence" select="1"/>
<!--
    If these are set, start the display at the nth occurrence of the
    element with local name "rootelem"
-->

<xsl:param name="maxdepth" select="1000"/>
<xsl:param name="maxsiblings" select="1000"/>
<!--
    Maximum depth and sibling count, any elements
    exceeding these limits are omoited with ... marker
-->

<xsl:param name="elidecontent"/>
<!--
    Space separated list of element local-names
    any children of these elements are just shown as ...
-->

<xsl:param name="omitatts"/>
<!--
    Space separated list of attribute local names
    that shoul dnot be displayed
-->

<xsl:param name="showemptyatts" select="'no'"/>
<!--
    yes/no option on whether to sow attributes with empty value
    such as Alt=""
-->

<xsl:param name="maxattlength" select="20"/>
<!--
    Attribute values longer than this are truncated with a ... marker"
-->

<xsl:param name="nsprefix"/>
<xsl:param name="nsuri"/>
<!--
    Space separated lists of namespace prefixes and namespace URI
    provides the prefixes to use when displaying namespaces
    as the PDF file does not provide prefixes and show-pdf
    can not generate "good" ones.
-->
    
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
<!--
    If this is non zero element content is displayed as a "-delimited string
    in the comments column of the UML, truncated to this length if necessary.
-->


<xsl:variable name="elide-elems" select="tokenize($elidecontent,'[ ,]+')"/>
<xsl:variable name="omit-atts" select="tokenize($omitatts,'[ ,]+')"/>
<xsl:variable name="show-empty" select="matches($showemptyatts,'true|yes')" as="xs:boolean"/>
<xsl:variable name="maxsiblingsnum" select="xs:int($maxsiblings)"/>
<xsl:variable name="namestylenum" select="xs:int($namestyle)"/>
<xsl:variable name="maxstringlengthnum" select="xs:int($maxstringlength)"/>

<xsl:variable name="nsprefixseq" select="tokenize($nsprefix,'\s+')"/>
<xsl:variable name="nsuriseq" select="tokenize($nsuri,'\s+')"/>

<xsl:variable  name="namespacemap">
  <xsl:for-each select="distinct-values(//*/namespace::*)[not(starts-with(.,'http://iso.org/pdf/ssn/'))]">
    <n uri="{.}">
      <xsl:choose>
	<xsl:when test=".=$nsuriseq">
	  <xsl:value-of select="$nsprefixseq[index-of($nsuriseq,current())]"/>
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
      <xsl:value-of select="'//',$atnode,'//'" separator=""/>
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
  <xsl:result-document href="document-ns.txt">
    <xsl:for-each select="$namespacemap/n">
      <xsl:value-of select="'|',.,substring('    ',string-length(.)),'|',@uri,'|&#10;'"/>
    </xsl:for-each>		  
  </xsl:result-document>
<xsl:result-document href="document.puml">
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
</xsl:result-document>
<xsl:variable name="table">
    <xsl:choose>
      <xsl:when test="$rootelem">
	<xsl:apply-templates mode="tbl1" select="/descendant::*[local-name(.)=$rootelem][xs:int($occurrence)]"/>
      </xsl:when>
      <xsl:otherwise>
	    <xsl:apply-templates mode="tbl1" select="StructTreeRoot/*[position() le $maxsiblingsnum]"/>
	    <xsl:if test="*[position() gt $maxsiblingsnum]">
	      <row><prefix/><tag>...</tag><attributes/><comment>&lt;&lt;skipped&gt;&gt;</comment></row>
	    </xsl:if>
      </xsl:otherwise>
    </xsl:choose>
</xsl:variable>
<xsl:result-document href="document-table.txt">
<xsl:text>span class="adoc">[%header,cols="6h,6d,12d,8d,8d,20d,20d"]&#10;.Table &#10;|===/span>&#10;</xsl:text>
<xsl:text>| Row number | Depth | Parent row         | Prefix | Tag        | Attributes        | Comment&#10;</xsl:text>
<xsl:text>span class="md">|----        |----   |----                |----    |----        |----               |----/span>&#10;</xsl:text>
<xsl:apply-templates mode="tbl2"  select="$table//row"/>  
</xsl:result-document>
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
  <!-- {|} in string content messes up the layout or breaks the plantuml editor if mis-matched -->
  <xsl:variable name="t" select="replace(replace(replace(normalize-space(.),'[{]','&lt;U+007B>'),'[|]','&lt;U+007C>'),'[}]','&lt;U+007D>')"/>
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


<xsl:template mode="tbl1" match="*">
  <xsl:param name="level" select="xs:int(1)"/>
  <xsl:text>&#10;</xsl:text>
  <row>
    <prefix>
      <xsl:choose>
	<xsl:when test="@rolemapped-from">
	  <xsl:variable name="nu" select="string(namespace::orig-ns)"/>
	  <xsl:value-of select="$namespacemap/n[@uri=$nu]" separator=""/>
	</xsl:when>
	<xsl:otherwise>
	  <xsl:value-of select="$namespacemap/n[@uri=namespace-uri(current())]"/>
	</xsl:otherwise>
      </xsl:choose>
    </prefix>
    <tag>
  <xsl:if test="@rolemapped-from and $namestylenum=(0,1,2,3,4)">
    <xsl:value-of select="substring-after(@rolemapped-from,':')" separator=""/>
  </xsl:if>
  <xsl:if test="@rolemapped-from and $namestylenum=(0,1,2)">
    <xsl:text>-&gt;</xsl:text>
  </xsl:if>
  <xsl:value-of select="local-name()" separator=""/>
    </tag>
    <attributes>
  <xsl:choose>
    <xsl:when test="empty((@* except (@rolemaps-to,@rolemapped-from,@referenced-as))[not(p:attname(local-name(.))=$omit-atts)][$show-empty or normalize-space(.)])">
      <xsl:text> </xsl:text>
    </xsl:when>
    <xsl:otherwise>
      <xsl:for-each select="(@* except (@rolemaps-to,@rolemapped-from,@referenced-as))[$show-empty or normalize-space(.)]">
	<xsl:variable name="n" select="p:attname(local-name())"/>
	<xsl:if test="not($n=$omit-atts)">
	  <xsl:value-of select="' ',$n,'=',p:attvalue(.),' '" separator=""/>
	</xsl:if>
      </xsl:for-each>
    </xsl:otherwise>
  </xsl:choose>
    </attributes>
    <comment>
  <xsl:variable name="t" select="normalize-space(.)"/>
  <xsl:choose>
    <xsl:when test="not(*) and $t and ($maxstringlengthnum gt 0)">
      <xsl:value-of select="'&quot;',substring($t,0,$maxstringlengthnum)" separator=""/>
      <xsl:if test="string-length($t) gt xs:int($maxstringlengthnum)">...</xsl:if>
      <xsl:text>"</xsl:text>
    </xsl:when>
  </xsl:choose>
    </comment>
 <xsl:choose>      
    <xsl:when test="local-name()=$elide-elems or
		    (exists(*) and $level=xs:int($maxdepth))">
      <xsl:text>&#10;</xsl:text>
      <row><prefix/><tag>...</tag><attributes/><comment>&lt;&lt;skipped&gt;&gt;</comment></row>
    </xsl:when>
    <xsl:otherwise>
      <xsl:apply-templates mode="tbl1" select="*[position() le $maxsiblingsnum]">
	<xsl:with-param name="level" select="xs:int($level+1)"/>
      </xsl:apply-templates>
      <xsl:if test="*[position() gt $maxsiblingsnum]">
	<xsl:text>&#10;</xsl:text>
	<row><prefix/><tag>...</tag><attributes/><comment>&lt;&lt;skipped&gt;&gt;</comment></row>
      </xsl:if>
    </xsl:otherwise>
  </xsl:choose>
  </row>
</xsl:template>



<xsl:template mode="tbl2" match="row">
  <xsl:text>| </xsl:text>
  <xsl:variable name="n"><xsl:number level="any"/></xsl:variable>
  <xsl:value-of select="substring('         ',string-length($n)),$n" separator=""/>
  <xsl:text> | </xsl:text>
  <xsl:variable name="n"><xsl:value-of select="count(ancestor::*)+1"/></xsl:variable>
  <xsl:value-of select="substring('    ',string-length($n)),$n" separator=""/>
  <xsl:text> | </xsl:text>
  <xsl:choose>
    <xsl:when test="parent::row">
      <xsl:text>Row </xsl:text>
      <xsl:variable name="n"><xsl:number level="any" select=".."/></xsl:variable>
      <xsl:value-of select="substring(' ',string-length($n)),$n" separator=""/>
      <xsl:text>: </xsl:text>
      <xsl:value-of select="../tag"/>
    </xsl:when>
    <xsl:otherwise><xsl:text>        </xsl:text></xsl:otherwise>
  </xsl:choose>
  <xsl:value-of select="substring('          ',1+string-length(../tag))" separator=""/>
  <xsl:text> | </xsl:text>
  <xsl:value-of select="prefix"/>
  <xsl:value-of select="substring('      ',1+string-length(prefix))" separator=""/>
  <xsl:text> | </xsl:text>
  <xsl:value-of select="tag"/>
  <xsl:value-of select="substring('          ',1+string-length(tag))" separator=""/>
  <xsl:text> | </xsl:text>
  <xsl:value-of select="attributes"/>
  <xsl:value-of select="substring('                 ',1+string-length(attributes))" separator=""/>
  <xsl:text> | </xsl:text>
  <xsl:value-of select="replace(comment,'[|]','\\|')"/>
  <xsl:text>&#10;</xsl:text>
</xsl:template>

</xsl:stylesheet>
