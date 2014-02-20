<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:t="http://pipx.org/ns/test"
                version="2.0">

   <xsl:output method="html"/>

   <xsl:template match="node()" priority="-10">
      <xsl:message terminate="yes">
         <xsl:text>Unkown element: </xsl:text>
         <xsl:value-of select="name(.)"/>
      </xsl:message>
   </xsl:template>

   <xsl:template match="/t:suite-result">
      <html xmlns="http://www.w3.org/1999/xhtml">
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
      </div>
   </xsl:template>

</xsl:stylesheet>
