<!---
ColdFusion IPTracker, by Michael Muller, MontagueWebWorks.com, October 2020.
This code was written on Lucee 5.3.2.77 but should work on any CFM engine.
You are free to use this code as you see fit. Absoutely free.
If you make any improvements, contact tech@montaguewebworks.com

The intention of this app is to track the IP numbers hitting your server and automatically block overly aggressive requestors.
What makes this approach better than others is that it only tracks CFM page requests, and not images, css, js, etc. (unless you have a CFM-based 404 script)

You should place this file (as well as _iptrack-site-config.cfm) in your tags folder and call it from the top of every application.cfm on your server.
To repeat: this file, and _iptrack-site-config.cfm, should be stored in only one place on your server, and called from everywhere you want to use it.
Otherwise you may wind up with different config settings for different sites, which will produce potentially unwanted behavior.

All query tables and variables are stored in server.iptrack[] structure.
o We create a tracking query object and a blocking query object (tables) for a temporary hold.
o We create a IP whitelist and blacklist text files for long-term hold and store them in a server var for use.
o We also create a user agent (UA) blacklist, as well as URL snippet blacklist text file for long-term hold and store them in a server var for use.

We look through the tracking query table on every page request on your server to see if they exceed an acceptable threashold.
If they exceed x number of page requests in y number of minutes, the IPnumber is inserted into the blocking table.

If you also use the _IPTrack-console.cfm file you will have access to edit the whitelist, blacklist, UA black list and URL snippet blacklist.
You can view the IP numbers currently blocked, and can either send them to the whitelist or blacklist.
You can view the current IP Track list, which holds as many minutes of traffic as you've set it to hold.
If you see any hacking attempts, like /wp-admin/ or snarky spiders, you can add them to the URL snippet and UA blacklists.
--->

<!--- ===================================================================== --->
<!--- set up some variables --->
<!--- ===================================================================== --->

<cfinclude template="_iptrack-site-config.cfm">


<!--- ===================================================================== --->
<!--- now we get down to it --->
<!--- ===================================================================== --->

<!--- are you in our ipwhitelist? --->
<cfif not listFind(server.iptrack.ipwhitelist,cgi.remote_addr)>
	<!--- if you're not, we take a closer look --->

	<!--- first lets check their user agent to see if we don't like them --->
	<cfif REFindNoCase(server.iptrack.uablacklist,cgi.http_user_agent) or len(trim(cgi.http_user_agent)) eq 0>
		<!--- visitor has a user agent in our pipe-delim | ua blacklist, or an empty user agent, so we just abort --->
		<cfoutput>
			<html>
				<body>
					<div style="text-align:center;background:##ffa;margin:20px;padding:20px;border:20px solid red;">
						<h1>Blocked!</h1>
						<p>Sorry, you appear to be a bad bot.</p>
						<p>#server.iptrack.blockmessage#</p>
					</div>
					<!---
					<p>#REFindNoCase(server.iptrack.uablacklist,cgi.http_user_agent)#</p>
					<p>#server.iptrack.uablacklist#</p>
					<p>#cgi.http_user_agent#</p>
					--->
				</body>
			</html>
		</cfoutput>
		<cfabort>
	</cfif>

	<!--- now lets check their URL request to see if we don't like what they're asking for --->
	<cfif REFindNoCase(server.iptrack.urlblacklist,cgi.script_name & "?" & cgi.query_string)>
		<!--- visitor is requesting a URL that has a snippet in our pipe-delim | url blacklist, so we just abort --->
		<cfoutput>
			<html>
				<body>
					<div style="text-align:center;background:##ffa;margin:20px;padding:20px;border:20px solid red;">
						<h1>Blocked!</h1>
						<p>Sorry, you appear to be a bad bot.</p>
						<p>#server.iptrack.blockmessage#</p>
					</div>
				</body>
			</html>
		</cfoutput>
		<cfabort>
	</cfif>

	<cftry>
		<!--- look to see if this IP is stored in the IP Blocker query object --->
		<!--- this query holds blocked IP numbers for only an hour .... they're not blacklisted, just temporarily blocked --->
		<cfquery name="qsIPB" dbtype="query">
			select count(*) as c
			from server.iptrack.ipblocker
			where IP = '#cgi.remote_addr#'
		</cfquery>
		<cfif val(qsIPB.c)>
			<!--- looks like you're in the ipblocker list! --->
			<cfoutput>
				<html>
					<body>
						<div style="text-align:center;background:##ffa;margin:20px;padding:20px;border:20px solid red;">
							<h1>Blocked!</h1>
							<p>Too many page requests!</p>
							<p>#server.iptrack.blockmessage#</p>
							<p><a href="https://WhatIsMyIP.com/" target="_blank"><small><i>What Is My IP?</i></small></a></p>
						</div>
					</body>
				</html>
			</cfoutput>
			<cfabort>
		</cfif>

		<!--- if you made it this far, you're not in the ipwhitelist, and you're not in the ipblocker query object, so let's add you to the iptracker query object --->
		<cfset queryAddRow(server.iptrack.iptracker,['#cgi.remote_addr#','#server.iptrack.noww#','#cgi.server_name#','#cgi.user_agent#'])>

		<!--- now, let's see how many times you appear in the iptracker query object --->
		<cfquery name="qsIPT" dbtype="query">
			select count(*) as c
			from server.iptrack.iptracker
			where ip = '#cgi.remote_addr#'
		</cfquery>
		<cfif val(qsIPT.c) gt server.iptrack.maxtrack>
			<!--- ahah! you're in the iptracker query more than 100 times in 120 seconds? blocked! --->
			<!--- ipblocker deletes entries after an hour --->
			<!--- the 0 on the end (keep) indicates whether this ip will be removed from the query during the purge --->
			<cfset queryAddRow(server.iptrack.ipblocker,['#cgi.remote_addr#','#server.iptrack.noww#',0])>
		</cfif>

		<!--- let's see if you've been hitting more than one site --->
		<!--- this assumes you're running this code on more than one site --->
		<!--- will re-enable once we see behavior
		<cfquery name="qsIPT" dbtype="query">
			select count(*) as c, site
			from server.iptrack.iptracker
			where ip = '#cgi.remote_addr#'
			group by site
		</cfquery>
		<cfif val(qsIPT.recordCount) gt 2>
			<!--- what? you hit more than two sites on my server from this one IP? --->
			<!--- permanent add - gotta write this out to a text file list --->
			<cfset queryAddRow(server.iptrack.ipblocker,['#cgi.remote_addr#','#server.iptrack.noww#',1])>
		</cfif>
		--->

		<!--- check the first three octets of IP numbers to see if they're a subnet of IP numbers in the iptracker query object --->
		<!--- this will eventually populate an ipblocksubnet / ipblacksubnet list, or something, to block entire subnets of IP numbers --->
		<!---
		<cfquery name="qsIPT2" dbtype="query">
			select count(*) as c
			from server.iptrack.iptracker
			where ip like '#replace(cgi.remote_addr,listGetAt(cgi.remote_addr,4,"."),"","all")#%'
		</cfquery>
		<cfif qsIPT2.c gt 100>
		</cfif>
		--->

		<cfcatch>
			<cfdump var="#cfcatch#">
		</cfcatch>
	</cftry>
</cfif><!--- end if you're not in the ipwhitelist --->

<!--- now we do the purges --->
<cfloop query="server.iptrack.iptracker">
	<!--- remove all entries older than 2 minutes, or if they're on the ipwhitelist --->
	<cfif datetime lt DateAdd("n", server.iptrack.iptracktime, server.iptrack.noww) or listFind(server.iptrack.ipwhitelist,cgi.remote_addr)>
		<cftry>
			<cfscript>server.iptrack.iptracker.DeleteRow(currentRow);</cfscript>
			<cfcatch></cfcatch>
		</cftry>
	</cfif>
</cfloop>

<cfloop query="server.iptrack.ipblocker">
	<!--- remove all entries older then an hour, or if they're on the ipwhitelist --->
	<cfif not keep and (datetime lt DateAdd("n", server.iptrack.ipblocktime, server.iptrack.noww) or listFind(server.iptrack.ipwhitelist,cgi.remote_addr))>
		<cftry>
			<cfscript>server.iptrack.ipblocker.DeleteRow(currentRow);</cfscript>
			<cfcatch></cfcatch>
		</cftry>
	</cfif>
</cfloop>
