' Maxpsoft May 30, 2013, 9:34:15 PM
' 06/18/2013 Add extra for Bing Desktop v1.3
' 06/28/2013 Updated to continue searching as long as it is finding something otherwise Quit
' 05/02/2014 By adding KB and Bing Bar it gets them all and so far has not come back
'
' Original Mike.Moore Dec 17, 2012 on answers.microsoft but when ran it Hide everything so no good.
' Link to script: http://www.msfn.org/board/topic/163162-hide-bing-desktop-and-other-windows-updates/
' You may freely use this script as long as you copy it complete and it remains the same except for adjusting hideupdates.
' If I need to change something then let me know so all may benefit.

Dim WSHShell, StartTime, ElapsedTime, strUpdateName, strAllHidden
Dim Checkagain 'Find more keep going otherwise Quit

Dim hideupdates(11)    'TO ADD 1 EDIT THE (11) AND ADD another hideupdates(#)

hideupdates(0) = "KB2592687" 'Remote Desktop Protocol 8.0
hideupdates(1) = "KB2861855" 'Remote Desktop Protocol 8.0
hideupdates(2) = "KB2574819" 'Remote Desktop.
hideupdates(3) = "KB2830477" 'Remote Desktop
hideupdates(4) = "KB2709981" 'Windows Media Player 12
hideupdates(5) = "KB2803821" 'Windows Media Player 12
hideupdates(6) = "Bing Desktop" 'With this we get all versions
hideupdates(7) = "Internet Explorer 8"
hideupdates(8) = "Internet Explorer 9"
hideupdates(9) = "Internet Explorer 10"
hideupdates(10) = "KB2673774" 'Bing Bar 7.3 KB
hideupdates(11) = "Bing Bar" 'Bing Bar ALL
hideupdates(12) = "Silverlight" 'All Silverlight nonsense
hideupdates(13) = "KB2483139" 'Language Packs

Set WSHShell = CreateObject("WScript.Shell")

StartTime = Timer 'Start the Timer

Set updateSession = CreateObject("Microsoft.Update.Session")
updateSession.ClientApplicationID = "MSDN Sample Script"
Set updateSearcher = updateSession.CreateUpdateSearcher()
Set searchResult = updateSearcher.Search("IsInstalled=0 and Type='Software' and IsHidden=0")

Checkagain = "True"

For K = 0 To 10 'Bing Desktop has 4, Silverlight has 5
  If Checkagain = "True" Then
    Checkagain = "False"
    CheckUpdates
    ParseUpdates
  End if
Next

ElapsedTime = Timer - StartTime
strTitle = "Bing Desktop and Windows Updates Hidden."
strText = strAllHidden
strText = strText & vbCrLf & ""
strText = strText & vbCrLf & "Total Time " & ElapsedTime
intType = vbOkOnly

'Silent just comment these 2 lines with a ' and it will run and quit
'Set objWshShell = WScript.CreateObject("WScript.Shell")
'intResult = objWshShell.Popup(strText, ,strTitle, intType)

'Open Windows Update after remove the comment '
'WshShell.Run "%windir%\system32\control.exe /name Microsoft.WindowsUpdate"

'Set objWshShell = nothing
'Set WSHShell = Nothing
WScript.Quit

Function ParseUpdates 'cycle through updates
  For I = 0 To searchResult.Updates.Count-1
    Set update = searchResult.Updates.Item(I)
    strUpdateName = update.Title
    'WScript.Echo I + 1 & "> " & update.Title
    For j = 0 To UBound(hideupdates)
    if instr(1, strUpdateName, hideupdates(j), vbTextCompare) = 0 then
    Else
          strAllHidden = strAllHidden _
          & vbcrlf & update.Title
      update.IsHidden = True'
      Checkagain = "True"
    end if
    Next
  Next
End Function

Function CheckUpdates 'check for new updates cause Bing Desktop has 3
  Set updateSession = CreateObject("Microsoft.Update.Session")
  updateSession.ClientApplicationID = "MSDN Sample Script"
  Set updateSearcher = updateSession.CreateUpdateSearcher()
  Set searchResult = _
  updateSearcher.Search("IsInstalled=0 and Type='Software' and IsHidden=0")
End Function