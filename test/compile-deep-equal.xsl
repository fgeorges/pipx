<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:t="http://pipx.org/ns/test"
                version="2.0">

   <!-- TODO: Test the user does not pass an invalid enum value for $comments. -->
   <xsl:param name="comments"/>

   <!-- TODO: Test the user does not pass an invalid enum value for $whitespaces. -->
   <xsl:param name="whitespaces"/>

   <!-- TODO: Double-check there is nothing in [3]. -->
   <xsl:variable name="expected" select="collection()[2]"/>

   <xsl:variable name="content" as="document-node()">
      <xsl:choose>
         <!-- TODO: It seems Calabash presents the doc as an element, report it... -->
         <xsl:when test=". instance of element()">
            <xsl:document>
               <xsl:sequence select="."/>
            </xsl:document>
         </xsl:when>
         <xsl:otherwise>
            <xsl:sequence select="."/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:variable>

   <xsl:template match="node()">
      <xsl:variable name="equal" as="xs:boolean">
         <xsl:apply-templates select="$content" mode="cmp">
            <xsl:with-param name="exp" select="$expected"/>
         </xsl:apply-templates>
      </xsl:variable>
      <xsl:choose>
         <xsl:when test="$equal">
            <t:success>
               <t:actual>
                  <xsl:sequence select="$content"/>
               </t:actual>
               <t:expected>
                  <xsl:sequence select="$expected"/>
               </t:expected>
            </t:success>
         </xsl:when>
         <xsl:otherwise>
            <t:error>
               <t:message>Actual result is not deep equal to expected result.</t:message>
               <t:actual>
                  <xsl:sequence select="$content"/>
               </t:actual>
               <t:expected>
                  <xsl:sequence select="$expected"/>
               </t:expected>
            </t:error>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>

   <!-- Should never match, as we match all node kinds. Just in case. -->
   <xsl:template match="node()" mode="cmp" priority="-10">
      <xsl:message terminate="yes">
         <xsl:text>Unsupported node: </xsl:text>
         <xsl:value-of select="name(.)"/>
      </xsl:message>
   </xsl:template>

   <!-- If $exp is a doc node, recurse both sides, if not, recurse here. -->
   <xsl:template match="document-node()" mode="cmp" as="xs:boolean">
      <xsl:param name="exp" as="node()" required="yes"/>
      <xsl:choose>
         <xsl:when test="$exp instance of document-node()">
            <xsl:sequence select="t:cmp-children(node(), $exp/node())"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:sequence select="t:cmp-children(node(), $exp)"/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>

   <xsl:template match="*" mode="cmp" as="xs:boolean">
      <xsl:param name="exp" as="node()" required="yes"/>
      <xsl:choose>
         <xsl:when test="not($exp instance of element())">
            <xsl:sequence select="false()"/>
         </xsl:when>
         <xsl:when test="node-name(.) ne node-name($exp)">
            <xsl:sequence select="false()"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:variable name="actual-attrs" select="t:sort-attrs(@*)"/>
            <xsl:variable name="exp-attrs"    select="t:sort-attrs($exp/@*)"/>
            <xsl:choose>
               <xsl:when test="not(t:cmp-attrs($actual-attrs, $exp-attrs))">
                  <xsl:sequence select="false()"/>
               </xsl:when>
               <xsl:otherwise>
                  <xsl:sequence select="t:cmp-children(node(), $exp/node())"/>
               </xsl:otherwise>
            </xsl:choose>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>

   <xsl:template match="text()" mode="cmp" as="xs:boolean">
      <xsl:param name="exp" as="node()" required="yes"/>
      <xsl:choose>
         <xsl:when test="not($exp instance of text())">
            <xsl:sequence select="false()"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:sequence select=". eq $exp"/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>

   <xsl:template match="comment()" mode="cmp" as="xs:boolean">
      <xsl:param name="exp" as="node()" required="yes"/>
      <xsl:choose>
         <xsl:when test="not($exp instance of comment())">
            <xsl:sequence select="false()"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:sequence select=". eq $exp"/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>

   <xsl:template match="processing-instruction()" mode="cmp" as="xs:boolean">
      <xsl:param name="exp" as="node()" required="yes"/>
      <xsl:choose>
         <xsl:when test="not($exp instance of processing-instruction())">
            <xsl:sequence select="false()"/>
         </xsl:when>
         <xsl:when test="node-name(.) ne node-name($exp)">
            <xsl:sequence select="false()"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:sequence select=". eq $exp"/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>

   <!--
      Sort a list of attributes, by name.
   -->
   <xsl:function name="t:sort-attrs" as="attribute()*">
      <xsl:param name="attrs" as="attribute()*"/>
      <xsl:for-each select="$attrs">
         <!-- TODO: QNames are comparable, but not ordered, so need to use a 2 keys
              approach (first key is the namespace, second is the local name). -->
         <xsl:sort select="namespace-uri(.)"/>
         <xsl:sort select="local-name(.)"/>
         <xsl:sequence select="."/>
      </xsl:for-each>
   </xsl:function>

   <!--
      Compare 2 sequences of attributes (must be sorted by name), each item 2 by 2.
   -->
   <xsl:function name="t:cmp-attrs" as="xs:boolean">
      <xsl:param name="actual" as="attribute()*"/>
      <xsl:param name="exp"    as="attribute()*"/>
      <xsl:choose>
         <xsl:when test="empty($actual) and empty($exp)">
            <xsl:sequence select="true()"/>
         </xsl:when>
         <xsl:when test="count($actual) ne count($exp)">
            <xsl:sequence select="false()"/>
         </xsl:when>
         <xsl:when test="node-name($actual[1]) ne node-name($exp[1])">
            <xsl:sequence select="false()"/>
         </xsl:when>
         <xsl:when test="$actual[1] ne $exp[1]">
            <xsl:sequence select="false()"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:sequence select="t:cmp-attrs(remove($actual, 1), remove($exp, 1))"/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>

   <!--
      Compare 2 sequences, each item 2 by 2.  Ignore nodes to ignore as it meets
      them (e.g. comments if they have to be ignored).
   -->
   <xsl:function name="t:cmp-children" as="xs:boolean">
      <xsl:param name="actual" as="node()*"/>
      <xsl:param name="exp"    as="node()*"/>
      <!-- ignore as much as we can at the beginning of both sequences -->
      <xsl:variable name="clean-actual" select="t:ignore-head($actual)"/>
      <xsl:variable name="clean-exp"    select="t:ignore-head($exp)"/>
      <xsl:choose>
         <!-- both empty -->
         <xsl:when test="empty($clean-actual) and empty($clean-exp)">
            <xsl:sequence select="true()"/>
         </xsl:when>
         <!-- only one empty -->
         <xsl:when test="empty($clean-actual) or empty($clean-exp)">
            <xsl:sequence select="false()"/>
         </xsl:when>
         <!-- compare both heads, then recurse if equal -->
         <xsl:otherwise>
            <xsl:variable name="heads-equal" as="xs:boolean">
               <xsl:apply-templates select="$clean-actual[1]" mode="cmp">
                  <xsl:with-param name="exp" select="$clean-exp[1]"/>
               </xsl:apply-templates>
            </xsl:variable>
            <xsl:choose>
               <xsl:when test="$heads-equal">
                  <xsl:sequence select="
                     t:cmp-children(
                        remove($clean-actual, 1),
                        remove($clean-exp, 1))"/>
               </xsl:when>
               <xsl:otherwise>
                  <xsl:sequence select="false()"/>
               </xsl:otherwise>
            </xsl:choose>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>

   <!--
      Ignore any ignorable node (depending on $comments and $whitespaces), only
      at the beginning of the sequence.
   -->
   <xsl:function name="t:ignore-head" as="node()*">
      <xsl:param name="seq" as="node()*"/>
      <xsl:choose>
         <xsl:when test="empty($seq)">
            <!-- nothing -->
         </xsl:when>
         <xsl:when test="$seq[1] instance of comment()">
            <xsl:choose>
               <xsl:when test="$comments eq 'ignore'">
                  <xsl:sequence select="t:ignore-head(remove($seq, 1))"/>
               </xsl:when>
               <xsl:otherwise>
                  <xsl:sequence select="$seq"/>
               </xsl:otherwise>
            </xsl:choose>
         </xsl:when>
         <xsl:when test="$seq[1] instance of text()">
            <xsl:choose>
               <xsl:when test="$whitespaces eq 'ignore' and matches($seq[1], '^\s*$')">
                  <xsl:sequence select="t:ignore-head(remove($seq, 1))"/>
               </xsl:when>
               <xsl:otherwise>
                  <xsl:sequence select="$seq"/>
               </xsl:otherwise>
            </xsl:choose>
         </xsl:when>
         <xsl:otherwise>
            <xsl:sequence select="$seq"/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>

</xsl:stylesheet>
