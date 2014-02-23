;;
;; TVDeploy (TeamViewer Deploy Tool)
;;
;;
;; This is Autoit script that does the following things, in this very order:
;; 1. Downloads setup file from $SETUP_URL
;; 2. Executes setup in silent mode
;; 3. Stops TeamViewer service and processes
;; 4. Downloads registry file containing TeamViewer's settings via teamviewer.php
;;    Also sends ClientID and @ComputerName to teamviewer.php that can later mail
;;    the administrator with these details.
;; 5. Imports registry file with settings
;; 6. Deletes no longer required setup and registry file
;; 7. Starts TeamViewer service
;;


;;
;; Settings
;;

;; URL to download the installer from
$SETUP_URL = "http://download.teamviewer.com/download/TeamViewer_Host_Setup.exe"
;; URL to the php script serving registry file and processing registration
$REG_SCRIPT = "http://repo.local/teamviewer.php"

;;
;; DO NOT MODIFY ANYTHIN THIS LINE UNLESS YOU ARE ABSOLUTELY KNOW THAT YOU KNOW WHAT YOU DOING
;;
#include <InetConstants.au3>

;; Define properties of the exe file
#pragma compile(FileVersion, 1.0.0)
#pragma compile(ProductVersion, 1.0.0)
#pragma compile(ProductName, TVDeploy)
#pragma compile(LegalCopyright, (C)2014 Mike Nowak)

;; Require Administrator privileges to avoid registry import warning
#RequireAdmin

;; Download TeamViewer Host setup directly from the vendor
;; and place in the @TempDir
$SETUP_PATH = @TempDir & "\teamviewer.exe"
If Not @error Then
   $SETUP_INET = InetGet($SETUP_URL,$SETUP_PATH,1,1)
   Do
    Sleep(250)
   Until InetGetInfo($SETUP_INET, $INET_DOWNLOADCOMPLETE)
   InetClose($SETUP_INET)
EndIf

;; Run Setup in /Silent mode
ShellExecuteWait($SETUP_PATH, "/S")

;; Stop Teamviewer service and close processes
RunWait(@ComSpec & " /c " & 'net stop TeamViewer9', "", @SW_HIDE)
ProcessClose("TeamViewer.exe")

;; Set registry root path based on @OSArch
If @OSArch == "X86" Then
   $REG_ROOT = "HKEY_LOCAL_MACHINE\SOFTWARE\TeamViewer\Version9"
EndIf
If @OSArch == "X64" Then
   $REG_ROOT = "HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\TeamViewer\Version9"
EndIf

;; Find TeamViewer's ClientID based on registry entry
$id =  RegRead ( $REG_ROOT , "ClientID" )

;; Download registry file (provided by the teamviewer.php script), based on architecture
;; also pass ClientID and ComputerName as parameters. This will result in an email
;; with these details being sent to the administrator.
$REG_URL = $REG_SCRIPT & "?id=" & $id & "&arch=" & @OSArch & "&hostname=" & @ComputerName
$REG_PATH = @TempDir & "\teamviewer.reg"
If Not @error Then
   $REG_INET = InetGet($REG_URL,$REG_PATH,1,1)
   Do
    Sleep(250)
   Until InetGetInfo($REG_INET, $INET_DOWNLOADCOMPLETE)
   InetClose($REG_INET)
EndIf

;; Import to registry
ShellExecuteWait("Regedit.exe", "/S " & $REG_PATH, "", "", @SW_HIDE)

;; Remove setup and regfiles
FileDelete($REG_PATH)
FileDelete($SETUP_PATH)

;; Start TeamViewer service
RunWait(@ComSpec & " /c " & 'net start TeamViewer9', "", @SW_HIDE)

