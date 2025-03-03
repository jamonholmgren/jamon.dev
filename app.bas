' QB64 web server inspired by the one found here: https://github.com/smokingwheels/Yacy_front_end/blob/master/yacyfrontend.bas
' Modified to power https://jamon.dev

$Console:Only

' Variables are integers by default if they start with a-z
DefInt A-Z

' Constants
Const MAX_CLIENTS = 8
Const EXPIRY_TIME = 240 'seconds
Const MIDNIGHT_FIX_WINDOW = 60 * 60 'seconds
Const MAX_HEADER_SIZE = 4096 'bytes

' Const DEFAULT_HOST = "147.182.205.32" ' for hosting
Const DEFAULT_HOST = "localhost" ' for local
Const DEFAULT_PORT = "6464"

' Different types of web requests
Const METHOD_HEAD = 1
Const METHOD_GET = 2
Const METHOD_POST = 3

' Logging?
Const ENABLE_LOG = 0 ' 0 for off, 1 for on

' When did the server start?
Dim Shared StartTime As String
StartTime = datetime

' convenience consts
Dim Shared CRLF As String
Dim Shared QT As String
CRLF = Chr$(13) + Chr$(10) ' carriage return + line feed
QT = Chr$(34) ' double quote

' QB64 doesn't support variable-length strings in TYPEs, so we have to use a fixed-length string
' Important ones first
Dim client_handle(1 To MAX_CLIENTS) As Integer
Dim client_expiry(1 To MAX_CLIENTS) As Double
Dim client_request(1 To MAX_CLIENTS) As String
Dim client_uri(1 To MAX_CLIENTS) As String
Dim client_method(1 To MAX_CLIENTS) As Integer
Dim client_content_length(1 To MAX_CLIENTS) As Long

' These ones are less important
Dim client_host(1 To MAX_CLIENTS) As String
Dim client_browser(1 To MAX_CLIENTS) As String
' Dim client_content_encoding(1 To MAX_CLIENTS) As Integer

connections = 0

DebugLog "Starting QB64 webserver on port " + DEFAULT_PORT

' kick off the listener
host = _OpenHost("TCP/IP:" + DEFAULT_PORT)

' main loop!
Do
    ' Process old connections
    If connections Then
        For c = 1 To MAX_CLIENTS
            ' If this connection is active
            If client_handle(c) Then
                ' Add logging to monitor connection processing
                DebugLog "Processing connection #" + Str$(c) + " (" + Str$(ROUND((Timer(.001) - client_expiry(c)) / 1000, 1)) + "ms old)"

                ' work on the request in an effort to finish it
                If handle_request(c) Then
                    ' Ignore "captive" pings
                    If InStr(client_uri(c), "captive") < 1 Then
                        DebugLog "Completed request for: " + client_uri(c)
                        DebugLog " from " + _ConnectionAddress(client_handle(c))
                        DebugLog " using " + client_browser(c)
                    End If
                    tear_down c
                    ' If the request was completed, we can reduce the number of active connections
                    connections = connections - 1
                    ' Timeout old connections
                ElseIf Timer >= client_expiry(c) And Timer < client_expiry(c) + MIDNIGHT_FIX_WINDOW Then
                    DebugLog "TIMED OUT: request for: " + client_uri(c)
                    DebugLog " from " + _ConnectionAddress(client_handle(c))
                    DebugLog " using " + client_browser(c)
                    respond c, "HTTP/1.1 408 Request Timeout", "", "text/html"
                    tear_down c
                    ' If the request timed out, we can reduce the number of active connections
                    connections = connections - 1
                End If
            End If
        Next
    End If

    ' Accept any new connections
    If connections < MAX_CLIENTS Then
        newclient = _OpenConnection(host) ' monitor host connection
        Do While newclient
            For c = 1 To MAX_CLIENTS
                ' Find an empty client handle to handle this new connection
                If client_handle(c) = 0 Then
                    client_handle(c) = newclient
                    client_method(c) = 0
                    client_content_length(c) = -1
                    client_expiry(c) = Timer(.001) + EXPIRY_TIME
                    If client_expiry(c) >= 86400 Then client_expiry(c) = client_expiry(c) - 86400
                    Exit For
                End If
            Next
            
            connections = connections + 1

            ' If we're at the max, stop accepting new connections
            If connections >= MAX_CLIENTS Then Exit Do

            ' Get the next connection
            newclient = _OpenConnection(host) ' monitor host connection
        Loop
    End If

    ' Limit CPU usage and leave some time for stuff be sent across the network..I have it as high as 1000 on my Front End
    _Limit 250 ' default 50
Loop Until InKey$ = Chr$(27) ' escape quits

' After a keypress, close all connections and quit
Close #host
System ' Quits to system


StaticFileError:
    DebugLog "File error: " + Error$
    Resume Next

' This tears down a connection, empties memory, and resets the client handle to 0
Sub tear_down (c As Integer)
    ' Import the shared arrays
    Shared client_handle() As Integer
    Shared client_uri() As String
    Shared client_host() As String
    Shared client_browser() As String
    Shared client_request() As String

    ' Close the connection
    Close #client_handle(c)

    'set handle to 0 so we know it's unused
    client_handle(c) = 0
    'set strings to empty to save memory
    client_uri(c) = ""
    client_host(c) = ""
    client_browser(c) = ""
    client_request(c) = ""
End Sub

' Attempt to complete a request
Function handle_request% (c As Integer)
    ' Import the shared arrays
    Shared client_handle() As Integer
    Shared client_uri() As String
    Shared client_host() As String
    Shared client_browser() As String
    Shared client_content_length() As Long
    Shared client_request() As String
    Shared client_method() As Integer

    ' Start timer
    Dim start_timer As Single
    start_timer = Timer(.001)

    ' Apparently QB64 doesn't support this yet
    ' ON LOCAL ERROR GOTO runtime_internal_error

    ' Allocate space for the current line we're reading
    Dim cur_line As String

    ' Read the first line of the request and store in s$
    Get #client_handle(c), , s$

    ' Empty requests are just dumped
    If Len(s$) = 0 Then Exit Function

    'client_request is used to collect the client's request
    'when all the headers have arrived, they are stripped away from client_request
    client_request(c) = client_request(c) + s$

    ' If we haven't parsed out the client method yet, let's do that
    If client_method(c) = 0 Then
        ' The end of the headers is the first blank line, which is two CRLFs in a row
        header_end = InStr(client_request(c), CRLF + CRLF)
        ' If it's immediately at the start of the request, we have no headers
        If header_end = 0 Then
            ' Too large of a request...can't handle it
            If Len(client_request(c)) > MAX_HEADER_SIZE Then GoTo large_request
            ' Either way, we're out
            Exit Function
        End If

        ' HTTP permits the use of multiple spaces/tabs and in some cases newlines
        ' to separate words. So we collapse them.
        headers$ = shrinkspace(Left$(client_request(c), header_end + 1))
        client_request(c) = Mid$(client_request(c), header_end + 4)

        'This loop processes all the header lines
        first_line = 1
        Do
            ' If there's a CRLF, we have another line
            linebreak = InStr(headers$, CRLF)
            If linebreak = 0 Then Exit Do

            ' Get the current line minus the CRLF
            cur_line = Left$(headers$, linebreak - 1)

            ' Remove the current line from the rest of the headers, since we're processing it now
            headers$ = Mid$(headers$, linebreak + 2)

            ' If this is the first line, it's the request line
            If first_line Then
                'First line looks something like
                'GET /index.html HTTP/1.1
                
                ' Not the first line anymore, after this
                first_line = 0

                ' First space separates the method from the uri
                methodSpace = InStr(cur_line, " ")
                If methodSpace = 0 Then GoTo bad_request
                method$ = Left$(cur_line, methodSpace - 1)

                ' Second space separates the uri from the protocol
                uriSpace = InStr(methodSpace + 1, cur_line, " ")
                If uriSpace = 0 Then GoTo bad_request
                client_uri(c) = Mid$(cur_line, methodSpace + 1, uriSpace - (methodSpace + 1))
                If Len(client_uri(c)) = 0 Then GoTo bad_request

                If InStr(client_uri(c), "remote_ping") Then GoTo quick_ping

                ' The rest is the protocol
                version$ = Mid$(cur_line, uriSpace + 1)

                ' Grab the method, first
                Select Case method$
                    Case "GET"
                        client_method(c) = METHOD_GET
                    Case "HEAD"
                        client_method(c) = METHOD_HEAD
                    Case "POST"
                        client_method(c) = METHOD_POST
                    Case Else
                        GoTo unimplemented
                End Select

                ' We only support HTTP/1.1 and 1.0
                Select Case version$
                    Case "HTTP/1.1"
                    Case "HTTP/1.0"
                    Case Else
                        GoTo bad_request
                End Select
            Else
                ' The rest of the headers look like "Name: Value", e.g.
                ' Host: www.qb64.net
                colon = InStr(cur_line, ": ")
                If colon = 0 Then GoTo bad_request

                header$ = LCase$(Left$(cur_line, colon - 1))
                value$ = Mid$(cur_line, colon + 2)

                ' Here are the headers we recognize. We don't care about most of them.
                Select Case header$
                    Case "cache-control"
                    Case "connection"
                    Case "date"
                    Case "pragma"
                    Case "trailer"
                    Case "transfer-encoding"
                        GoTo unimplemented
                    Case "upgrade"
                    Case "via"
                    Case "warning"

                    Case "accept"
                    Case "accept-charset"
                    Case "accept-encoding"
                    Case "accept-language"
                    Case "authorization"
                    Case "expect"
                    Case "from"
                    Case "host"
                        client_host(c) = value$
                    Case "if-match"
                    Case "if-modified-since"
                    Case "if-none-match"
                    Case "if-range"
                    Case "if-unmodified-Since"
                    Case "max-forwards"
                    Case "proxy-authorization"
                    Case "range"
                    Case "referer"
                        ' Could add this later, referer is sometimes useful
                    Case "te"
                    Case "user-agent"
                        client_browser(c) = value$
                    Case "allow"
                    Case "content-encoding"
                        If LCase$(value$) <> "identity" Then GoTo unimplemented
                    Case "content-language"
                    Case "content-length"
                        If Len(value$) <= 6 Then
                            client_content_length(c) = Val(value$)
                        Else
                            GoTo large_request
                        End If
                    Case "content-location"
                    Case "content-md5"
                    Case "content-range"
                    Case "content-type"
                    Case "expires"
                    Case "last-modified"
                    Case Else
                        ' Ignore
                End Select
            End If
        Loop

        'All modern clients send a hostname, so this is mainly to prevent
        'ancient clients and bad requests from tripping us up
        If Len(client_host(c)) = 0 Then client_host(c) = DEFAULT_HOST
    End If

    'assume the request can be completed; set to 0 if it can't.
    handle_request = 1
    code$ = "200 OK"
    content_type$ = "text/html"
    Select Case client_method(c)
        Case METHOD_HEAD
            respond c, "HTTP/1.1 200 OK", "", "text/html"
        Case METHOD_GET
            uri$ = client_uri(c)

            ' Router!
            Select Case 1
                Case InStr(client_host(c), "jamonholmgren.com")
                    'redirect to the same page on jamon.dev
                    code$ = "301 Moved Permanently" + CRLF + "Location: https://jamon.dev" + client_uri(c)
                    html$ = "Moved to https://jamon.dev" + client_uri(c)
                Case InStr(client_host(c), "qb.jamonholmgren.com")
                    'redirect to the same page on jamon.dev
                    code$ = "301 Moved Permanently" + CRLF + "Location: https://jamon.dev" + client_uri(c)
                    html$ = "Moved to https://jamon.dev" + client_uri(c)
                Case Len(client_uri(c)) ' hack .. length of 1 is probably just "/" so we capture home page
                    html$ = load_page$("home")
                Case PageExists(uri$)
                    ' route any pages in the pages folder
                    html$ = load_page$(uri$)
                Case InStr(client_uri(c), "/blog")
                    html$ = load_blog$(uri$)
                Case InStr(client_uri(c), "/archive/ten")
                    html$ = load_page$("/_archive-ten")
                Case InStr(client_uri(c), "/archive/next")
                    html$ = load_page$("/_archive-next")
                Case InStr(client_uri(c), "/ten")
                    code$ = "301 Moved Permanently" + CRLF + "Location: /archive/ten"
                    html$ = "Moved to /archive/ten"
                Case InStr(client_uri(c), "/next")
                    code$ = "301 Moved Permanently" + CRLF + "Location: /archive/next"
                    html$ = "Moved to /archive/next"
                Case InStr(client_uri(c), "/live")
                    code$ = "301 Moved Permanently" + CRLF + "Location: /archive/live"
                    html$ = "Moved permanently"
                Case InStr(client_uri(c), "/connect")
                    code$ = "301 Moved Permanently" + CRLF + "Location: /links"
                    html$ = "Moved permanently"
                Case InStr(client_uri(c), "/archive/live")
                    html$ = load_page$("/_archive-live")
                Case InStr(client_uri(c), "/static/path")
                    html$ = load_static$("/static/path.html")
                ' Case InStr(client_uri(c), "/static/tank.css")
                Case InStr(client_uri(c), "/static/tanks")
                    html$ = load_static$("/static/tanks.html")
                Case InStr(client_uri(c), "/static/notes")
                    html$ = load_static$("/static/notes.html")
                Case InStr(client_uri(c), "/static/classic")
                    html$ = load_static$("/static/classic.html")
                Case StaticExists(filename$)
                    html$ = load_static$(filename$)
                Case InStr(client_uri(c), "/robots.txt")
                    ' html$ = robots_txt()
                    GoTo not_found
                Case InStr(client_uri(c), "/static/blog.json")
                    html$ = load_static$("/static/blog.json")
                    content_type$ = "application/json"
                Case InStr(client_uri(c), "/static/styles.css")
                    respond_static c, "HTTP/1.1 200 OK", "styles.css", "text/css"
                    Exit Function
                Case InStr(client_uri(c), "/static/scripts.js")
                    ' stream static file
                    respond_static c, "HTTP/1.1 200 OK", "scripts.js", "text/javascript"
                    Exit Function
                Case InStr(client_uri(c), "/static/favicon.svg")
                    ' stream static file
                    respond_static c, "HTTP/1.1 200 OK", "tractor.svg", "image/svg+xml"
                    Exit Function
                Case InStr(client_uri(c), "/static/snow.js")
                    ' Check if it's wintertime before we load up the snow
                    If is_wintertime = 1 Then
                        respond_static c, "HTTP/1.1 200 OK", "snow.js", "text/css"
                        Exit Function
                    Else
                        html$ = "// It's not wintertime, so we're not loading up the snow!"
                    End If
                    content_type$ = "text/javascript"
                Case InStr(client_uri(c), "/static/") AND InStr(client_uri(c), ".jpg")
                    image_name$ = Mid$(client_uri(c), InStr(client_uri(c), "/static/") + 8)
                    DebugLog "Loading image: " + image_name$
                    respond_binary c, "HTTP/1.1 200 OK", image_name$, "image/jpeg"
                    Exit Function
                Case Else
                    html$ = load_page$("/404")
                    code$ = "404 Not Found"
            End Select

            respond c, "HTTP/1.1 " + code$, html$, content_type$
        Case METHOD_POST
            GoTo unimplemented
        Case Else
            'This shouldn't happen because we would have EXITed FUNCTION earlier
            DebugLog "ERROR: Unknown method. This should never happen."
    End Select

    ' Done with all the normal stuff. Everything past this point is just helper "functions" (actually gotos)
    Dim total_time As Single
    total_time = Timer(.001) - start_timer
    ' DebugLog "Request handled in " + Str$(total_time) + " seconds."

    Exit Function

    not_found:
    respond c, "HTTP/1.1 404 Not Found", "404 Not Found", "text/html"
    Exit Function

    large_request:
    respond c, "HTTP/1.1 413 Request Entity Too Large", "", "text/html"
    handle_request = 1
    Exit Function

    bad_request:
    respond c, "HTTP/1.1 400 Bad Request", "", "text/html"
    handle_request = 1
    Exit Function
    unimplemented:
    respond c, "HTTP/1.1 501 Not Implemented", "", "text/html"
    handle_request = 1
    Exit Function

    quick_ping:
    respond c, "HTTP/1.1 200 OK", "OK", "text/html"
    handle_request = 1
    Exit Function

    runtime_internal_error:
    DebugLog "RUNTIME ERROR: Error code" + Str$(Err) + ", Line " + Str$(_ErrorLine)
    Resume internal_error
    
    internal_error:
    respond c, "HTTP/1.1 500 Internal Server Error", "", "text/html"
    handle_request = 1
    Exit Function
End Function

Function PageExists(filename$)
    PageExists = _FILEEXISTS("./web/pages" + filename$ + ".html") * -1
End Function

Function StaticExists(filename$)
    StaticExists = _FILEEXISTS("./web/static" + filename$) * -1
End Function

' Actually responds to the request
Sub respond (c As Integer, header As String, payload As String, content_type As String)
    ' Pull in the client_handle first
    Shared client_handle() As Integer

    ' Output ... build with a header first, then an empty line, then the payload
    out$ = header + CRLF

    out$ = out$ + "Date: " + datetime + CRLF
    out$ = out$ + "Server: QweB64" + CRLF
    out$ = out$ + "Last-Modified: " + StartTime + CRLF
    ' 604800 seconds = 1 week
    ' 86400 seconds = 1 day
    out$ = out$ + "Cache-Control: public, max-age=86400, s-maxage=86400" + CRLF
    out$ = out$ + "Connection: close" + CRLF
    ' Not sure why these are commented out, but they are in the original code
    ' out$ = out$ + "Keep-Alive: timeout=15, max=99" + CRLF
    ' out$ = out$ + "Connection: Keep-Alive" + CRLF
    
    ' If we have a payload, then the content-type is text/html, UTF-8
    If Len(payload) Then
        out$ = out$ + "Content-Type: " + content_type + "; charset=UTF-8" + CRLF
        'out$ = out$ + "Transfer-Encoding: chunked" + CRLF
        out$ = out$ + "Content-Length:" + Str$(Len(payload)) + CRLF
    End If

    ' extra newline to signify end of header
    out$ = out$ + CRLF

    ' Put the header output to the handle
    Put #client_handle(c), , out$

    ' Put the payload to the handle
    Put #client_handle(c), , payload

    ' Done!
End Sub

' static text files
Sub respond_static (c As Integer, header As String, filename as String, content_type As String)
    Shared client_handle() As Integer

    ' DebugLog "Serving static file: " + filename

    out$ = header + CRLF
    out$ = out$ + "Date: " + datetime + CRLF
    out$ = out$ + "Server: QweB64" + CRLF
    out$ = out$ + "Last-Modified: " + StartTime + CRLF
    ' 604800 seconds = 1 week
    ' 86400 seconds = 1 day
    out$ = out$ + "Cache-Control: public, max-age=86400, s-maxage=86400" + CRLF
    out$ = out$ + "Connection: close" + CRLF
    out$ = out$ + "Content-Type: " + content_type + "; charset=UTF-8" + CRLF
    out$ = out$ + CRLF

    ' output headers first
    Put #client_handle(c), , out$

    ' Read the file and write it to the handle
    ON ERROR GOTO StaticFileError
    Open "./web/static/" + filename For Input As #1
    ON ERROR GOTO 0

    Do While Not EOF(1)
       Line Input #1, line$
       out$ = line$ + CRLF
       Put #client_handle(c), , out$
    Loop

    Close #1

    ' Done!
End Sub

Sub respond_binary (c As Integer, header As String, filename as String, content_type As String)
    Shared client_handle() As Integer

    out$ = header + CRLF
    out$ = out$ + "Date: " + datetime + CRLF
    out$ = out$ + "Server: QweB64" + CRLF
    out$ = out$ + "Last-Modified: " + StartTime + CRLF
    ' 604800 seconds = 1 week
    ' 86400 seconds = 1 day
    out$ = out$ + "Cache-Control: public, max-age=86400, s-maxage=86400" + CRLF
    out$ = out$ + "Connection: close" + CRLF
    out$ = out$ + "Content-Type: " + content_type + "; charset=UTF-8" + CRLF
    out$ = out$ + CRLF

    ' output headers first
    Put #client_handle(c), , out$

    ' Read the file and write it to the handle
    ON ERROR GOTO StaticFileError
    Open "./web/static/" + filename For Binary As #1
    ON ERROR GOTO 0

    ' Define a buffer size, e.g., 1 KB chunks
    Const bufferSize = 1024
    Dim buffer As String * bufferSize

    Dim fileLength As Long
    fileLength = LOF(1) ' Length of file

    While fileLength > 0
        ' Determine the size of the next chunk to read
        If fileLength < bufferSize Then
            ' Resize buffer for the last piece of the file
            buffer = Space$(fileLength)
        End If
        
        ' Read a chunk of the file
        Get #1, , buffer
        
        ' Send the chunk to the client
        Put #client_handle(c), , buffer  ' Send the entire buffer
        
        ' Reduce the remaining file length by the size of the chunk just read
        fileLength = fileLength - Len(buffer)
    Wend

    Close #1

    ' Done!
End Sub

' This returns a string of the current date and time in the format required by HTTP
Function datetime$ ()
    Static init As Integer
    Static day() As String, month() As String, monthtbl() As Integer
    If init = 0 Then
        init = 1
        ReDim day(0 To 6) As String
        ReDim month(0 To 11) As String
        ReDim monthtbl(0 To 11) As Integer
        day(0) = "Sun": day(1) = "Mon": day(2) = "Tue"
        day(3) = "Wed": day(4) = "Thu": day(5) = "Fri"
        day(6) = "Sat"
        month(0) = "Jan": month(1) = "Feb": month(2) = "Mar"
        month(3) = "Apr": month(4) = "May": month(5) = "Jun"
        month(6) = "Jul": month(7) = "Aug": month(8) = "Sep"
        month(9) = "Oct": month(10) = "Nov": month(11) = "Dec"
        'Source: Wikipedia
        monthtbl(0) = 0: monthtbl(1) = 3: monthtbl(2) = 3
        monthtbl(3) = 6: monthtbl(4) = 1: monthtbl(5) = 4
        monthtbl(6) = 6: monthtbl(7) = 2: monthtbl(8) = 5
        monthtbl(9) = 0: monthtbl(10) = 3: monthtbl(11) = 5
    End If
    temp$ = Date$ + " " + Time$
    m = Val(Left$(temp$, 2))
    d = Val(Mid$(temp$, 4, 2))
    y = Val(Mid$(temp$, 7, 4))
    c = 2 * (3 - (y \ 100) Mod 4)
    y2 = y Mod 100
    y2 = y2 + y2 \ 4
    m2 = monthtbl(m - 1)
    weekday = c + y2 + m2 + d

    'leap year and Jan/Feb
    If ((y Mod 4 = 0) And (y Mod 100 <> 0) Or (y Mod 400 = 0)) And m <= 2 Then weekday = weekday - 1

    weekday = weekday Mod 7

    datetime$ = day(weekday) + ", " + Left$(temp$, 2) + " " + month(m - 1) + " " + Mid$(temp$, 7) + " GMT"
End Function

' This function returns whether it's wintertime or not ... according to Copilot
Function is_wintertime ()
    Static init As Integer
    Static wintertime As Integer
    If init = 0 Then
        init = 1
        temp$ = Date$ + " " + Time$
        m = Val(Left$(temp$, 2))
        wintertime = 0
        ' December and January only
        If m = 12 Or m = 1 Then
            wintertime = 1
        End If
    End If
    is_wintertime = wintertime
End Function

' removes extra spaces from a string, I guess?
Function shrinkspace$ (str1 As String)
    Do
        i = InStr(str1, Chr$(9))
        If i = 0 Then Exit Do
        Mid$(str1, i, 1) = " "
    Loop
    Do
        i = InStr(str1, CRLF + " ")
        If i = 0 Then Exit Do
        str1 = Left$(str1, i - 1) + Mid$(str1, i + 2)
    Loop
    Do
        i = InStr(str1, "  ")
        If i = 0 Then Exit Do
        str1 = Left$(str1, i - 1) + Mid$(str1, i + 1)
    Loop
    shrinkspace = str1
End Function

' slugifies a url path string, assuming no foreign characters
Function slugify$ (str1 As string)
    str1 = LCase$(str1)
    str1 = replace$(str1, " ", "-")
    str1 = replace$(str1, "/", "-")
    str1 = replace$(str1, "\", "-")
    str1 = replace$(str1, ":", "-")
    str1 = replace$(str1, "*", "-")
    str1 = replace$(str1, "?", "-")
    slugify = str1
End Function

' replaces various template variables with their values
Function replace$ (str1 As String, template_var As String, template_value As String)
    Do
        i = InStr(str1, template_var)
        If i = 0 Then Exit Do
        str1 = Left$(str1, i - 1) + template_value + Mid$(str1, i + Len(template_var))
    Loop
    replace = str1
End Function

' Replaces all template variables with their values
Function process_template$ (template_str As String, pagename As String)
    ' template_str = replace(template_str, "${date}", datetime$)
    template_str = replace(template_str, "${year}", Mid$(datetime$, 13, 4))
    template_str = replace(template_str, "${slug}", slugify(pagename))
    
    ' add other template strings here
    ' template_str = replace(template_str, "${date}", datetime$)

    process_template = template_str
End Function

' Loads a blog post from the blog folder, which are just years (2023.html) etc, starting in 2023.
' If the file doesn't exist, it returns a 404 page.
' Adds links to all the other years at the end of the page, if they exist.
' Defaults to the current year if no year is specified.
Function load_blog$ (uri$)
    current_year$ = Mid$(datetime$, 13, 4)

    ' check if uri starts with a slash and remove it
    If Left$(uri$, 1) = "/" Then
        uri$ = Mid$(uri$, 2)
    End If

    ' check if uri ends with a slash and remove it
    If Right$(uri$, 1) = "/" Then
        uri$ = Left$(uri$, Len(uri$) - 1)
    End If

    ' get a year if it exists after blog, like `blog/****`
    year$ = Mid$(uri$, 6, 4)

    ' if no year is specified, use the current year
    If Len(year$) = 0 Then
        year$ = current_year$
    End If
    
    ' add links to all the other years
    h$ = "<nav id='blog-years' data-year='" + current_year$ + "'>" + CRLF
    h$ = h$ + "<div class='years'>" + CRLF
    For i = Val(current_year$) To 2023 Step -1
        ' convert to string and strip spaces
        y$ = LTrim$(Str$(i))

        If _FILEEXISTS("./web/blog/" + y$ + ".html") Then
            If y$ = year$ Then
                ' If current year, bold it
                h$ = h$ + "<a href='/blog/" + y$ + "' class='active'>" + y$ + "</a>" + CRLF
            Else
                h$ = h$ + "<a href='/blog/" + y$ + "'>" + y$ + "</a>" + CRLF
            End If
        Else
            ' no blog articles for this year, skip
            ' h$ = h$ + "<span>" + "./web/blog/" + y$ + ".html" + "</span>" + CRLF
        End If
    Next
    h$ = h$ + "</div>" + CRLF
    h$ = h$ + "</nav>" + CRLF

    ' check if the year exists in `./web/blog/yyyy.html`
    If _FILEEXISTS("./web/blog/" + year$ + ".html") = 0 Then
        ' if not, return a 404 page
        load_blog = load_page$("/404")
        Exit Function
    End If

    ' load the blog post
    Open "./web/blog/" + year$ + ".html" For Input As #1
    bold = 0
    italic = 0
    Do While Not EOF(1)
       Line Input #1, line$
       h$ = h$ + line$ + CRLF
    Loop
    Close #1

    load_blog = full_html$("Blog", h$, uri$)
End Function

Function full_html$ (title As String, body As String, pagename As String)
    h$ = "<!DOCTYPE html>" + CRLF
    h$ = h$ + "<html>" + CRLF
    h$ = h$ + "<head>" + CRLF
    h$ = h$ + "<title>" + title + "</title>" + CRLF

    ' extra head tags
    Open "./web/head.html" For Input As #1
    Do While Not EOF(1)
       Line Input #1, line$
       h$ = h$ + process_template(line$, pagename) + CRLF
    Loop
    Close #1

    h$ = h$ + "</head>" + CRLF
    h$ = h$ + "<body>" + CRLF
    h$ = h$ + "<div class='container'>" + CRLF

    ' Load the header from header.html and add to h$
    Open "./web/header.html" For Input As #1
    Do While Not EOF(1)
       Line Input #1, line$
       h$ = h$ + process_template(line$, pagename) + CRLF
    Loop
    Close #1

    h$ = h$ + "<main>" + CRLF
    h$ = h$ + body + CRLF
    h$ = h$ + "</main>" + CRLF

    ' Load the footer from footer.html and add to h$
    Open "./web/footer.html" For Input As #1
    Do While Not EOF(1)
       Line Input #1, line$
       h$ = h$ + process_template(line$, pagename) + CRLF
    Loop
    Close #1

    h$ = h$ + "</div>" + CRLF ' container
    h$ = h$ + "</body>" + CRLF
    h$ = h$ + "</html>" + CRLF
    full_html = h$
End Function

Function load_page$ (pagename as String)
    title$ = "Jamon Holmgren's Personal Website"

    ' check if pagename starts with a slash and remove it
    If Left$(pagename, 1) = "/" Then
        pagename = Mid$(pagename, 2)
    End If

    h$ = ""
    ' Read the page and return it
    Open "./web/pages/" + pagename + ".html" For Input As #1
    Do While Not EOF(1)
       Line Input #1, line$
       
       if line$ = "<!--TITLE" Then
           h$ = h$ + line$ + CRLF
           ' next line is the title! let's store it
           Line Input #1, line$
           title$ = line$
       End If
    
       h$ = h$ + process_template(line$, pagename) + CRLF
    Loop
    Close #1

    load_page = full_html$(title$, h$, pagename)
End Function

Function load_static$ (filename as String)
    h$ = ""
    
    Open "./web" + filename For Input As #1
    Do While Not EOF(1)
       Line Input #1, line$
       h$ = h$ + line$ + CRLF
    Loop
    Close #1

    load_static = h$
End Function

Sub DebugLog(s as String)
    if ENABLE_LOG = 1 then
        Print s
    end if
End Sub
