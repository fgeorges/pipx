<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:t="http://pipx.org/ns/test"
                xmlns:c="http://www.w3.org/ns/xproc-step"
                xmlns="http://www.w3.org/1999/xhtml"
                version="2.0">

   <xsl:output method="html"/>

   <xsl:template match="node()" priority="-10" mode="#all">
      <xsl:message terminate="yes">
         <xsl:text>Unkown element: </xsl:text>
         <xsl:value-of select="name(.)"/>
      </xsl:message>
   </xsl:template>

   <xsl:template match="/t:suite-result">
      <html>
         <head>
            <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
            <meta charset="utf-8" />
            <meta http-equiv="X-UA-Compatible" content="IE=edge" />
            <meta name="viewport" content="width=device-width, initial-scale=1" />
            <title>
               <xsl:value-of select="t:title"/>
            </title>
            <link rel="stylesheet" type="text/css" href="bootstrap.css" />
         </head>
         <body>
            <div class="container">
               <h1>
                  <xsl:copy-of select="t:title/node()"/>
               </h1>
               <p>
                  <xsl:text>Results of the unit tests, ran on </xsl:text>
                  <xsl:value-of select="@timestamp"/>
                  <xsl:text>.</xsl:text>
               </p>
               <p>Click on the test code to expand (or collapse) its description.</p>
               <xsl:apply-templates select="t:test-result"/>
            </div>
            <script src="jquery-2.1.0.js" />
            <script>
              $('button').click(function () {
                var btn = $(this);
                var id = btn.attr('id');
                $('.' + id).toggle();
              });
              // hide description of successful tests
              <xsl:for-each select="t:test-result[empty(t:error)]">
                 <xsl:text>$('.pipx-id-</xsl:text>
                 <xsl:value-of select="@code"/>
                 <xsl:text>').toggle();</xsl:text>
              </xsl:for-each>
            </script>
         </body>
      </html>
   </xsl:template>

   <!--
      TODO: Include the actual and expected results when the test is successful
      as well (not only when it fails).  It is sometimes useful to be able to
      get the results from the test reports, even when the tests pass.
   -->
   <xsl:template match="t:test-result">
      <xsl:variable name="success-class" select="if ( exists(t:error) ) then 'danger' else 'success'"/>
      <p>
         <button id="pipx-id-{ @code }" type="button" class="btn btn-xs btn-{ $success-class }">
            <xsl:value-of select="@code"/>
         </button>
         <xsl:text> </xsl:text>
         <xsl:copy-of select="t:title/node()"/>
      </p>
      <div class="pipx-id-{ @code }">
         <xsl:copy-of select="t:documentation/node()"/>
         <xsl:apply-templates select="t:error"/>
      </div>
   </xsl:template>

   <xsl:template match="t:error">
      <p>
         <b>Error</b>
         <xsl:text>: </xsl:text>
         <xsl:value-of select="t:message"/>
      </p>
      <xsl:if test="exists(c:errors)">
         <ul>
            <xsl:for-each select="c:errors/c:error">
               <li>
                  <b>
                     <xsl:value-of select="@code"/>
                  </b>
                  <xsl:text>: in </xsl:text>
                  <!-- TODO: Add an tool tip with the absolute URI? -->
                  <xsl:value-of select="if ( contains(@href, '/') ) then tokenize(@href, '/')[last()] else @href"/>
                  <xsl:text>:</xsl:text>
                  <xsl:value-of select="@line"/>
                  <xsl:text>:</xsl:text>
                  <xsl:value-of select="@column"/>
               </li>
            </xsl:for-each>
         </ul>
      </xsl:if>
      <xsl:if test="exists(t:actual)">
         <p>
            <b>Actual result</b>
            <xsl:text>:</xsl:text>
         </p>
         <pre>
            <xsl:apply-templates select="t:actual/node()" mode="serialize"/>
         </pre>
      </xsl:if>
      <xsl:if test="exists(t:expected)">
         <p>
            <b>Expected result</b>
            <xsl:text>:</xsl:text>
         </p>
         <pre>
            <!-- TODO: Serialize properly the content... -->
            <xsl:apply-templates select="t:expected/node()" mode="serialize"/>
         </pre>
      </xsl:if>
   </xsl:template>

   <!-- TODO: Use the lib "serial" to serialize properly the content... -->
   <!-- Does not handle properly namespace declarations, char escaping, etc. -->
   <xsl:template match="*" mode="serialize">
      <xsl:text>&lt;</xsl:text>
      <xsl:value-of select="name(.)"/>
      <xsl:for-each select="@*">
         <xsl:text> </xsl:text>
         <xsl:value-of select="name(.)"/>
         <xsl:text>="</xsl:text>
         <xsl:value-of select="."/>
         <xsl:text>"</xsl:text>
      </xsl:for-each>
      <xsl:choose>
         <xsl:when test="empty(node())">
            <xsl:text>/&gt;</xsl:text>
         </xsl:when>
         <xsl:otherwise>
            <xsl:text>&gt;</xsl:text>
            <xsl:apply-templates select="node()" mode="serialize"/>
            <xsl:text>&lt;/</xsl:text>
            <xsl:value-of select="name(.)"/>
            <xsl:text>&gt;</xsl:text>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>

   <xsl:template match="text()" mode="serialize">
      <xsl:value-of select="."/>
   </xsl:template>

   <xsl:template match="document-node()" mode="serialize">
      <xsl:apply-templates mode="serialize"/>
   </xsl:template>

   <xsl:template match="@*" mode="serialize">
      <xsl:message terminate="yes">
         <xsl:text>Trying to serialize an attribute node: </xsl:text>
         <xsl:value-of select="name(.)"/>
         <xsl:text>, on an element: </xsl:text>
         <xsl:value-of select="name(..)"/>
         <xsl:text>, value: </xsl:text>
         <xsl:value-of select="."/>
      </xsl:message>
   </xsl:template>

   <xsl:template match="processing-instruction()" mode="serialize">
      <xsl:text>&lt;?</xsl:text>
      <xsl:value-of select="name(.)"/>
      <xsl:text> </xsl:text>
      <xsl:value-of select="."/>
      <xsl:text>?></xsl:text>
   </xsl:template>

   <xsl:template match="comment()" mode="serialize">
      <xsl:text>&lt;!--</xsl:text>
      <xsl:value-of select="."/>
      <xsl:text>--></xsl:text>
   </xsl:template>

</xsl:stylesheet>
