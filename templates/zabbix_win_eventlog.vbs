'2011.05.03


Dim objFSO, strCurPath, strDateFile
Set objFSO = CreateObject("Scripting.FileSystemObject")
strCurPath = objFSO.GetParentFolderName(WScript.ScriptFullName)
strDateFile = "zabbix_win_eventlog.datetime"

Dim FOR_READ, FOR_WRITE
FOR_READ = 1
FOR_WRITE = 2


Dim ET_ERROR, ET_WARNING, ET_INFO, ET_AUDIT_SUCCESS, ET_AUDIT_FAILURE
ET_ERROR = 1
ET_WARNING = 2
ET_INFO = 3
ET_AUDIT_SUCCESS = 4
ET_AUDIT_FAILURE = 5


'CHECK ARGUMENTS
Function CheckArguments(nArgs, expArgs)
On Error Resume Next
	If (nArgs < expArgs) Then
		Call WScript.echo("Not enough arguments (" & nArgs & "/" & expArgs & ").")
		WScript.Quit		
	End If
End Function


'FUNCTION FINDDATE
Function FindDate(strFile, strLogFile, strSource, strEventID, strEventType, ByRef strTimeDate) 
	'RESULT
	FindDate = False

	strSplit = Split(strFile, vbCrLf)
		
	'MULTIPLE ENTRIES
	If (UBound(strSplit) >= 0) Then
		For x = LBound(strSplit) To UBound(strSplit)
			strEntrySplit = Split(strSplit(x), ",")
	
			'MATCH
			If (StrComp(strEntrySplit(0), strLogFile, 1) = 0) And (StrComp(strEntrySplit(1), strSource, 1) = 0) And (StrComp(strEntrySplit(2), strEventID, 1) = 0) And (StrComp(strEntrySplit(3), strEventType, 1) = 0) Then
				'UPDATE DATE
				strTimeDate = strEntrySplit(4)
				'RESULT
				FindDate = True
				'BAIL
				Exit For
			End If
		Next
	End If
End Function


'FUNCTION SETDATE
Function SetDate(ByRef strFile, strLogFile, strSource, strEventID, strEventType)
	strSplit = Split(strFile, vbCrLf)
	
	Found = False
	
	'MULTIPLE ENTRIES
	If (UBound(strSplit) >= 0) Then
		For x = LBound(strSplit) To UBound(strSplit)
			strEntrySplit = Split(strSplit(x), ",")
			
			'MATCH
			If (StrComp(strEntrySplit(0), strLogFile, 1) = 0) And (StrComp(strEntrySplit(1), strSource, 1) = 0) And (StrComp(strEntrySplit(2), strEventID, 1) = 0) And (StrComp(strEntrySplit(3), strEventType, 1) = 0) Then
				'UPDATE DATE
				strSplit(x) = strEntrySplit(0) & "," & strEntrySplit(1) & "," & strEntrySplit(2) & "," & strEntrySplit(3) & "," & Now			
				'FOUND
				Found = True
				'BAIL
				Exit For
			End If
		Next
						
		strFile = ""
			
		'MAKE FILE AGAIN
		For x = LBound(strSplit) To UBound(strSplit)
			strFile = strFile & strSplit(x)
			'CRLF
			If (x < UBound(strSplit)) Then strFile = strFile & vbCrLf
		Next
		
		'ADD NEW ENTRY	
		If (Found = False) Then strFile = strFile & vbCrLf & strLogFile & "," & strSource & "," & strEventID & "," & strEventType & "," & Now
	Else
		'ONE ENTRY
		strFile = strLogFile & "," & strSource & "," & strEventID & "," & strEventType & "," & Now
	End If
End Function


'FORMAT EVENT
Function FormatEvent(strTimeDate, strMessage)
	FormatEvent = "Event datetime: <font color=#606060> " & strTimeDate & " </font><br>" & _
				  "Event message: <font color=#606060> " & Replace(strMessage, vbCrLf, "<br>") & "</font><br><br>"
End Function


'GET EVENT DATA
Function GetEventData(strTimeDate, strLogFile, strSource, strEventID, strEventType)
	'CONVERT DATE
	Dim dtmTimeDate, objWMI
	Set dtmTimeDate = CreateObject("WbemScripting.SWbemDateTime")
	Call dtmTimeDate.SetVarDate(strTimeDate, True)

	'RESULT
	GetEventData = ""

	'GET UNEXPECTED EVENT FROM NOW TO DATE
	Set objWMI = GetObject("winmgmts:\\.\root\cimv2")	

	Dim quEventID, quEventType
	quEventID = ""
	quEventType = ""
	
	'QUERY FOR EVENTID
	If (StrComp(strEventID, "*", 1) <> 0) Then quEventID = "And(EventCode = '" & strEventID & "')"
	'QUERY FOR EVENT TYPE
	If (StrComp(strEventType, "*", 1) <> 0) Then quEventType = "And(EventType = '" & strEventType & "')"	
	
	Dim colEvents, objEvent
	Set colEvents = objWMI.ExecQuery("Select * from Win32_NTLogEvent Where (TimeGenerated >= '" & dtmTimeDate & "')And(Logfile = '" & strLogFile &"')And(SourceName = '" & strSource & "')" & quEventID & quEventType)

	'NOT EMPTY
	If (Not IsEmpty(colEvents)) Then
		If (colEvents.Count > 0) Then	
			'EACH EVENT FOUND
			For Each objEvent In colEvents	
				'CONVERT DATE
				dtmTimeDate.Value = objEvent.TimeGenerated
				'GET EVENT DATA
				GetEventData = GetEventData & FormatEvent(dtmTimeDate.GetVarDate, objEvent.Message)
			Next					
		End If
	End If
End Function	



'ARGUMENTS
' 0 = LOG FILE
' 1 = SOURCE
' 2 = EVENTID
' 3 = EVENT TYPE

'CHECK ARGUMENTS
Call CheckArguments(WScript.Arguments.Count, 4)

Dim strLogFile, strSource, strEventID, strEventType
strLogFile = Replace(WScript.Arguments(0), "_", " ")
strSource = Replace(WScript.Arguments(1), "_", " ")
strEventID = WScript.Arguments(2)
strEventType = WScript.Arguments(3)

'READ PREVIOUS DATE
Dim objFile, strFile, strTimeDate, nDay

If (objFSO.FileExists(strCurPath & "\" & strDateFile)) Then
	Set objFile = objFSO.GetFile(strCurPath & "\" & strDateFile)
	'FILE NOT EMPTY
	If (objFile.Size > 0) Then
		Set objFile = objFSO.OpenTextFile(strCurPath & "\" & strDateFile, FOR_READ, True)
		strFile = objFile.Readall
		objFile.Close
	End If

	'FAIL TO CURRENT DATE
	If (Not FindDate(strFile, strLogFile, strSource, strEventID, strEventType, strTimeDate)) Then strTimeDate = Now
Else
	'FAIL TO CURRENT DATE
	strTimeDate = Now	
End If

Dim strResult
strResult = GetEventData(strTimeDate, strLogFile, strSource, strEventID, strEventType)

'RETURN
If (Len(strResult) > 0) Then
	Call Wscript.Echo(strResult)
Else
	Call WScript.Echo("-")
End If

'RETURN
Call Wscript.Echo(strResult)

'WRITE DATE
Set objFile = objFSO.OpenTextFile(strCurPath & "\" & strDateFile, FOR_WRITE, True)
'SET DATE TO FILE
Call SetDate(strFile, strLogFile, strSource, strEventID, strEventType)
objFile.Write(strFile)
objFile.Close