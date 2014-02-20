<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:x_="http://www.w3.org/1999/XSL/Transform#Alias"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:t="http://pipx.org/ns/test"
                xmlns:p="http://www.w3.org/ns/xproc"
                xmlns:c="http://www.w3.org/ns/xproc-step"
                version="2.0">

   <xsl:namespace-alias stylesheet-prefix="x_" result-prefix="xsl"/>

   <xsl:template match="node()" priority="-10">
      <xsl:message terminate="yes">
         <xsl:text>Unkown element: </xsl:text>
         <xsl:value-of select="name(.)"/>
      </xsl:message>
   </xsl:template>

   <!-- create namespace nodes, by copying in-scope namespace on $element -->
   <xsl:template name="copy-namespaces">
      <xsl:param name="element" as="element()" select="."/>
      <xsl:for-each select="in-scope-prefixes($element)">
         <xsl:namespace name="{ . }" select="namespace-uri-for-prefix(., $element)"/>
      </xsl:for-each>
   </xsl:template>

   <xsl:template match="/t:suite">
      <p:declare-step version="1.0">
         <!-- copy the namespaces, as usually the root element contains most namespace -->
         <!-- that makes the result more readable -->
         <xsl:call-template name="copy-namespaces"/>

         <p:output port="result" primary="true"/>

         <p:import href="../src/pipx.xpl"/>
      
         <p:declare-step type="t:deep-equal" name="this">
            <p:input  port="actual" primary="true"/>
            <p:input  port="expected"/>
            <p:output port="result" primary="true"/>
            <p:xslt>
               <p:input port="source">
                  <p:pipe step="this" port="actual"/>
                  <p:pipe step="this" port="expected"/>
               </p:input>
               <p:input port="stylesheet">
                  <p:inline>
                     <x_:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0">
                        <x_:variable name="expected" select="collection()[2]"/>
                        <x_:template match="node()">
                           <x_:choose>
                              <x_:when test="deep-equal(., $expected)">
                                 <t:success/>
                              </x_:when>
                              <!-- TODO: It seems Calabash presents the doc as an element, report it... -->
                              <x_:when test=". instance of element() and count($expected/*) eq 1 and deep-equal(., $expected/*)">
                                 <t:success/>
                              </x_:when>
                              <x_:otherwise>
                                 <t:error>
                                    <t:message>Actual result is not deep equal to expected result.</t:message>
                                    <t:actual>
                                       <x_:sequence select="."/>
                                    </t:actual>
                                    <t:expected>
                                       <x_:sequence select="$expected"/>
                                    </t:expected>
                                 </t:error>
                              </x_:otherwise>
                           </x_:choose>
                        </x_:template>
                     </x_:stylesheet>
                  </p:inline>
               </p:input>
               <p:input port="parameters">
                  <p:empty/>
               </p:input>
            </p:xslt>
         </p:declare-step>

         <!-- generate the test themselves -->
         <xsl:apply-templates select="t:test"/>

         <p:wrap-sequence wrapper="t:suite-result">
            <p:input port="source">
               <xsl:for-each select="t:test">
                  <!-- TODO: Needs to be more sophisticated to allow other port names... -->
                  <!-- Will probably need to wrap tests into a p:declare-step, so they can
                     connect the primary port automatically to a port with a specific name. -->
                  <p:pipe step="{ @code }" port="result"/>
               </xsl:for-each>
            </p:input>
         </p:wrap-sequence>
         <p:add-attribute match="/*" attribute-name="timestamp">
            <p:with-option name="attribute-value" select="current-dateTime()"/>
         </p:add-attribute>
         <p:insert match="/*" position="first-child">
            <p:input port="insertion" select="/*/*">
               <p:inline>
                  <dummy>
                     <xsl:copy-of select="t:title|t:documentation"/>
                  </dummy>
               </p:inline>
            </p:input>
         </p:insert>

      </p:declare-step>
   </xsl:template>

   <xsl:template match="t:test">
      <p:try>
         <xsl:call-template name="copy-namespaces"/>
         <p:group>
            <!-- the pipeline to test -->
            <xsl:copy-of select="* except t:*"/>
            <!-- the assertions (except error assertions) -->
            <xsl:apply-templates select="t:* except (t:error|t:title|t:documentation)"/>
         </p:group>
         <p:catch>
            <xsl:choose>
               <xsl:when test="exists(t:error)">
                  <!-- the error assertions -->
                  <xsl:apply-templates select="t:error"/>
               </xsl:when>
               <xsl:otherwise>
                  <!-- the default error catching (failing) -->
                  <p:identity>
                     <p:input port="source">
                        <p:inline>
                           <!-- TODO: Add error information... -->
                           <t:error>
                              <t:message>An unexpected error was thrown...</t:message>
                           </t:error>
                        </p:inline>
                     </p:input>
                  </p:identity>
               </xsl:otherwise>
            </xsl:choose>
         </p:catch>
      </p:try>
      <!-- wrapping the primary output into a t:test-result element, with the test @code -->
      <p:wrap match="/*" wrapper="t:test-result"/>
      <p:insert match="/*" position="first-child">
         <p:input port="insertion" select="/*/*">
            <p:inline>
               <dummy>
                  <xsl:copy-of select="t:title|t:documentation"/>
               </dummy>
            </p:inline>
         </p:input>
      </p:insert>
      <p:add-attribute match="/*" attribute-name="code" attribute-value="{ @code }" name="{ @code }"/>
   </xsl:template>

   <xsl:template match="t:deep-equal[empty(t:*)]">
      <t:deep-equal>
         <p:input port="expected">
            <p:inline>
               <xsl:copy-of select="*"/>
            </p:inline>
         </p:input>
      </t:deep-equal>
   </xsl:template>

   <xsl:template match="t:error">
      <!-- TODO: Check the correct error has been caught (t:error/@code) -->
      <p:identity>
         <p:input port="source">
            <p:inline>
               <t:success>
                  <t:message>Error properly thrown.</t:message>
               </t:success>
            </p:inline>
         </p:input>
      </p:identity>
   </xsl:template>

</xsl:stylesheet>
