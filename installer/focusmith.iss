; FOCUSMITH Windows installer (Inno Setup 6)
; Build: scripts\build-installer.ps1
; Manual: ISCC.exe /DMyAppVersion=1.2.0 /DMyAppBuild=3 installer\focusmith.iss

#ifndef MyAppVersion
  #define MyAppVersion "1.2.0"
#endif
#ifndef MyAppBuild
  #define MyAppBuild "3"
#endif

#define MyAppName "FOCUSMITH"
#define MyAppPublisher "FOCUSMITH"
#define MyAppExeName "focusmith.exe"
#define BuildDir "..\build\windows\x64\runner\Release"

[Setup]
; Fixed AppId — keep unchanged so upgrades replace the same install entry.
AppId={{E4A91C2D-8B5F-4E3A-9D1C-7F6E5A4B3C2D}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion} ({#MyAppBuild})
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
AllowNoIcons=yes
OutputDir=..\dist
OutputBaseFilename=FOCUSMITH-Setup-{#MyAppVersion}
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
UninstallDisplayIcon={app}\{#MyAppExeName}
#ifexist "..\windows\runner\resources\app_icon.ico"
SetupIconFile=..\windows\runner\resources\app_icon.ico
#endif
VersionInfoVersion={#MyAppVersion}.{#MyAppBuild}
VersionInfoCompany={#MyAppPublisher}
VersionInfoDescription={#MyAppName} — Focus-driven workspace
VersionInfoProductName={#MyAppName}
VersionInfoProductVersion={#MyAppVersion}.{#MyAppBuild}

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "{#BuildDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

[Code]
function InitializeUninstall(): Boolean;
var
  AppDataDir: String;
begin
  Result := True;
  AppDataDir := ExpandConstant('{userappdata}\FOCUSMITH');
  if DirExists(AppDataDir) then
  begin
    if MsgBox(
      'Also remove your local workspace data (stories, notes, settings)?' + #13#10 + #13#10 +
      AppDataDir,
      mbConfirmation, MB_YESNO or MB_DEFBUTTON2) = IDYES then
    begin
      DelTree(AppDataDir, True, True, True);
    end;
  end;
end;
