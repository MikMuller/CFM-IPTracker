<!---
ColdFusion IPTracker, by Michael Muller, MontagueWebWorks.com, October 2020.
This code was written on Lucee 5.3.2.77 but should work on any CFM engine.
You are free to use this code as you see fit. Absoutely free.
If you make any improvements, contact tech@montaguewebworks.com

The intention of this app is to track the IP numbers hitting your server and automatically block overly aggressive requestors.

You should place this file in your tags folder along with _iptrack-site.cfm.

Read more notes in _iptrack-site.cfm
--->

<!--- create the iptracker variable struct --->
<cfif not isDefined("server.iptrack")>
	<cfset server.iptrack = structNew()>
</cfif>

<!--- ===================================================================== --->
<!--- set up some iptrack variables --->
<!--- ===================================================================== --->

<!---
Time in minutes to hold IP numbers in the tracking query object.
Number ** MUST ** be a negative, ie; -2, or the table will never be culled/purged and will continue to grow.
Also, unless you have tons of memory and cpu, keep this number low.
Math: If each record is about 150 bytes, a busy server that averages 20+ page loads per second will reach 1200 records (180kb) in 1 minute.
Question: How robust is your server to QoQ this table up to 20 times per second, or more?
--->
<cfset server.iptrack.iptracktime = -2><!--- MUST be a negative number, in minutes --->

<!---
Number of times an IP can appear in iptracker table before getting blocked.
For instance, more than 100 page requests in 2 minutes? more than 200 in 5 minutes?
When you first install this, you should spend some time reviewing the traffic shown in _iptrack-console.cfm
--->
<cfset server.iptrack.maxtrack = 100>

<!---
Time in minutes to hold IP numbers in the blocking query object.
Number ** MUST ** be a negative, ie; -60, or the table will never be culled and will continue to grow.
That said, the blocker query object will likely not grow too big, unless your server is under DDoS attack.
Also, in the console script, you have the ability to permanently whitelist or blacklist any blocked IP numbers,
which will remove them from the ipblocker query object:
	o whitelist IP numbers of clients who work in a building using a single IP for all staff may get caught in the blocker
	o blacklist IP numbers of authentic hackers and other nefarious ne'er do wellers
--->
<cfset server.iptrack.ipblocktime = -60><!--- MUST be a negative number, in minutes --->

<!--- location to hold permanent ipwhitelist, ipblacklist, useragent and url blacklist text files --->
<cfset server.iptrack.folder = "D:\sites">

<!--- standardize the date time variable across this script --->
<cfset server.iptrack.noww = "#dateFormat(now(),"yyyy-mm-dd")# #timeFormat(now(),"HH:mm:ss")#">

<!--- personal message to display if the visitor is blocked --->
<cfset server.iptrack.blockmessage = "If you feel this is an error, call Montague WebWorks 320.5336">

<!--- enter in your current IP number to seed the whitelist if it doesn't already exist --->
<cfset server.iptrack.myipnumber = "">


<!--- ===================================================================== --->
<!--- create the query objects --->
<!--- ===================================================================== --->

<cftry>

	<cfif not isDefined("server.iptrack.iptracker")>
		<!--- query object that stores all IP traffic --->
		<!--- this query object holds IP numbers for server.iptrack.iptracktime minutes, set above --->
		<cfset server.iptrack.iptracker = queryNew("ip,datetime,site,useragent,script","varchar,varchar,varchar,varchar,varchar")>
	</cfif>

	<cfif not isDefined("server.iptrack.ipblocker")>
		<!--- query object that stores all automatically temporarily blocked IP traffic (not blacklisted) --->
		<!--- this query object holds blocked IP numbers for server.iptrack.ipblocktime minutes, set above --->
		<cfset server.iptrack.ipblocker = queryNew("ip,datetime,keep","varchar,varchar,numeric")>
	</cfif>

	<cfif not isDefined("server.iptrack.ipwhitelist")>
		<!--- IP whitelist in comma delim list text file for permanent storage --->
		<!--- this list is typically for your clients who operate out of a building with a single IP and visit their site a lot, which could trigger a blocking --->
		<cftry>
			<cffile action="read" file="#server.iptrack.folder#\ip-whitelist.txt" variable="theFile">
			<cfset server.iptrack.ipwhitelist = thefile>
			<cfcatch type="any">
				<cfset server.iptrack.ipwhitelist = server.iptrack.myipnumber><!--- defaults to your IP number, set above --->
				<cffile action="write" file="#server.iptrack.folder#\ip-whitelist.txt" source="#server.iptrack.ipwhitelist#">
			</cfcatch>
		</cftry>
	</cfif>

	<cfif not isDefined("server.iptrack.ipblacklist")>
		<!--- IP blacklist in comma delim list --->
		<cftry>
			<cffile action="read" file="#server.iptrack.folder#\ip-blacklist.txt" variable="theFile">
			<cfset server.iptrack.ipblacklist = thefile>
			<cfcatch type="any">
				<cfset server.iptrack.ipblacklist = "">
				<cffile action="write" file="#server.iptrack.folder#\ip-blacklist.txt" source="#server.iptrack.ipblacklist#">
			</cfcatch>
		</cftry>
	</cfif>

	<cfif not isDefined("server.iptrack.uablacklist")>
		<!--- user agent blacklist in pipe | delim list for REFindNoCase use, primarily for bad bots and spiders who ignore robots.txt --->
		<!--- be careful not to add any UA with a slash / or other special characters, which can be found in your OWN user agent. just whole-word text --->
		<!--- after installing this app, spend some time reviewing the tracking table to see what kinds of bots are hitting your server --->
		<cftry>
			<cffile action="read" file="#server.iptrack.folder#\ua-blacklist.txt" variable="theFile">
			<cfset server.iptrack.uablacklist = thefile>
			<cfcatch type="any">
				<!--- these user agents seem to always trouble me, so I put them in here for you. --->
				<cfset server.iptrack.uablacklist = "AhrefsBot|aiHitBot|Anemone|Baidu|bezeqint|Blog Search|CareerBot|CCBot|cmscrawler|copyscape|DotBot|EasouSpider|Ezooms|FatBot|FunWebProducts|Genieo|goo.ne|Mail.RU|majestic|mj12bot|NaverBot|NetcraftSurveyAgent|NerdyBot|panopta|Semalt|semrush|SEOkicks-Robot|seoprofiler|SISTRIX|Sogou|TurnitinBot|TwengaBot|Yandex|Youdao|Yodao">
				<cffile action="write" file="#server.iptrack.folder#\ua-blacklist.txt" source="#server.iptrack.uablacklist#">
			</cfcatch>
		</cftry>
	</cfif>

	<cfif not isDefined("server.iptrack.urlblacklist")>
		<!--- url blacklist in pipe | delim list for REFindNoCase use, primarily for bad bots and spiders who ignore robots.txt --->
		<cftry>
			<cffile action="read" file="#server.iptrack.folder#\url-blacklist.txt" variable="theFile">
			<cfset server.iptrack.urlblacklist = thefile>
			<cfcatch type="any">
				<!--- I get thousands of spiders / hackers looking for wordpress files on my server, so let's start with these. --->
				<cfset server.iptrack.urlblacklist = ".env|wp-admin">
				<cffile action="write" file="#server.iptrack.folder#\url-blacklist.txt" source="#server.iptrack.urlblacklist#">
			</cfcatch>
		</cftry>
	</cfif>

	<cfcatch>
		<!---<cfdump var="#cfcatch#">--->
	</cfcatch>
</cftry>
