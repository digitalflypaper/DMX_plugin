'v.0.5
' dmxTracks
' (c) Digitalflypaper, 2024
'
'This plugin takes the currently playing video and looks for a matching ".dmx" file
' this matching .dmx track is a simple JSON object with timecodes (in Seconds) and commands. 
' This plugin is inactive if the .dmx file is not found.
' the commands will be sent to the compatible DMX USB serial device
'
' The .dmx track file json format:
' {
'   "filename":"video_file_name.mp4",
'   "timedata":
'   [
'       {
'           "time_sec":"0",
'           "tag":"1:0,2:123"
'       },
'       {
'           "time_sec":"0.83215",
'           "tag":"2:222"
'       },
'       ..
'       ..
'       {
'           "time_sec":"118.010515",
'           "tag":"1:0"
'       }
'   ]
' }

Function DMX_Initialize(msgPort As Object, userVariables As Object, bsp as Object)

    print "DMX_Initialize - entry"
    print "type of msgPort is ";type(msgPort)
    print "type of userVariables is ";type(userVariables)

    DMX = newDMX(msgPort, userVariables, bsp)
	
    return DMX

End Function


Function newDMX(msgPort As Object, userVariables As Object, bsp as Object)
	print "initDMX"

	' Create the object to return and set it up
	
	s = {}
	s.msgPort = msgPort
	s.userVariables = userVariables
	s.bsp = bsp
	s.ProcessEvent = DMX_ProcessEvent
	s.vm=CreateObject("roVideoMode")
	s.HandleVideoEventPlugin = HandleVideoEventPlugin

    s.objectName = "DMX_object"
    s.serial = CreateObject("roSerialPort", 2, 115200)
    print type(s.serial)

	return s

End Function


Function DMX_ProcessEvent(event As Object) as boolean

	retval = false
    'print "DMX_ProcessEvent - entry"
    'print "type of m is ";type(m)
    'print "type of event is ";type(event)

	if type(event) = "roVideoEvent" then			
		retval = HandleVideoEventPlugin(event, m)

    else if type(event) = "roAssociativeArray" then

        	if type(event["EventType"]) = "roString" then
             		if (event["EventType"] = "SEND_PLUGIN_MESSAGE") then
                		if event["PluginName"] = "DMX" then
                    		pluginMessage$ = event["PluginMessage"]
							print "SEND_PLUGIN/EVENT_MESSAGE: ";pluginMessage$
							'messageToParse$ = event["PluginName"]+"!"+pluginMessage$
							'm.dlog("Plugin Message: ===> "+pluginMessage$)
                            retval = ParsePluginMsg(pluginMessage$, m)
					
                		endif
            		endif
        	endif
		
	end if
	
	'debug
	return retval

End Function
	

Function HandleVideoEventPlugin(origMsg as Object, s as Object) as boolean
	if type(origMsg) = "roVideoEvent" then		
		'stop
        print '*** Video Event **** '
		if origMsg.GetInt() = 3 then
            'm.serial = CreateObject("roSerialPort", 2, 115200)
            print "Video Start checking for active state/file name"
	        print m.bsp.sign.zoneshsm[0].activestate.name$

            name$= m.bsp.sign.zoneshsm[0].activestate.name$
            lname= len(name$)
            tpos = instr(1, name$, ".")
            fname$ = left(name$, tpos)
            fullname$ = fname$+"dmx"
            
            m.trackFilePath$ = m.bsp.assetpoolfiles.GetPoolFilePath(fullname$)

            if m.trackFilePath$ <> "" then
                m.FileRead = ReadAsciiFile(m.trackFilePath$)
            
                'print " m.FileRead " + Chr(13) + Chr(10) m.FileRead
                tc = ParseJson(m.FileRead)
                tid = 0
                'm.tStamps.clear()
                'm.codes.clear()
                m.codes = CreateObject("roArray", 1, true)

                For Each tcode In tc.timedata
                        time_in_ms = INT(tcode.time_sec.tofloat()*1000)
                        'print time_in_ms, tcode.tag, tid
                        'm.tStamps.push(time_in_ms)
                        m.codes.push(tcode.tag)
                        eventx = m.bsp.sign.zoneshsm[0].videoplayer.AddEvent(tid, time_in_ms)
                        tid = tid + 1
                        'print "!!!Eventx!!!!!" eventx; tcode.tag; time_in_ms
                End For
            end if
            
        else if origMsg.GetInt() = 12 then
            id = origMsg.GetData()
            print "TimeCode event Received" id, m.codes[id]
            sendDMXcommand(s, m.codes[id]) 
    
        else if origMsg.GetInt() = 8 then
            'print "Video End Event Received"
        
		end if
	end if

End Function

Sub sendDMXcommand(s as object, code$ as String) 
	if type(s.serial) = "roSerialPort" then
        print "sending code: ", code$
	    s.serial.SendLine(code$) 
    else
        print "problem with serial port init.", type(s.serial), code$
	end if	
End Sub

Function ParsePluginMsg(origMsg as string, s as object) as boolean
	retval = true
	print "in ParsePluginMsg", origMsg

	'convert the message to all lower case for easier string matching later
	msg = lcase(origMsg)
	print "Received Plugin message: " + msg
	'verify its a DMX message'

    sendDMXcommand(s, msg) 

	return (retVal)
end Function

