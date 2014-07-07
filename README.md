Purpose
=======

WebAbstract provides an organized way to configure and maintain XPath-based parse instructions should you need to parse HTML directly in Objective-C.
 
Discussion
==========

Don't parse HTML in Objective-C.  You are likely trying to solve a problem the wrong way.  If you need to scrape data from an external site to power your iOS / OS X application, consider first if this task would not be better handled by a web service.  In that scenario, your app sends requests to the web service which would translate the external (HTML) data to a JSON/XML format that your app understands.  If there HTML format changes on the external site, you need only to update the parser logic in the web service to accommodate those changes.  Much better than rushing off to resubmit a new version of your app to Apple.

There may be cases where introducing an intermediate web service is not feasible.  If the external content requires login, then passing user credentials and/or data to a web service may not be acceptable.  You're stuck processing the external HTML directly inside your app. WebAbstract was designed for this type of scenario.  Be sure that you are not violating any of the external site's Terms of Use by accessing and using data in this fashion.

WebAbstract provides a way to organize HTML parse instructions.  It supports instructions that defined by XPath queries, or failing that, regular expressions.  You define the parse instructions in a property list (.plist) file.  This file need not be bundled into your app (though it can be). You can host the .plist file on a website and have your app download it as well as periodically check for updates.  This way, you avoid hard-coding parse instructions into your app.  You can compensate for minor HTML format changes in the external data without submitting a new version of your app to Apple.

XPath queries are excellent for traversing data structures and extracting particular pieces of data. XPath is mainly used for traversing XML; WebAbstract uses a varient for HTML.  XPath is an entire language into itself.  I've found this tutorial to be a good place to begin learning how to write XPath queries:

[http://oreilly.com/perl/excerpts/system-admin-with-perl/ten-minute-xpath-utorial.html]

As HTML is not a regular language, it should not be parsed using regular expressions.  If you are so inclined, read this full discussion of this topic:

[http://blog.codinghorror.com/parsing-html-the-cthulhu-way/]

However, regular expressions are often helpful in conjunction with XPath queries: once an individual data element has been extracted from HTML (i.e. a non-marked-up string), that can further be striped down with a regular expression to identify the exact substring of interest.


The WebAbstract configuration .plist file
-------------------------------------------------------

A WebAbstract configuration consists two types of constructs:

* 'source' descriptions (how to build a request URL to an external source)
* 'output' descriptions (how to parse the resulting data after requesting that URL)

Source
------

A 'source' describes how to build a `NSURLRequest` object for a given request type.  Your application indicates what kind of data it is looking for, and the WebAbstract 'source' describes how to build a corresponding concrete NSURLRequest.  The application may pass in parameters that are used (or ignored) by the 'source' configuration.  Parameters passed in may be used to construct the URL query string, or to create an HTTP POST submission.

This is an example of a *source* configuration ("fetchWorkouts") viewed as XML:

    <key>source</key>
    <dict>
   	 <key>[fetchWorkouts]</key>
   	 <dict>
   		 <key>url</key>
   		 <dict>
   			 <key>format</key>
   			 <string>cgi-bin/schedule.cgi?gymId=%@&amp;startDate=%@&amp;period=%@&amp;timeZone=%@</string>
   			 <key>variables</key>
   			 <array>
   				 <string>gymId</string>
   				 <string>startDate</string>
   				 <string>period</string>
   				 <string>timeZone</string>
   			 </array>
   		 </dict>
   	 </dict>
    </dict>




 The details, including (domain name, protocol type, and path) are described in the .plist configuration file and not code.  How the NSURLRequest is actually executed is up to your app.

**Example:**

    NSURLRequest *request = [myWebAbstractObj buildUrlRequestForOperation:@"weatherForcast"
                                                             forSourceTag:@"tempByDate"
                                                            withVariables:@{ @"date" : [NSDate date] }
                    	    ];


Output
------

An 'output' describes how to parse an NSData (response) object into native data-types, including NSString, NSArray, NSDictionary elements.

**Example:**

    NSString *tempStr = [myWebAbstractObj parseData:htmlData
                                 	forOperation:@"weatherForcast"
                                 	forOutputTag:@"tempByDate"
                  	    ];


much much more goes here...


Author
======
WebAbstract was developed by Eric Colton (ericcolton@gmail.com)

[https://github.com/ericcolton/WebAbstract]

