# CFM-IPTracker
Track the IP numbers hitting your server and automatically block overly aggressive requestors

ColdFusion IPTracker, by Michael Muller, MontagueWebWorks.com, October 2020.
This code was written on Lucee 5.3.2.77 but should work on any CFM engine.
You are free to use this code as you see fit. Absoutely free. Only if you want to be.

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
