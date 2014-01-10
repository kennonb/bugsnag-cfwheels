<!--- Create the URL string of the page that the error occured on. --->
<cfset errorPage = "#LCase(ListFirst(cgi.server_protocol, "/"))#://#cgi.server_name##Replace(cgi.script_name, "/#application.wheels.rewriteFile#", "")##cgi.path_info#" />
<cfif cgi.query_string IS NOT "">
    <cfset errorPage = errorPage & "?#cgi.query_string#" />
</cfif>


<!--- Setup the struct of the data to send to Bugsnag --->
<cfscript>

    var payload = {
        apiKey  = "YOUR_API_KEY_HERE";
        notifier = {
            name    : "Bugsnag Cfwheels",
            version : "1.0",
            url     : errorPage,
        },
        events = [{
            userId       : cgi.remote_host,
            osVersion    : cgi.http_user_agent,
            releaseStage : "production",
            context      : Application.WHEELS.EXISTINGOBJECTFILES,
            exceptions   = [{
                errorClass : arguments.exception.rootcause.type,
                message    : arguments.exception.rootcause.message,
                stacktrace : []
            }]
        }]
    };

    for ( s = 1; s LTE arraylen(payload.arguments.exception.rootcause.TagContext); s = s+1 ) {
        var trace = {
            file         : arguments.exception.rootcause.TagContext[s].template,
            lineNumber   : arguments.exception.rootcause.TagContext[s].line,
            columnNumber : arguments.exception.rootcause.TagContext[s].column,
            method       : arguments.exception.rootcause.TagContext[s].codePrintPlain
        };

        arrayAppend(payload.events[1].exceptions[1].stacktrace, trace);
    }

    var jsonPayload = serializejson(payload);

    httpService = new http();
    httpService.setUrl("https://notify.bugsnag.com");
    httpService.setMethod("post");
    httpService.addParam(type="header", name="Content-Type", value="application/json");
    httpService.addParam(type="body", value=jsonPayload);
    result = httpService.send().getPrefix();
</cfscript>

<cfheader statuscode="500" statustext="Internal Server Error">

<h1>Error!</h1>
<p>
    Sorry, that caused an unexpected error.<br />
    Please try again later.
</p>