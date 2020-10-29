<cfparam name="form.run" default="0">
<cfif val(form.run)>
	<cfoutput>
		<!---<cfdump var="#form#">--->
		<cffile action="write" file="D:\sites\ip-whitelist.txt" output="#trim(replace(trim(form.ipwhitelist),chr(13)&chr(10),",","all"))#">
		<cfset server.iptrack.ipwhitelist = trim(replace(trim(form.ipwhitelist),chr(13)&chr(10),",","all"))>
		<cffile action="write" file="D:\sites\ip-blacklist.txt" output="#trim(replace(trim(form.ipblacklist),chr(13)&chr(10),",","all"))#">
		<cfset server.iptrack.ipblacklist = trim(replace(trim(form.ipblacklist),chr(13)&chr(10),",","all"))>
		<cffile action="write" file="D:\sites\ua-blacklist.txt" output="#trim(replace(trim(form.uablacklist),chr(13)&chr(10),"|","all"))#">
		<cfset server.iptrack.uablacklist = trim(replace(trim(form.uablacklist),chr(13)&chr(10),"|","all"))>
		<cffile action="write" file="D:\sites\url-blacklist.txt" output="#trim(replace(trim(form.urlblacklist),chr(13)&chr(10),"|","all"))#">
		<cfset server.iptrack.urlblacklist = trim(replace(trim(form.urlblacklist),chr(13)&chr(10),"|","all"))>

		<cfloop query="server.iptrack.ipblocker">
			<cfif isDefined("form.action_#replace(ip,".","_","all")#")>
				<cfswitch expression="#evaluate("form.action_" & replace(ip,'.','_','all'))#">
					<cfcase value="Whitelist">
						<cfset server.iptrack.ipwhitelist = listappend(server.iptrack.ipwhitelist,ip)>
						<cffile action="write" file="D:\sites\ip-whitelist.txt" output="#server.iptrack.ipwhitelist#">
						<cfscript>server.iptrack.ipblocker.DeleteRow(currentRow);</cfscript>
					</cfcase>
					<cfcase value="Blacklist">
						<cfset server.iptrack.ipblacklist = listappend(server.iptrack.ipblacklist,ip)>
						<cffile action="write" file="D:\sites\ip-blacklist.txt" output="#server.iptrack.ipblacklist#">
						<cfscript>server.iptrack.ipblocker.DeleteRow(currentRow);</cfscript>
					</cfcase>
					<cfcase value="Remove">
						<cfscript>server.iptrack.ipblocker.DeleteRow(currentRow);</cfscript>
					</cfcase>
					<cfdefaultcase>
					</cfdefaultcase>
				</cfswitch>
			</cfif>
		</cfloop>
	</cfoutput>
</cfif>

<cflocation url="_iptrack-console.cfm" addtoken="No">
