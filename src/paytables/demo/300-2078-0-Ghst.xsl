<?xml version="1.0" encoding="UTF-8"?><xsl:stylesheet version="1.0" exclude-result-prefixes="java" extension-element-prefixes="my-ext" xmlns:lxslt="http://xml.apache.org/xslt" xmlns:java="http://xml.apache.org/xslt/java" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:my-ext="ext1">
<xsl:import href="HTML-CCFR.xsl"/>
<xsl:output indent="no" method="xml" omit-xml-declaration="yes"/>
<xsl:template match="/">
<xsl:apply-templates select="*"/>
<xsl:apply-templates select="/output/root[position()=last()]" mode="last"/>
<br/>
</xsl:template>
<lxslt:component prefix="my-ext" functions="formatJson retrievePrizeTable retrievePatternWins">
<lxslt:script lang="javascript">
					
					var debugFeed = [];
					var debugFlag = false;					
					
					// Format instant win JSON results.
					// @param jsonContext String JSON results to parse and display.
					// @param bingoColumns String of Bingo Symbols.
					function formatJson(jsonContext, translations, prizeTable, prizeValues, prizeNames)
					{
						var scenario = getScenario(jsonContext);
						var patternWins = (prizeValues.substring(1)).split('|');
						var prizeLetterList = 'A,B,C,D,E,F';
						
						var index = 1;
						registerDebugText("Translation Table");
						while(index &lt; translations.item(0).getChildNodes().getLength())
						{
							var childNode = translations.item(0).getChildNodes().item(index);
							registerDebugText(childNode.getAttribute("key") + ": " +  childNode.getAttribute("value"));
							index += 2;
						}
						registerDebugText("Prize Table");
						
						var r = [];
						
						var revealList = scenario.split("|");
						r.push('&lt;table border="0" cellpadding="2" cellspacing="1" width="100%" class="gameDetailsTable" style="table-layout:fixed;overflow-x:scroll"&gt;');
						r.push('&lt;tr&gt;');
						r.push('&lt;td class="tablehead"&gt;');
						r.push(getTranslationByName("reveal", translations));
						r.push('&lt;/td&gt;');
						r.push('&lt;td class="tablehead"&gt;');
						r.push(getTranslationByName("prizeAmount", translations));
						r.push('&lt;/td&gt;');
						r.push('&lt;/tr&gt;');
						
						for(var i = 0; i &lt; revealList.length; i++){
							r.push('&lt;tr&gt;');
							r.push('&lt;td class="tablebody"&gt;');
							r.push(handleRevealType(revealList[i],translations));
							r.push('&lt;/td&gt;');
							r.push('&lt;td class="tablebody"&gt;');
							r.push(handleRevealValue(revealList[i],prizeLetterList,patternWins,translations));
							r.push('&lt;/td&gt;');
							r.push('&lt;/tr&gt;');
						}
						
						r.push('&lt;/table&gt;');
						
						////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
						// !DEBUG OUTPUT TABLE
						if(debugFlag)
						{
							// DEBUG TABLE
							//////////////////////////////////////
							r.push('&lt;table border="0" cellpadding="2" cellspacing="1" width="100%" class="gameDetailsTable" style="table-layout:fixed"&gt;');
							for(var idx = 0; idx &lt; debugFeed.length; ++idx)
							{
								r.push('&lt;tr&gt;');
								r.push('&lt;td class="tablebody"&gt;');
								r.push(debugFeed[idx]);
								r.push('&lt;/td&gt;');
								r.push('&lt;/tr&gt;');
							}
							r.push('&lt;/table&gt;');
						}

						return r.join('');
					}
					
					// Input: Json document string containing 'scenario' at root level.
					// Output: Scenario value.
					function getScenario(jsonContext)
					{
						// Parse json and retrieve scenario string.
						var jsObj = JSON.parse(jsonContext);
						var scenario = jsObj.scenario;

						// Trim null from scenario string.
						scenario = scenario.replace(/\0/g, '');

						return scenario;
					}
					
					// Input: Json document string containing 'amount' at root level.
					// Output: Price Point value.
					function getPricePoint(jsonContext)
					{
						// Parse json and retrieve price point amount
						var jsObj = JSON.parse(jsonContext);
						var pricePoint = jsObj.amount;

						return pricePoint;
					}
					
					//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
					// Input: A list of Price Points and the available Prize Structures for the game as well as the wagered price point
					// Output: A string of the specific prize structure for the wagered price point
					function retrievePrizeTable(pricePoints, prizeTables, wageredPricePoint)
					{
						var pricePointList = pricePoints.split(",");
						var prizeTableStrings = prizeTables.split("|");
						
						
						for(var i = 0; i &lt; pricePoints.length; ++i)
						{
							if(wageredPricePoint == pricePointList[i])
							{
								registerDebugText("Price Point " + pricePointList[i] + " table: " + prizeTableStrings[i]);
								return prizeTableStrings[i];
							}
						}
						
						return "";
					}
					
					function checkForLinesPattern(drawnNumbers, bingoCardData, linePatterns)
					{
						var linesAwarded = 0;
						for(var line = 0; line &lt; linePatterns.length; ++line)
						{
							if(checkForExclusivePattern(drawnNumbers, bingoCardData, linePatterns[line]))
							{
								linesAwarded++;
								registerDebugText("Line Pattern Awarded(" + linesAwarded + "): " + linePatterns[line]);
							}
						}
						
						registerDebugText(linesAwarded);
						
						return linesAwarded;
					}
					
					////////////////////////////////////////////////////////////////////////////////////////
					function registerDebugText(debugText)
					{
						debugFeed.push(debugText);
					}
					
					/////////////////////////////////////////////////////////////////////////////////////////
					function getTranslationByName(keyName, translationNodeSet)
					{
						var index = 1;
						while(index &lt; translationNodeSet.item(0).getChildNodes().getLength())
						{
							var childNode = translationNodeSet.item(0).getChildNodes().item(index);
							
							if(childNode.name == "phrase" &amp;&amp; childNode.getAttribute("key") == keyName)
							{
								registerDebugText("Child Node: " + childNode.name);
								return childNode.getAttribute("value");
							}
							
							index += 1;
						}
					}
					
					// Input: "A,B,C,D,..." and "A"
					// Output: index number
					function getPrizeNameIndex(prizeNames, currPrize)
					{
						registerDebugText("Getting index of " + currPrize + " in " + prizeNames);
						var prizes = prizeNames.split(",");
						
						for(var i = 0; i &lt; prizes.length; ++i)
						{
							if(prizes[i] == currPrize)
							{
								return i;
							}
						}
					}
					
					function handleInstantWin(reveal,prizeLetterList,prizeValues){
						var instantWinPrize = reveal.charAt(2);
						var index = getPrizeNameIndex(prizeLetterList, instantWinPrize);
						var instantWinPrizeAmount = prizeValues[index];
						return instantWinPrizeAmount;
						
					}
					
					function handleBonus(reveal,prizeLetterList,prizeValues,translations){
						//Get the last character of the bonus reveal
						var bonusPick = parseInt(reveal.charAt(7));
						//Find the index of the pick
						var bonusListOffset = 1;
						var bonusListIndex = bonusListOffset + bonusPick;
						
						//Determine the letter prize.
						var bonusWinPrize = reveal.charAt(bonusListIndex);
						//If it's an X then this misses right now
						if(bonusWinPrize === 'X'){
							return getTranslationByName("miss", translations);
						}
						//Get the bonus prize value from the letter
						var index = getPrizeNameIndex(prizeLetterList,bonusWinPrize);

						var bonusWinPrizeAmount = prizeValues[index];
						return bonusWinPrizeAmount;
					}
					
					function handleRevealType(reveal,translations){
						switch(reveal.charAt(0)){
						case 'M':
							//Handle Miss
							return getTranslationByName("miss", translations);
							break;
						case 'I':
							//Handle an Instant Win
							return getTranslationByName("instantWin", translations);
							break;
						case 'B':
							//Handle a Bonus Win
							return getTranslationByName("bonus", translations);
							break;
						}
					}	
					
					function handleRevealValue(reveal,prizeLetterList,prizeValues,translations){
						switch(reveal.charAt(0)){
						case 'M':
							//Handle Miss
							return "";
							break;
						case 'I':
							//Handle an Instant Win
							return handleInstantWin(reveal,prizeLetterList,prizeValues);
							break;
						case 'B':
							//Handle a Bonus Win
							return handleBonus(reveal,prizeLetterList,prizeValues,translations);
							break;
						}
					}
					
					
				</lxslt:script>
</lxslt:component>
<xsl:template match="root" mode="last">
<table border="0" cellpadding="1" cellspacing="1" width="100%" class="gameDetailsTable">
<tr>
<td valign="top" class="subheader">
<xsl:value-of select="//translation/phrase[@key='totalWager']/@value"/>
<xsl:value-of select="': '"/>
<xsl:call-template name="Utils.ApplyConversionByLocale">
<xsl:with-param name="multi" select="/output/denom/percredit"/>
<xsl:with-param name="value" select="//ResultData/WagerOutcome[@name='Game.Total']/@amount"/>
<xsl:with-param name="code" select="/output/denom/currencycode"/>
<xsl:with-param name="locale" select="//translation/@language"/>
</xsl:call-template>
</td>
</tr>
<tr>
<td valign="top" class="subheader">
<xsl:value-of select="//translation/phrase[@key='totalWins']/@value"/>
<xsl:value-of select="': '"/>
<xsl:call-template name="Utils.ApplyConversionByLocale">
<xsl:with-param name="multi" select="/output/denom/percredit"/>
<xsl:with-param name="value" select="//ResultData/PrizeOutcome[@name='Game.Total']/@totalPay"/>
<xsl:with-param name="code" select="/output/denom/currencycode"/>
<xsl:with-param name="locale" select="//translation/@language"/>
</xsl:call-template>
</td>
</tr>
</table>
</xsl:template>
<xsl:template match="//Outcome">
<xsl:if test="OutcomeDetail/Stage = 'Scenario'">
<xsl:call-template name="Scenario.Detail"/>
</xsl:if>
</xsl:template>
<xsl:template name="Scenario.Detail">
<table border="0" cellpadding="0" cellspacing="0" width="100%" class="gameDetailsTable">
<tr>
<td class="tablebold" background="">
<xsl:value-of select="//translation/phrase[@key='transactionId']/@value"/>
<xsl:value-of select="': '"/>
<xsl:value-of select="OutcomeDetail/RngTxnId"/>
</td>
</tr>
</table>
<xsl:variable name="odeResponseJson" select="string(//ResultData/JSONOutcome[@name='ODEResponse']/text())"/>
<xsl:variable name="translations" select="lxslt:nodeset(//translation)"/>
<xsl:variable name="wageredPricePoint" select="string(//ResultData/WagerOutcome[@name='Game.Total']/@amount)"/>
<xsl:variable name="prizeTable" select="lxslt:nodeset(//lottery)"/>
<xsl:variable name="convertedPrizeValues">
<xsl:apply-templates select="//lottery/prizetable/prize" mode="PrizeValue"/>
</xsl:variable>
<xsl:variable name="prizeNames">
<xsl:apply-templates select="//lottery/prizetable/description" mode="PrizeDescriptions"/>
</xsl:variable>
<xsl:value-of select="my-ext:formatJson($odeResponseJson, $translations, $prizeTable, string($convertedPrizeValues), string($prizeNames))" disable-output-escaping="yes"/>
</xsl:template>
<xsl:template match="prize" mode="PrizeValue">
<xsl:text>|</xsl:text>
<xsl:call-template name="Utils.ApplyConversionByLocale">
<xsl:with-param name="multi" select="/output/denom/percredit"/>
<xsl:with-param name="value" select="text()"/>
<xsl:with-param name="code" select="/output/denom/currencycode"/>
<xsl:with-param name="locale" select="//translation/@language"/>
</xsl:call-template>
</xsl:template>
<xsl:template match="description" mode="PrizeDescriptions">
<xsl:text>,</xsl:text>
<xsl:value-of select="text()"/>
</xsl:template>
<xsl:template match="text()"/>
</xsl:stylesheet>
