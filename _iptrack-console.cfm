<!---
ColdFusion IPTracker, by Michael Muller, MontagueWebWorks.com, October 2020.
This code was written on Lucee 5.3.2.77 but should work on any CFM engine.
You are free to use this code as you see fit. Absoutely free.
If you make any improvements, contact tech@montaguewebworks.com

The intention of this app is to track the IP numbers hitting your server and automatically block overly aggressive requestors.

Companion files are _iptrack-site.cfm and _iptrack-site-config.cfm. Please go check those out for additional notes.

You should place this file and its action script in a site that is not a regular customer site, but instead a management site, so your activity here will not be tracked.

In this file, through the browser, you will have access to edit the IP whitelist, IP blacklist, UA black list and URL snippet blacklist.
You can view the IP numbers currently blocked, and can either send them to the whitelist or blacklist.
You can view the current IP Track list, which holds as many minutes of traffic as you've set it to hold in _iptracker-site-config.cfm.
If you see any hacking attempts, like /wp-admin/ or snarky spiders, you can manually add them to the URL snippet and UA blacklists.
--->

<h1>IP Tracker / Blocker</h1>

<div style="background:white!important;">

	<cfif not isDefined("server.iptrack")>
		<h3>Ooops...!</h3>
		<p>It appears you have not yet added _iptracker-site.cfm and the accompanying _iptracker-site-settings.cfm files to any website on this server, or that website has not seen any traffic since including those files.</p>
		<cfabort>
	</cfif>

	<form action="_iptrack-console-action.cfm" method="post">
		<input type="hidden" name="run" value="1">
		<cfoutput>
			<div class="container">
				<div class="row">
					<div class="col-sm-3">
						<h3 style="color:black;" title="#server.iptrack.ipwhitelist#">IP WhiteList: #listLen(server.iptrack.ipwhitelist,",")#</h3>
						<textarea name="ipwhitelist" class="form-control">#replace(listSort(server.iptrack.ipwhitelist,"text","asc"),",",chr(10)&chr(13),"all")#</textarea>
					</div>
					<div class="col-sm-3">
						<h3 style="color:black;">IP BlackList: #listLen(server.iptrack.ipblacklist)#</h3>
						<textarea name="ipblacklist" class="form-control">#replace(listSort(server.iptrack.ipblacklist,"text","asc"),",",chr(10)&chr(13),"all")#</textarea>
					</div>
					<div class="col-sm-3">
						<h3 style="color:black;">UA BlackList: #listLen(server.iptrack.uablacklist,"|")#</h3>
						<textarea name="uablacklist" class="form-control">#replace(listSort(server.iptrack.uablacklist,"text","asc"),"|",chr(10)&chr(13),"all")#</textarea>
					</div>
					<div class="col-sm-3">
						<h3 style="color:black;">URL BlackList: #listLen(server.iptrack.urlblacklist,"|")#</h3>
						<textarea name="urlblacklist" class="form-control">#replace(listSort(trim(server.iptrack.urlblacklist),"text","asc"),"|",chr(10)&chr(13),"all")#</textarea>
					</div>
				</div>
				<div class="row">
					<div class="col-sm-12" style="margin:10px;">
						<input type="submit" name="submit" value="Submit" class="btn btn-sm btn-danger">
						<a class="btn btn-sm btn-info" href="_iptrack-console-help.html" onclick="window.open(this.href, '', 'resizable=no,status=no,location=no,toolbar=no,menubar=no,fullscreen=no,scrollbars=yes,dependent=no,width=600,height=600'); return false;">Help</a>
					</div>
				</div>
			</div>

			<h3 style="color:black;">IPs Blocked: #server.iptrack.ipblocker.recordCount#</h3>
			<cfif server.iptrack.ipblocker.recordCount>
			<p>
				These are IP numbers that exceeded #server.iptrack.maxtrack# page requests in #replace(server.iptrack.iptracktime,"-","","all")# minutes.
				They will live in this table for #replace(server.iptrack.ipblocktime,"-","","all")# minutes unless you move them to the permanent IP whitelist or blacklist.
			</p>
				<table class="projects">
					<tr>
						<th>IP Num</th>
						<th>Loc</th>
						<th>Whois</th>
						<th>Date Time</th>
						<th>Keep</th>
						<th>Action</th>
					</tr>
					<cfloop query="server.iptrack.ipblocker">
						<tr>
							<td>#IP#</td>
							<td><a href="https://viewdns.info/iplocation/?ip=#IP#" target="_blank">loc</a></td>
							<td><a href="https://viewdns.info/whois/?domain=#IP#" target="_blank">whois</a></td>
							<td>#DateTime#</td>
							<td align="center">#keep#</td>
							<td>
								<select name="action_#replace(ip,".","_","all")#" class="form-control">
									<cfloop list="None,Whitelist,Blacklist,Remove" index="ll">
										<option value="#ll#">#ll#</option>
									</cfloop>
								</select>
							</td>
						</tr>
					</cfloop>
				</table>
			</cfif>

			<hr>
			<cfquery name="qsPie" dbtype="query">
				select count(*) as c, ip
				from server.iptrack.iptracker
				group by ip
				order by c desc
			</cfquery>
			<cftry>
				<cfquery name="qsBar" dbtype="query">
					select count(*) as c, substring(datetime,18,2) as t
					from server.iptrack.iptracker
					group by t
					order by c desc
				</cfquery>
				<cfcatch type="any"><cfdump var="#cfcatch#"></cfcatch>
			</cftry>
			<h3 style="color:black;">Distinct IPs Tracked: #qsPie.recordCount#</h3>
			<div class="container">
				<div class="row">
					<div class="col-sm-4">
						<cfchart format="jpg" title="IP Tracking Grouped by IP" backgroundcolor="white" showborder="false">
							<cfchartseries type="pie">
								<cfloop query="qsPie">
									<cfchartdata item="#ip#" value="#c#">
								</cfloop>
							</cfchartseries>
						</cfchart>
					</div>
					<div class="col-sm-4">
						<table class="projects">
							<tr>
								<th colspan="3">IP Num</th>
								<th>Count</th>
							</tr>
							<cfloop query="qsPie">
								<tr>
									<td>#ip#</td>
									<td><a href="https://viewdns.info/whois/?domain=#ip#" target="_blank">Whois</a></td>
									<td><a href="https://viewdns.info/iplocation/?ip=#ip#" target="_blank">Location</a></td>
									<td align="center">#c#</td>
								</tr>
							</cfloop>
						</table>
					</div>
					<div class="col-sm-4">
						<cftry>
							<cfchart format="jpg" title="IP Tracking by Second" backgroundcolor="white" showborder="false">
								<cfchartseries type="pie">
									<cfloop query="qsBar">
										<cfchartdata item="#t#" value="#c#">
									</cfloop>
								</cfchartseries>
							</cfchart>
							<cfcatch type="any"><cfdump var="#cfcatch#"></cfcatch>
						</cftry>
					</div>
				</div>
			</div>

			<hr>
			<h3 style="color:black;">All Tracked IP Traffic: #server.iptrack.iptracker.recordCount#</h3>
			<p>These are the IP numbers that made it through the whitelist, the blacklist, the user agent blacklist and the url snippet black list.</p>
			<p><b>You are tracking #replace(server.iptrack.iptracktime,"-","","all")# minutes worth of page requests.</b>
			If an IP number exceeds #server.iptrack.maxtrack# requests, they get added to the <b>IPs Blocked</b> table, above<cfif not val(server.iptrack.ipblocker.recordCount)> (currently empty)</cfif>.</p>
			<table class="projects">
				<tr>
					<th>IP Num</th>
					<th>Date Time</th>
					<th>Site</th>
					<th>Agent</th>
					<th>Script</th>
				</tr>
				<cfloop query="server.iptrack.iptracker">
					<tr>
						<td>#ip#</td>
						<td>#listRest(datetime," ")#</td>
						<td>#site#</td>
						<td>#useragent#</td>
						<td>#replace(script,"/index.cfm?","","all")#</td>
					</tr>
				</cfloop>
			</table>

			<hr>
			<!---
			<cfdump var="#server.iptrack.ipblocker#" label="BLOCKED" expand="0">
			<cfdump var="#server.iptrack.iptracker#" label="TRACKED" expand="0">
			--->
		</cfoutput>
	</form>
</div>