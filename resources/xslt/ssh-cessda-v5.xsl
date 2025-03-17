<?xml version="1.0"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:js="http://www.w3.org/2005/xpath-functions"
    xmlns="http://www.openarchives.org/OAI/2.0/"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:schemaLocation="http://www.openarchives.org/OAI/2.0/ http://www.openarchives.org/OAI/2.0/OAI-PMH.xsd"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:oai="http://www.openarchives.org/OAI/2.0/"
    xmlns:ddi="ddi:codebook:2_5"
    exclude-result-prefixes="xs math" version="3.0">
    
    <xsl:output indent="yes" omit-xml-declaration="no" encoding="UTF-8"/>
    
    <xsl:param name="json-uri" select="()"/>
<!--    <xsl:param name="json-uri" select="'file:/Users/akmi/git/ODISSEI-2024/oai-enricher-service/resources/etc/dvs_json.json'"/>-->
    <xsl:param name="json" select="unparsed-text($json-uri)"/>
    <xsl:param name="json-xml" select="json-to-xml($json)"/>

    <xsl:template match="node() | @*">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="//oai:record">
        <xsl:variable name="pid" select="./oai:header/oai:identifier"/>
        <xsl:variable name="js-dv" select="$json-xml//js:map[normalize-space(js:map[@key='datasetVersion']/js:string[@key='datasetPersistentId']) = $pid]" as="element(js:map)?"/>
        <xsl:choose>
            <xsl:when test="exists($js-dv)">
                <xsl:message>PID:<xsl:value-of select="$pid"/> and identifier = <xsl:value-of select="$js-dv/js:string[@key='identifier']"/></xsl:message>
                <xsl:copy>
                    <xsl:apply-templates select="node() | @*">
                        <xsl:with-param name="js-dv" select="$js-dv" as="element(js:map)?" tunnel="yes"/>
                    </xsl:apply-templates>
                </xsl:copy>
            </xsl:when>
            <xsl:otherwise>
                <xsl:element name="record">
                <xsl:copy-of select="node() | @*"/>
                </xsl:element>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="ddi:citation/ddi:titlStmt/ddi:titl">
        <xsl:param name="js-dv" tunnel="yes"  as="element(js:map)?"/>
        <xsl:copy>
            <xsl:attribute name="xml:lang">
                <xsl:variable name="val" select="$js-dv/js:map/js:map[@key='metadataBlocks']/js:map[@key='dansRights']/js:array[@key='fields']/js:map/js:string[@key='typeName' and text()='dansMetadataLanguage']/following-sibling::js:array[@key='value']/js:string"/>
                <xsl:call-template name="set_lang">
                    <xsl:with-param name="val" select="$val" tunnel="yes"/>
                </xsl:call-template>
            </xsl:attribute>
            <xsl:value-of select="."/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="ddi:distStmt/ddi:distrbtr">
        <xsl:param name="js-dv" tunnel="yes" as="element(js:map)?"/>
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:attribute name="xml:lang">
                <xsl:variable name="val" select="$js-dv/js:map/js:map[@key='metadataBlocks']/js:map[@key='dansRights']/js:array[@key='fields']/js:map/js:string[@key='typeName' and text()='dansMetadataLanguage']/following-sibling::js:array[@key='value']/js:string"/>
                <xsl:call-template name="set_lang">
                    <xsl:with-param name="val" select="$val" tunnel="yes"/>
                </xsl:call-template>
            </xsl:attribute>
            <xsl:apply-templates select="node()"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="ddi:distStmt/ddi:depDate">
        <xsl:message>Removed</xsl:message>
        <!-- Remove it -->
    </xsl:template>

    <xsl:template match="ddi:dataAccs">
        <xsl:copy>
            <xsl:apply-templates select="ddi:setAvail"/>
            <xsl:apply-templates select="ddi:useStmt"/>
            <xsl:apply-templates select="ddi:notes"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="ddi:distStmt/ddi:distDate">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:attribute name="date">
                <xsl:value-of select="."/>
            </xsl:attribute>
            <xsl:apply-templates select="node()"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="ddi:subject" xmlns="ddi:codebook:2_5" xpath-default-namespace="http://www.w3.org/2005/xpath-functions">
        <xsl:param name="js-dv" tunnel="yes" as="element(js:map)?"/>
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:for-each select="$js-dv/js:map/js:map[@key='metadataBlocks']/js:map[@key='dansSocialSciences']/js:array[@key='fields']/js:map/js:string[@key='typeName' and text()='dansElsstClassification']/following-sibling::js:array[@key='value']/js:string">
                <xsl:variable name="kw"  select="."/>
                <xsl:element name="keyword">
                    <xsl:attribute name="xml:lang">en</xsl:attribute>
                    <xsl:attribute name="vocab">ELSST</xsl:attribute>
                    <xsl:attribute name="vocabURI" select="$kw"/>
                    <xsl:value-of select="../following-sibling::js:array[@key='expandedvalue']/js:map/js:string[@key='@id' and text()=$kw]/following-sibling::js:array/js:map/js:string[@key='lang' and text()='en']/following-sibling::js:string[@key='value']"/>
                </xsl:element>
            </xsl:for-each>
            <xsl:apply-templates select="node()"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="ddi:subject/ddi:keyword[normalize-space(@xml:lang)='']">
        <xsl:param name="js-dv" tunnel="yes" as="element(js:map)?"/>
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:attribute name="xml:lang">
                <xsl:variable name="val" select="$js-dv/js:map/js:map[@key='metadataBlocks']/js:map[@key='dansRights']/js:array[@key='fields']/js:map/js:string[@key='typeName' and text()='dansMetadataLanguage']/following-sibling::js:array[@key='value']/js:string"/>
                <xsl:call-template name="set_lang">
                    <xsl:with-param name="val" select="$val" tunnel="yes"/>
                </xsl:call-template>
            </xsl:attribute>
            <xsl:apply-templates select="node()"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="ddi:stdyInfo/ddi:abstract">
        <xsl:param name="js-dv" tunnel="yes" as="element(js:map)?"/>
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:attribute name="xml:lang">
                <xsl:variable name="val" select="$js-dv/js:map/js:map[@key='metadataBlocks']/js:map[@key='dansRights']/js:array[@key='fields']/js:map/js:string[@key='typeName' and text()='dansMetadataLanguage']/following-sibling::js:array[@key='value']/js:string"/>
                <xsl:call-template name="set_lang">
                    <xsl:with-param name="val" select="$val" tunnel="yes"/>
                </xsl:call-template>
            </xsl:attribute>
            <xsl:apply-templates select="node()"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template name="set_lang">
        <xsl:param name="val" tunnel="yes"/>
        <xsl:variable name="val-string" select="string-join($val, ' ')" />
        <xsl:message><xsl:value-of select="$val-string"/></xsl:message>
        <xsl:choose>
            <xsl:when test="contains($val-string, 'English')">
                <xsl:value-of select="'en'"/>
            </xsl:when>
            <xsl:when test="contains($val-string, 'Dutch') and not(contains($val, 'English'))">
                <xsl:value-of select="'nl'"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="'en'"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

</xsl:stylesheet>