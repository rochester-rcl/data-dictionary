<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet 
  xmlns="http://www.w3.org/1999/xhtml"
  xmlns:tei="http://www.tei-c.org/ns/1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0" 
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:a="http://relaxng.org/ns/compatibility/annotations/1.0"
  xmlns:teix="http://www.tei-c.org/ns/Examples" 
  xmlns:d="http://www.oxygenxml.com/ns/doc/xsl"
  xpath-default-namespace="http://www.tei-c.org/ns/1.0"
  exclude-result-prefixes="#all">
  <d:doc>
    <d:desc>
      <d:p type="title">Data Dictionary Generator</d:p>
      <d:p>An open-source TEI documentation tool</d:p>
      <d:p>Special thanks to Martin Holmes, University of Victoria, for the egXML code-rendering
        mechanism.</d:p>
      <d:p>This script uses a TEI-formatted glossary of local definitions and the TEI source to P5
        to generate an XHTML "dictionary" profile of the TEI file. See the included README for 
        further information.</d:p>
      <d:ul>
        <d:li type="dependency">p5subset.xml</d:li>
        <d:li type="dependency">*_dictionary.xml</d:li>
      </d:ul>
      <d:p type="creator">Joe Easterly</d:p>
      <d:p type="contributor">Syd Bauman</d:p>
      <d:p type="contributor">Sean Morris</d:p>
      <d:p type="updated">2015-09-01</d:p>
      <d:ref>http://humanities.lib.rochester.edu/</d:ref>
      <d:p>This work is licensed under the Creative Commons Attribution-ShareAlike 4.0 International
        License. To view a copy of this license, visit
        http://creativecommons.org/licenses/by-sa/4.0/.</d:p>
    </d:desc>
  </d:doc>
  <xsl:key name="elements" match="*" use="name()"/>
  <xsl:key name="attributes" match="@*" use="name()"/>
  <xsl:param name="debug" select="'true'"/>
  <xsl:param name="displayModule" select="'false'"/>
  <xsl:param name="outputFormat" select="'html'"/>
  <xsl:param name="teiOutPath" select="'/tmp/data_dictionary_tei.xml'"/>
  <xsl:param name="P5source" select="'p5subset.xml'"/>
  <xsl:param name="dictFile">
    <xsl:if test="doc-available('sample_dictionary.xml')">
      <xsl:value-of select="'sample_dictionary.xml'"/>
    </xsl:if>
  </xsl:param>
  <xsl:variable name="dictAvail">
    <xsl:choose>
      <xsl:when test="doc-available($dictFile)">
        <xsl:value-of select="'yes'"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="'no'"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>
  <xsl:variable name="newline" select="'&#x0A;'"/>
  <xsl:variable name="bullet" select="' • '"/>
  <xsl:variable name="pipe" select="' | '"/>
  <xsl:template match="/">
    <xsl:if test="$debug = 'true'">
      <xsl:message>
        <xsl:value-of select="current-time()"/>
        <xsl:text> - D1001: Starting TEI Template</xsl:text>
      </xsl:message>
    </xsl:if>
    <xsl:variable name="intermediate_TEI">
      <xsl:variable name="teiFile" select="document($P5source)"/>
      <TEI xmlns="http://www.tei-c.org/ns/1.0">
        <xsl:choose>
          <xsl:when test="$dictAvail = 'yes'">
            <xsl:copy-of select="document($dictFile)//teiHeader"/>
          </xsl:when>
          <xsl:otherwise>
            <teiHeader>
              <fileDesc>
                <titleStmt>
                  <title type="main">Data Dictionary</title>
                </titleStmt>
                <publicationStmt>
                  <p>This sample TEI file was created using the Data Dictionary Generator,
                    originally release by the River Campus Libraries, University of Rochester.</p>
                </publicationStmt>
                <sourceDesc>
                  <p>A description of your data dictionary goes here.</p>
                </sourceDesc>
              </fileDesc>
            </teiHeader>
          </xsl:otherwise>
        </xsl:choose>
        <text>
          <body>
            <!--Start working on the element list-->
            <xsl:for-each select="//*[generate-id(.) = generate-id(key('elements', name())[1])]">
              <xsl:sort select="name()"/>
              <xsl:variable name="elementName" select="name()"/>
              <xsl:if test="$debug = 'true'">
                <xsl:message>
                  <xsl:value-of select="current-time()"/>
                  <xsl:text> - Processing element </xsl:text>
                  <xsl:value-of select="$elementName"/>
                </xsl:message>
              </xsl:if>
              <xsl:variable name="teiGloss"
                select="$teiFile//elementSpec[@ident eq $elementName]/gloss[@xml:lang = 'en']"/>
              <xsl:variable name="teiDesc"
                select="$teiFile//elementSpec[@ident eq $elementName]/desc[@xml:lang = 'en']"/>
              <xsl:variable name="eleModuleName"
                select="$teiFile//elementSpec[@ident eq $elementName]/@module"/>
              <xsl:variable name="eleClassNames"
                select="$teiFile//elementSpec[@ident eq $elementName]/classes/memberOf/@key"/>
              <xsl:variable name="dictEntries"
                select="document($dictFile)//body/div[@corresp eq $elementName][@type = 'element']"/>
              <xsl:for-each select="key('elements', name())">
                <xsl:if test="position() = 1">
                  <!--For the elements in the dictionary, start grabbing metadata from the source document-->
                  <xsl:variable name="eleCount" select="count(//*[name() = name(current())])"/>
                  <xsl:variable name="eleContainedBy"
                    select="distinct-values(//*[name() = name(current())]/parent::*/name())"/>
                  <xsl:variable name="eleMayContain"
                    select="distinct-values(//*[name() = name(current())]/child::*/name())"/>
                  <xsl:variable name="eleAttributes"
                    select="distinct-values(//*[name() = name(current())]/@*/name())"/>

                  <!-- Build a div for each element -->
                  <div>
                    <xsl:attribute name="type" select="'element'"/>
                    <xsl:attribute name="corresp" select="$elementName"/>
                    <xsl:attribute name="xml:id">
                      <xsl:text>e.</xsl:text>
                      <xsl:value-of select="$elementName"/>
                    </xsl:attribute>
                    <!-- Grab the gloss (i.e., fuller name) for the element -->
                    <xsl:if test="$teiGloss != ''">
                      <ab>
                        <xsl:attribute name="type" select="'gloss'"/>
                        <xsl:value-of select="$teiGloss"/>
                      </ab>
                    </xsl:if>
                    <!-- Grab the module and class data, if requested -->
                    <xsl:if test="$displayModule = 'true'">
                      <ab>
                        <xsl:attribute name="type" select="'module'"/>
                        <xsl:value-of select="$eleModuleName"/>
                      </ab>
                      <ab>
                        <xsl:attribute name="type" select="'classes'"/>
                        <xsl:for-each select="$eleClassNames">
                          <seg>
                            <xsl:value-of select="."/>
                          </seg>
                        </xsl:for-each>
                      </ab>
                    </xsl:if>
                    <!-- Count how many times the element appears in the document -->
                    <ab>
                      <xsl:attribute name="type" select="'count'"/>
                      <xsl:value-of select="$eleCount"/>
                    </ab>
                    <xsl:if test="$eleContainedBy != ''">
                      <ab>
                        <xsl:attribute name="type" select="'parents'"/>
                        <xsl:for-each select="distinct-values($eleContainedBy)">
                          <seg>
                            <xsl:attribute name="ana">
                              <xsl:text>#</xsl:text>
                              <xsl:text>e.</xsl:text>
                              <xsl:value-of select="."/>
                            </xsl:attribute>
                            <xsl:value-of select="."/>
                          </seg>
                        </xsl:for-each>
                      </ab>
                    </xsl:if>
                    <xsl:if test="$eleMayContain != ''">
                      <ab>
                        <xsl:attribute name="type" select="'children'"/>
                        <xsl:value-of select="$newline"/>
                        <xsl:for-each select="distinct-values($eleMayContain)">
                          <seg>
                            <xsl:attribute name="ana">
                              <xsl:text>#</xsl:text>
                              <xsl:text>e.</xsl:text>
                              <xsl:value-of select="."/>
                            </xsl:attribute>
                            <xsl:value-of select="."/>
                          </seg>
                          <xsl:value-of select="$newline"/>
                        </xsl:for-each>
                      </ab>
                    </xsl:if>
                    <xsl:if test="$eleAttributes != ''">
                      <ab>
                        <xsl:attribute name="type" select="'attributes'"/>
                        <xsl:value-of select="$newline"/>
                        <xsl:for-each select="distinct-values($eleAttributes)">
                          <seg>
                            <xsl:attribute name="ana">
                              <xsl:text>#</xsl:text>
                              <xsl:text>a.</xsl:text>
                              <xsl:value-of select="."/>
                            </xsl:attribute>
                            <xsl:value-of select="."/>
                          </seg>
                          <xsl:value-of select="$newline"/>
                        </xsl:for-each>
                      </ab>
                    </xsl:if>
                    <!-- Insert the local definition -->
                    <xsl:if test="count($dictEntries) ge 1">
                      <div>
                        <xsl:attribute name="type" select="'entry'"/>
                        <xsl:attribute name="ana" select="'project'"/>
                        <xsl:copy-of select="$dictEntries/div[@type = 'entry']/child::node()"/>
                      </div>
                    </xsl:if>
                    <!-- Insert the definition from the TEI Guidelines -->
                    <xsl:if test="$teiDesc != ''">
                      <div>
                        <xsl:attribute name="type" select="'entry'"/>
                        <xsl:attribute name="ana" select="'tei'"/>
                        <span type="definition">
                          <xsl:attribute name="target">
                            <xsl:text>http://www.tei-c.org/release/doc/tei-p5-doc/en/html/ref-</xsl:text>
                            <xsl:value-of select="$elementName"/>
                            <xsl:text>.html</xsl:text>
                          </xsl:attribute>
                          <xsl:value-of select="$teiDesc"/>
                        </span>
                      </div>
                    </xsl:if>
                  </div>
                </xsl:if>
              </xsl:for-each>

            </xsl:for-each>
            <!--Start working on the attribute list-->
            <xsl:for-each select="//@*[generate-id(.) = generate-id(key('attributes', name())[1])]">
              <xsl:sort select="name()"/>
              <xsl:variable name="attName" select="name()"/>
              <xsl:if test="$debug = 'true'">
                <xsl:message>
                  <xsl:value-of select="current-time()"/>
                  <xsl:text> - Processing attribute @</xsl:text>
                  <xsl:value-of select="$attName"/>
                </xsl:message>
              </xsl:if>
              <xsl:variable name="teiGloss"
                select="$teiFile//attDef[@ident eq $attName][1]/gloss[@xml:lang eq 'en']"/>
              <xsl:variable name="teiURL"
                select="document($dictFile)//body/div[@corresp eq $attName][@type eq 'attribute']/span[@type eq 'teiurl']"/>
              <xsl:variable name="teiAttDescSet"
                select="$teiFile//classSpec[descendant::attDef/@ident = $attName]"/>
              <xsl:variable name="attEntries"
                select="document($dictFile)//body/div[@corresp eq $attName][@type = 'attribute']"/>
              <xsl:variable name="attContents"
                select="document($dictFile)//body/div[@corresp eq $attName][@type eq 'attribute']//span[@type eq 'mayContain']"/>

              <xsl:for-each select="key('attributes', name())">
                <xsl:if test="position() = 1">

                  <!--For the attributes in the dictionary, start grabbing metadata from the source document-->
                  <xsl:variable name="attCount" select="count(//@*[name() = name(current())])"/>
                  <xsl:variable name="attContainedBy"
                    select="distinct-values(//@*[name() = name(current())]/parent::*/name())"/>
                  <xsl:variable name="attMayContain">
                    <xsl:choose>
                      <xsl:when test="$attContents != ''">
                        <xsl:value-of select="$attContents"/>
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:value-of select="distinct-values(//@*[name() = name(current())])"/>
                      </xsl:otherwise>
                    </xsl:choose>
                  </xsl:variable>
                  <!-- Build a div for each attribute -->
                  <div>
                    <xsl:attribute name="type" select="'attribute'"/>
                    <xsl:attribute name="corresp" select="$attName"/>
                    <xsl:attribute name="xml:id">
                      <xsl:text>a.</xsl:text>
                      <xsl:value-of select="translate($attName, ':', '.')"/>
                    </xsl:attribute>
                    <xsl:if test="$teiGloss != ''">
                      <ab>
                        <xsl:attribute name="type" select="'gloss'"/>
                        <xsl:value-of select="$teiGloss"/>
                      </ab>
                    </xsl:if>
                    <!-- Count how many times the attribute appears in the document -->
                    <ab>
                      <xsl:attribute name="type" select="'count'"/>
                      <xsl:value-of select="$attCount"/>
                    </ab>
                    <xsl:if test="$attContainedBy != ''">
                      <ab>
                        <xsl:attribute name="type" select="'parents'"/>
                        <xsl:for-each select="distinct-values($attContainedBy)">
                          <seg>
                            <xsl:attribute name="ana">
                              <xsl:text>#</xsl:text>
                              <xsl:text>e.</xsl:text>
                              <xsl:value-of select="."/>
                            </xsl:attribute>
                            <xsl:value-of select="."/>
                          </seg>
                        </xsl:for-each>
                      </ab>
                    </xsl:if>
                    <xsl:if test="$attMayContain != ''">
                      <ab>
                        <xsl:attribute name="type" select="'children'"/>
                        <xsl:value-of select="$attMayContain"/>
                      </ab>
                    </xsl:if>

                    <xsl:if test="count($teiAttDescSet) ge 1">
                      <div>
                        <xsl:attribute name="type" select="'entry'"/>
                        <xsl:attribute name="ana" select="'tei'"/>
                        <xsl:for-each select="$teiAttDescSet">
                          <span>
                            <xsl:attribute name="type" select="'definition'"/>
                            <xsl:attribute name="target">
                              <xsl:text>http://www.tei-c.org/release/doc/tei-p5-doc/en/html/ref-</xsl:text>
                              <xsl:value-of select="@ident"/>
                              <xsl:text>.html</xsl:text>
                            </xsl:attribute>
                            <xsl:value-of
                              select="attList/attDef[@ident = $attName]/desc[@xml:lang = 'en']"/>
                            <xsl:if test="@ident != ''">
                              <ident>
                                <xsl:value-of select="@ident"/>
                              </ident>
                            </xsl:if>
                          </span>
                        </xsl:for-each>
                      </div>
                    </xsl:if>
                    <xsl:if test="$attEntries != ''">
                      <div>
                        <xsl:attribute name="type" select="'entry'"/>
                        <xsl:attribute name="ana" select="'project'"/>
                        <xsl:copy-of select="$attEntries/div[@type = 'entry']/child::node()"/>
                      </div>
                    </xsl:if>
                  </div>
                </xsl:if>
              </xsl:for-each>

            </xsl:for-each>

          </body>
        </text>
      </TEI>
    </xsl:variable>
    <xsl:if test="$outputFormat = 'tei'">
      <xsl:result-document href="{$teiOutPath}">
        <xsl:copy-of select="$intermediate_TEI"/>
      </xsl:result-document>
    </xsl:if>
    <xsl:apply-templates select="$intermediate_TEI" mode="TEI2HTML"/>
  </xsl:template>

  <xsl:template match="/" mode="TEI2HTML">
    <html xmlns="http://www.w3.org/1999/xhtml">
      <head>
        <title>
          <xsl:choose>
            <xsl:when test="$dictAvail = 'yes'">
              <xsl:value-of select="document($dictFile)//titleStmt/title"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:text>Data Dictionary</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </title>
        <style type="text/css">
          .body{
          width:700px;
          margin-left:auto;
          margin-right:auto;
          }
          
          /* unvisited link */
          a:link {
          text-decoration: none;
          color: #29aba4;
          }
          /* visited link */
          a:visited {
          text-decoration: none;
          color: #29aba4;
          }
          /* mouse over link */
          a:hover {
          text-decoration: none;
          color: #171409;
          /*border-bottom: 0.125em solid #000;*/
          background-color: #29aba4;
          padding: 4px;
          color: #FFF;
          }
          /* selected link */
          a:active {
          color: #FFF;
          }
          
          /* Bulleted Items */
          ul{list-style-type: none; margin: 0; padding: 0;}
          
          /* Back to top botton */
          .go-top{
          font-family: 'Martel', serif;
          position: fixed;
          bottom: 2em;
          right: 2em;
          text-decoration: none;
          background-color: #eb7260;
          padding: 15px;
          border: none!important;
          color: #FFF!important;
          opacity: 0.8;
          }
          .go-top:hover{
          font-family: 'Martel', serif;
          opacity: 1;
          position: fixed;
          text-decoration: none;
          background-color: #eb7260;
          padding: 15px;
          border: none!important;
          color: #FFF!important;
          opacity: 1;
          }
          .title{
          font-size:xx-large;
          font-weight:bold;
          margin-top:50px;
          }
          .header{
          padding-top:0.5em;
          font-family: 'Martel', serif;
          font-size: 12px;
          border-bottom: solid 1px lightgray;
          margin-bottom: 16px;
          margin-top: 70px;
          /* This forces section to break to the next line regardless of floats */
          clear: both;
          
          }
          /* Hero cover potion */
          .hero{  
          width:100%;
          background-color: #48A6A1;
          margin: 0px;
          }
          /* Description Paragraph */
          .tagline{  
          width:700px;
          margin-left:auto;
          margin-right:auto;
          margin-bottom:50px;
          margin-top:0px;
          padding: 55px 0px 55px 0px;
          font-family: 'Martel', serif;
          font-size: 26px;
          color: #FFF;
          }
          /* Table of Contents */
          .attributeTOCLink{font-size: 18px;}
          .elementTOCLink{color: gray;}
          
          /* Columns */
          div.columns       { width: 700px; font-size: 20px; line-height: 32px;}
          div.columns div   { width: 155px;  float: left; }
          div.grey          { background-color: white; }
          div.red           { background-color: #white; }
          div.clear         { clear: both; }
          
          .name{
          font-size:large;
          font-weight:700;
          font-size:40px;
          }
          .count{
          width:50px;
          display:inline-block;
          float:right;
          text-align:right;
          padding-right:0.5em;
          font-size:medium;
          }
          .project{
          font-size:medium;
          margin-top:.5em;
          
          }
          .tei_guidelines{
          font-size:medium;
          margin-top:.5em;
          
          }
          .tei_description{
          font-family: 'Martel', serif;
          font-family: 
          font-size:medium;
          padding-bottom: 10px;
          display: block;
          }
          .label{
          font-family: 'Martel', serif;
          font-weight:900;
          font-size: 15px;
          }
          .tei_link{
          font-size:medium;
          font-style:italic;
          }
          
          .entry_contents_local{
          font-size:medium;
          margin-top:.5em;
          
          }
          .local_description{
          font-size:medium;
          font-family: 'Martel', serif;
          display: block;
          padding-bottom: 10px;
          }
          
          .see_also{
          font-size:medium;
          font-family: 'Martel', serif;
          display: inline;
          padding-bottom: 10px;
          }
          .see_also_label{
          font-size:medium;
          font-family: 'Martel', serif;
          font-style:italic;
          display: inline;
          padding-bottom: 10px;
          }
          
          .usage{
          font-size:medium;
          font-family: 'Martel', serif;
          display: inline;
          padding-bottom: 10px;
          }
          .usage_label{
          font-size:medium;
          font-family: 'Martel', serif;
          font-style:italic;
          display: inline;
          padding-bottom: 10px;
          }
          
          .examples{
          font-size:medium;
          font-family: 'Martel', serif;
          display: block;
          padding-bottom: 10px;
          }
          .entry_struct_notes{
          font-size:medium;
          margin-top:0em;
          margin-left:0.5em;
          }
          .struct_note_marker{
          font-weight:600;
          }
          .entry_local_contained_by{
          font-size:medium;
          }
          .entry_local_may_contain{
          font-size:medium;
          }
          .entry_local_attributes{
          font-size:medium;
          }
          
          /* Styles for 3 boxes under each element */
          .context{line-height: 25px; }
          .attributes {overflow: auto;margin-bottom: 15px; float: left; padding-right: 30px;}
          .parents{overflow: auto; margin-bottom: 15px; float: left; padding-right: 30px;}
          .children{overflow: auto; margin-bottom: 15px;}
          
          /* Handling of example XML code embedded in pages. */
          
          pre.teiCode{
          white-space:pre-wrap;
          border-top: solid lightgray 1px;
          border-bottom: solid lightgray 1px;
          padding: 13px 0px 0px 20px;
          background-color: #f2ede7;
          } 
          
          /* Divider between name and gloss */
          .divider{color:lightgray; font-size: 40px;}
          
          /* We want our XML code to look like code. */
          .xmlTag,
          .xmlAttName,
          .xmlAttVal,
          .teiCode{
          font-family:monospace;
          } 
          
          /* We want our XML code text to be bold. */
          .xmlTag,
          .xmlAttName,
          .xmlAttVal{
          font-weight:bold;
          } 
          
          /* We want syntax highlighting. */
          .xmlTag{
          color:#000099;
          }
          .xmlAttName{
          color:#f5844c;
          }
          .xmlAttVal{
          color:#993300;
          }
          
          
          /* Joe's new tags (Sean: please keep and/or tweak) */
          .giTag{
          color:#000099;
          font-size:medium;
          font-size:18px;
          font-family:monospace;
          }
          .attTag{
          color:#f5844c;
          font-size:medium;
          font-size:18px;
          font-family:monospace;
          }
          .gloss{
          color:#48A6A1;
          font-size:large;
          font-size:30px;
          font-weight:300;
          }
        </style>
        <link href="http://fonts.googleapis.com/css?family=Martel:400,200,300,600,800,700,900"
          rel="stylesheet" type="text/css"/>
      </head>
      <body>
        <div class="hero">
          <div class="tagline">
            <h1>
              <xsl:value-of select="//titleStmt/title[@type = 'main']"/>
            </h1>
            <xsl:value-of select="//sourceDesc/p[1]"/>
            <br/>
            <xsl:text>Last updated: </xsl:text>
            <xsl:value-of select="format-date(current-date(), '[MNn] [D1], [Y1]')"/>
          </div>
        </div>
        <div class="body">
          <xsl:variable name="eListCount"
            select="count(distinct-values(//div[@type = 'element']/@corresp))"/>
          <xsl:variable name="eListColQuant" select="round(($eListCount div 3))"/>
          <xsl:variable name="eListColTwo" select="$eListColQuant * 2"/>

          <div class="columns">
            <div class="red">
              <xsl:variable name="elementList"
                select="distinct-values(//div[@type = 'element']/@corresp)"/>
              <ul>
                <xsl:for-each select="$elementList">
                  <xsl:if test="position() lt ($eListColQuant + 1)">
                    <li>
                      <a>
                        <xsl:attribute name="href">
                          <xsl:text>#e.</xsl:text>
                          <xsl:value-of select="."/>
                        </xsl:attribute>
                        <xsl:value-of select="."/>
                      </a>
                    </li>
                  </xsl:if>
                  <xsl:text> </xsl:text>
                </xsl:for-each>
              </ul>
            </div>
            <div class="red">
              <xsl:variable name="elementList"
                select="distinct-values(//div[@type = 'element']/@corresp)"/>
              <ul>
                <xsl:for-each select="$elementList">
                  <xsl:if
                    test="(position() gt $eListColQuant) and (position() lt ($eListCount - $eListColQuant + 1))">
                    <li>
                      <a>
                        <xsl:attribute name="href">
                          <xsl:text>#e.</xsl:text>
                          <xsl:value-of select="."/>
                        </xsl:attribute>
                        <xsl:value-of select="."/>
                      </a>
                    </li>
                  </xsl:if>
                  <xsl:text> </xsl:text>
                </xsl:for-each>
              </ul>
            </div>
            <div class="red">
              <xsl:variable name="elementList"
                select="distinct-values(//div[@type = 'element']/@corresp)"/>
              <ul>
                <xsl:for-each select="$elementList">
                  <xsl:if test="position() gt ($eListCount - $eListColQuant)">
                    <li>
                      <a>
                        <xsl:attribute name="href">
                          <xsl:text>#e.</xsl:text>
                          <xsl:value-of select="."/>
                        </xsl:attribute>
                        <xsl:value-of select="."/>
                      </a>
                    </li>
                  </xsl:if>
                  <xsl:text> </xsl:text>
                </xsl:for-each>
              </ul>
            </div>
            <div class="grey">
              <xsl:variable name="attributeList"
                select="distinct-values(//div[@type = 'attribute']/@corresp)"/>
              <ul>
                <xsl:for-each select="$attributeList">
                  <li>
                    <a>
                      <xsl:attribute name="class" select="'attributeTOCLink'"/>
                      <xsl:attribute name="href">
                        <xsl:text>#a.</xsl:text>
                        <xsl:value-of select="."/>
                      </xsl:attribute>
                      <xsl:text>@</xsl:text>
                      <xsl:value-of select="."/>
                    </a>
                  </li>
                  <xsl:text> </xsl:text>
                </xsl:for-each>
              </ul>
            </div>
          </div>
          <div class="clear"/>
          <xsl:apply-templates select="//div[@type = 'element']" mode="TEI2HTML"/>
          <hr/>
          <xsl:apply-templates select="//div[@type = 'attribute']" mode="TEI2HTML"/>
        </div>
        <div>
          <a href="#" class="go-top">Back to top</a>
        </div>
      </body>
    </html>
  </xsl:template>

  <xsl:template match="div" mode="TEI2HTML">
    <div class="entry">
      <xsl:attribute name="id">
        <xsl:if test="@type = 'element'">
          <xsl:text>e.</xsl:text>
        </xsl:if>
        <xsl:if test="@type = 'attribute'">
          <xsl:text>a.</xsl:text>
        </xsl:if>
        <xsl:value-of select="@corresp"/>
      </xsl:attribute>

      <div class="header">
        <span class="name">
          <xsl:if test="@type eq 'attribute'">
            <xsl:text>@</xsl:text>
          </xsl:if>
          <xsl:value-of select="@corresp"/>
        </span>
        <xsl:if test="ab[@type eq 'gloss']">
          <span class="gloss">
            <span class="divider">
              <xsl:value-of select="$pipe"/>
            </span>
            <xsl:value-of select="ab[@type = 'gloss']"/>
          </span>
        </xsl:if>
        <xsl:if test="ab[@type eq 'count']">
          <span class="count">
            <xsl:value-of select="ab[@type = 'count']"/>
          </span>
        </xsl:if>
      </div>
      <div class="descriptions">
        <xsl:apply-templates select="div[@ana = 'tei']" mode="TEI2HTML"/>
        <xsl:apply-templates select="div[@ana = 'project']" mode="TEI2HTML"/>
      </div>
      <div class="context">
        <xsl:apply-templates select="ab[@type = 'attributes']" mode="TEI2HTML"/>
        <xsl:apply-templates select="ab[@type = 'parents']" mode="TEI2HTML"/>
        <xsl:apply-templates select="ab[@type = 'children']" mode="TEI2HTML"/>
      </div>

    </div>
  </xsl:template>

  <xsl:template match="div[@ana = 'project']" mode="TEI2HTML">
    <div>
      <span class="label">Project: </span>
      <span class="local_description">
        <xsl:for-each select="span[@type = 'definition']">
          <xsl:apply-templates/>
          <xsl:if test="position() lt last()">
            <xsl:value-of select="$bullet"/>
          </xsl:if>
        </xsl:for-each>
        <xsl:if test="span[@type = 'usage']">
          <span class="usage_label">
            <xsl:text> Usage: </xsl:text>
          </span>
          <span class="usage">
            <xsl:for-each select="span[@type = 'usage']">
              <xsl:apply-templates/>
              <xsl:choose>
                <xsl:when test="position() != last()">
                  <xsl:value-of select="$bullet"/>
                </xsl:when>
              </xsl:choose>
            </xsl:for-each>
          </span>
        </xsl:if>
        <xsl:if test="span[@type = 'seeAlso']">
          <span class="see_also_label">
            <xsl:text> See also: </xsl:text>
          </span>
          <span class="see_also">
            <xsl:for-each select="span[@type = 'seeAlso']/*">
              <a>
                <xsl:attribute name="href">
                  <xsl:if test="./name() eq 'gi'">
                    <xsl:text>#e.</xsl:text>
                  </xsl:if>
                  <xsl:if test="./name() eq 'att'">
                    <xsl:text>#a.</xsl:text>
                  </xsl:if>
                  <xsl:value-of select="."/>
                </xsl:attribute>
                <xsl:if test="./name() eq 'att'">
                  <xsl:text>@</xsl:text>
                </xsl:if>
                <xsl:value-of select="."/>
              </a>
              <xsl:choose>
                <xsl:when test="position() != last()">
                  <xsl:text>, </xsl:text>
                </xsl:when>
              </xsl:choose>
            </xsl:for-each>
          </span>
        </xsl:if>
      </span>
      <div class="examples">
        <xsl:if test="teix:egXML">
          <span class="label">Example(s): </span>
        </xsl:if>
        <xsl:apply-templates select="teix:egXML"/>
      </div>
    </div>
  </xsl:template>

  <xsl:template match="ref">
    <a>
      <xsl:attribute name="href" select="@target"/>
      <xsl:attribute name="target" select="'_blank'"/>
      <xsl:apply-templates/>
    </a>
  </xsl:template>


  <xsl:template match="div[@ana = 'tei']" mode="TEI2HTML">
    <div>
      <span class="label">P5 Guidelines: </span>
      <span class="tei_description">
        <xsl:for-each select="span[@type = 'definition']">
          <xsl:apply-templates mode="TEI2HTML"/>
          <xsl:text> </xsl:text>
          <a>
            <xsl:attribute name="target" select="'_blank'"/>
            <xsl:attribute name="href" select="@target"/>
            <xsl:text>[more]</xsl:text>
          </a>
          <xsl:if test="position() lt last()">
            <xsl:value-of select="$bullet"/>
          </xsl:if>
          <xsl:if test="$displayModule = 'true'">
            <xsl:text> Module: </xsl:text>
            <xsl:value-of select="preceding-sibling::ab[@type = 'module'][1]"/>
            <xsl:text> Class(es): </xsl:text>
            <xsl:value-of select="preceding-sibling::ab[@type = 'classes'][1]/seg"/>
          </xsl:if>
        </xsl:for-each>
      </span>
    </div>
  </xsl:template>

  <xsl:template match="
      ab[@type = ('gloss',
      'count')]" mode="TEI2HTML"/>

  <xsl:template match="
      ab[@type = ('parents',
      'children')]" mode="TEI2HTML">
    <div>
      <xsl:attribute name="class">
        <xsl:if test="@type = 'parents'">
          <xsl:value-of select="'parents'"/>
        </xsl:if>
        <xsl:if test="@type = 'children'">
          <xsl:value-of select="'children'"/>
        </xsl:if>
      </xsl:attribute>
      <xsl:if test="@type = 'parents'">
        <span class="label">Contained by: </span>
      </xsl:if>
      <xsl:if test="@type = 'children'">
        <span class="label">May contain: </span>
      </xsl:if>
      <ul>
        <xsl:choose>
          <xsl:when test="(@type = 'children') and (parent::div[@type = 'attribute'])">
            <li>
              <xsl:value-of select="."/>
            </li>
          </xsl:when>
          <xsl:otherwise>
            <xsl:for-each select="seg">
              <li>
                <a>
                  <xsl:attribute name="href" select="@ana"/>
                  <xsl:attribute name="target" select="'_self'"/>
                  <xsl:value-of select="."/>
                </a>
              </li>
            </xsl:for-each>
          </xsl:otherwise>
        </xsl:choose>
      </ul>
    </div>
  </xsl:template>

  <xsl:template match="ab[@type = 'attributes']" mode="TEI2HTML">
    <div class="attributes">
      <span class="label">Attributes: </span>
      <ul>
        <xsl:for-each select="seg">
          <li>
            <a>
              <xsl:attribute name="href" select="@ana"/>
              <xsl:attribute name="target" select="'_self'"/>
              <xsl:text>@</xsl:text>
              <xsl:value-of select="."/>
            </a>
          </li>
        </xsl:for-each>
      </ul>
    </div>
  </xsl:template>

  <xsl:template match="gi">
    <span class="giTag">
      <xsl:text>&lt;</xsl:text>
      <xsl:apply-templates mode="TEI2HTML"/>
      <xsl:text>&gt;</xsl:text>
    </span>
  </xsl:template>

  <xsl:template match="att">
    <span class="attTag">
      <xsl:text>@</xsl:text>
      <xsl:apply-templates mode="TEI2HTML"/>
    </span>
  </xsl:template>

  <!-- Handling of <egXML> elements in the TEI example namespace. -->
  <xsl:template match="teix:egXML">
    <pre class="teiCode">
      <xsl:apply-templates mode="TEI2HTML"/>
    </pre>
  </xsl:template>

  <!-- Escaping all tags and attributes within the teix (examples) namespace except for the containing egXML. -->
  <xsl:template match="teix:*[not(self::teix:egXML)]" mode="TEI2HTML">
    <!-- Indent based on the number of ancestor elements. -->
    <xsl:variable name="indent">
      <xsl:for-each select="ancestor::teix:*">
        <xsl:text/>
      </xsl:for-each>
    </xsl:variable>
    <!-- Indent before every opening tag if not inside a paragraph. -->
    <xsl:if test="not(ancestor::teix:p)">
      <xsl:value-of select="$indent"/>
    </xsl:if>
    <!-- Opening tag, including any attributes. -->
    <xsl:if test=".[text()]">
      <span class="xmlTag">&lt;<xsl:value-of select="name()"/></span>
      <xsl:for-each select="@*">
        <span class="xmlAttName">
          <xsl:text> </xsl:text>
          <xsl:value-of select="name()"/>=</span>
        <span class="xmlAttVal">"<xsl:value-of select="."/>"</span>
      </xsl:for-each>
      <span class="xmlTag">&gt;</span>
      <!-- Return before processing content, if not inside a p. -->
      <xsl:if test="not(ancestor::teix:p)">
        <xsl:text> </xsl:text>
      </xsl:if>
      <xsl:apply-templates select="* | text() | comment()" mode="TEI2HTML"/>
      <!-- Closing tag, following indent if not in a p. -->
      <xsl:if test="not(ancestor::teix:p)">
        <xsl:value-of select="$indent"/>
      </xsl:if>
      <span class="xmlTag">&lt;/<xsl:value-of select="local-name()"/>&gt;</span>
      <!-- Return after closing tag, if not in a p. -->
      <xsl:if test="not(ancestor::teix:p)">
        <xsl:text> </xsl:text>
      </xsl:if>
    </xsl:if>
    <!-- Process Empty Elements Differently -->
    <xsl:if test=".[not(text())]">
      <span class="xmlTag">&lt;<xsl:value-of select="name()"/></span>
      <xsl:for-each select="@*">
        <span class="xmlAttName">
          <xsl:text> </xsl:text>
          <xsl:value-of select="name()"/>=</span>
        <span class="xmlAttVal">"<xsl:value-of select="."/>"</span>
      </xsl:for-each>
      <xsl:apply-templates select="* | text() | comment()" mode="TEI2HTML"/>
      <!-- Closing tag, following indent if not in a p. -->
      <xsl:if test="not(ancestor::teix:p)">
        <xsl:value-of select="$indent"/>
      </xsl:if>
      <span class="xmlTag">/&gt;</span>
      <!-- Return after closing tag, if not in a p. -->
      <xsl:if test="not(ancestor::teix:p)">
        <xsl:text> </xsl:text>
      </xsl:if>
    </xsl:if>
  </xsl:template>
  <!-- For good-looking tree output, we need to include a return after any text content, assuming we're not inside a paragraph tag. -->
  <xsl:template match="teix:*/text()" mode="TEI2HTML">
    <xsl:if test="not(ancestor::teix:p)">
      <xsl:for-each select="ancestor::teix:*">
        <xsl:text/>
      </xsl:for-each>
    </xsl:if>
    <xsl:value-of select="replace(., '&amp;', '&amp;amp;')"/>
    <xsl:if test="not(ancestor::teix:p) or not(following-sibling::* or following-sibling::text())">
      <xsl:text> </xsl:text>
    </xsl:if>
  </xsl:template>

</xsl:stylesheet>
