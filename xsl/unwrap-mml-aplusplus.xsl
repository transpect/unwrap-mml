<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:tr="http://transpect.io"
  xmlns:css="http://www.w3.org/1996/css" 
  xmlns:mml="http://www.w3.org/1998/Math/MathML"
  xmlns:mml2tex="http://transpect.io/mml2tex"
  exclude-result-prefixes="#all" 
  version="2.0">
  
  <!-- dissolves inline equations in A++ by utilizing the unwrap-mml.xsl stylesheet 
    
       invoke from command line:
       $ saxon -xsl:xsl/unwrap-mml-hub.xsl -s:source.xml -o:output.xml -it:main

  -->
  
  <xsl:import href="unwrap-mml.xsl"/>
  
  <xsl:param name="superscript" as="element()">
    <Superscript/>
  </xsl:param>
  <xsl:param name="subscript" as="element()">
    <Subscript/>
  </xsl:param>
  <xsl:param name="italic" as="element()">
    <Emphasis Type="Italic"/>
  </xsl:param>
  <xsl:param name="bold" as="element()">
    <Emphasis Type="Bold"/>
  </xsl:param>
  <xsl:param name="bold-italic" as="element()">
    <Emphasis Type="BoldItalic"/>
  </xsl:param>

  <!--  *
        * mode "delete-mml-ns" drop the temporary mml namespace
        * -->
  
  <xsl:template match="mml:*" mode="delete-mml-ns">
    <xsl:element name="{local-name()}">
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </xsl:element>
  </xsl:template>

  <!--  *
        * mode "unwrap-mml" invokes unwrap-mml module
        * -->
  
  <xsl:template match="InlineEquation[EquationSource[@Format eq 'MATHML']/mml:math[tr:unwrap-mml-boolean(.)]]
                      |Equation[EquationSource[@Format eq 'MATHML']/mml:math[tr:unwrap-mml-boolean(.)]]" mode="apply-unwrap-mml">
    <xsl:comment select="@ID, 'flattened'"/>
    <xsl:apply-templates select="EquationSource[@Format eq 'MATHML']/mml:math[tr:unwrap-mml-boolean(.)]" mode="unwrap-mml"/>
  </xsl:template>
  
  <xsl:template match="mml:msubsup[not(.//*[local-name() = ('msub', 'msup', 'msubsup')])]" mode="unwrap-mml">
    <xsl:apply-templates select="*[1]" mode="#current"/>
    <Stack>
      <Subscript>
        <xsl:apply-templates select="*[2]" mode="#current"/>  
      </Subscript>
      <Superscript>
        <xsl:apply-templates select="*[3]" mode="#current"/>
      </Superscript>
    </Stack>
  </xsl:template>
  
  <!-- override function for Stack element, allow msubsup -->
  
  <xsl:function name="tr:unwrap-mml-boolean" as="xs:boolean">
    <xsl:param name="math" as="element(mml:math)"/>
    <xsl:value-of select="if(count($math//mo[not(matches(., concat('^', $whitespace-regex, '|', $parenthesis-regex, '$')))]) le $operator-limit
                             and not(   $math//mfrac 
                                     or $math//mroot
                                     or $math//msqrt
                                     or $math//mtable
                                     or $math//mmultiscripts
                                     or $math//mphantom
                                     or $math//mstyle
                                     or $math//mover
                                     or $math//munder
                                     or $math//munderover
                                     or $math//munderover
                                     or $math//menclose
                                     or $math//merror
                                     or $math//maction
                                     or $math//mglyph
                                     or $math//mlongdiv
                                     or $math//msup[.//msub|.//msup]
                                     or $math//msub[.//msub|.//msup]
                                     )
                              )
                              then true()
                              else false()"/>
  </xsl:function>

  <xsl:template match="mml:math[tr:unwrap-mml-boolean(.)]//text()[matches(., concat('^', $whitespace-regex, '+$'))]" mode="unwrap-mml"/>
  
  <!--  *
        * mode "attach-mml-ns" add mathml namespace
        * -->
  
  <xsl:template match="math|math//*" mode="attach-mml-ns">
    <xsl:element name="{local-name()}" namespace="http://www.w3.org/1998/Math/MathML">
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </xsl:element>
  </xsl:template>
  
  <!-- micro pipeline -->
  
  <xsl:template name="main">
    <xsl:sequence select="$delete-mml-ns"/>
  </xsl:template>
  
  <xsl:variable name="delete-mml-ns">
    <xsl:apply-templates select="$apply-unwrap-mml" mode="delete-mml-ns"/>
  </xsl:variable>
  
  <xsl:variable name="apply-unwrap-mml">
    <xsl:apply-templates select="$attach-mml-ns" mode="apply-unwrap-mml"/>
  </xsl:variable>
  
  <xsl:variable name="attach-mml-ns">
    <xsl:apply-templates select="/" mode="attach-mml-ns"/>
  </xsl:variable>
  
  <!-- identity template -->
  
  <xsl:template match="*|@*|processing-instruction()|comment()" 
                mode="attach-mml-ns apply-unwrap-mml delete-mml-ns" priority="-1">
    <xsl:copy>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>
  
</xsl:stylesheet>
