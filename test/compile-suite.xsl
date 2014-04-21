<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:t="http://pipx.org/ns/test"
                xmlns:p="http://www.w3.org/ns/xproc"
                xmlns:c="http://www.w3.org/ns/xproc-step"
                version="2.0">

   <xsl:variable name="deep-equal-xsl" select="document('compile-deep-equal.xsl')"/>

   <xsl:template match="node()" priority="-10">
      <xsl:message terminate="yes">
         <xsl:text>Unsupported node: </xsl:text>
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

         <xsl:apply-templates select="t:import"/>
      
         <p:declare-step type="t:deep-equal" name="this">
            <p:input  port="actual" primary="true"/>
            <p:input  port="expected"/>
            <p:output port="result" primary="true"/>
            <p:option name="comments"/>
            <p:option name="whitespaces"/>
            <p:xslt>
               <p:with-param name="comments"    select="$comments"/>
               <p:with-param name="whitespaces" select="$whitespaces"/>
               <p:input port="source">
                  <p:pipe step="this" port="actual"/>
                  <p:pipe step="this" port="expected"/>
               </p:input>
               <p:input port="stylesheet">
                  <p:inline>
                     <xsl:copy-of select="$deep-equal-xsl"/>
                  </p:inline>
               </p:input>
            </p:xslt>
         </p:declare-step>

         <p:declare-step type="t:catch-error" name="this">
            <p:input  port="source" primary="true"/>
            <p:output port="result" primary="true"/>
            <p:option name="message" required="true"/>
            <p:template name="title-tpl">
               <p:input port="source">
                  <p:empty/>
               </p:input>
               <p:input port="template">
                  <p:inline>
                     <t:error>
                        <t:message>{ $msg }</t:message>
                     </t:error>
                  </p:inline>
               </p:input>
               <p:with-param name="msg" select="$message"/>
            </p:template>
            <p:insert match="/*" position="last-child">
               <p:input port="insertion">
                  <p:pipe step="this" port="source"/>
               </p:input>
            </p:insert>
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

   <xsl:template match="t:import">
      <p:import href="{ resolve-uri(@href, base-uri(.)) }"/>
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
         <p:catch name="catch">
            <xsl:choose>
               <xsl:when test="exists(t:error)">
                  <!-- the error assertions -->
                  <xsl:apply-templates select="t:error"/>
               </xsl:when>
               <xsl:otherwise>
                  <!-- the default error catching (failing) -->
                  <t:catch-error message="An unexpected error was thrown...">
                     <p:input port="source">
                        <p:pipe step="catch" port="error"/>
                     </p:input>
                  </t:catch-error>
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
         <xsl:copy-of select="@*"/>
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
