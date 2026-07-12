; Inno Setup script for Bay Tracker.
;
; Produces a single-file Windows installer (BayTrackerSetup.exe) that installs
; the app per-user (no admin rights required), creates Start Menu / optional
; desktop shortcuts, and registers a normal Windows uninstaller. The app
; creates its own SQLite database on first run (see lib/db/database_helper.dart)
; so there is nothing else for the end user to set up.
;
; Build first: flutter build windows --release
; Then compile: ISCC packaging\installer.iss   (run from the repo root, or
; adjust MyBuildDir below if run from elsewhere)

#define MyAppName "Bay Tracker"
#define MyAppVersion "1.2.0"
#define MyAppPublisher "Brattynn Thompson"
#define MyAppExeName "graphics_bay_tracker.exe"
#define MyBuildDir "..\build\windows\x64\runner\Release"

[Setup]
AppId={{E6CF4DEB-A10C-441F-89FE-B9A74E6E0689}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={localappdata}\Programs\{#MyAppName}
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
; Per-user install: no UAC prompt, works even without admin rights on a work PC.
PrivilegesRequired=lowest
OutputDir=Output
OutputBaseFilename=BayTrackerSetup
SetupIconFile=..\windows\runner\resources\app_icon.ico
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
UninstallDisplayIcon={app}\{#MyAppExeName}
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "{#MyBuildDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\Uninstall {#MyAppName}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#MyAppName}}"; Flags: nowait postinstall skipifsilent
