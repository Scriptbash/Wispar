#define MyAppName "Wispar"
#define MyAppVersion "0.0.0+0"
#define MyAppPublisher "Scriptbash"
#define MyAppURL "https://wispar.app"
#define MyAppSupportURL "https://github.com/Scriptbash/Wispar/issues"
#define MyAppExeName "wispar.exe"

[Setup]
AppId={{2515FBD1-05EF-45BA-B7AA-0FF2319A1DEE}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
;AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppSupportURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={autopf}\{#MyAppName}
UninstallDisplayIcon={app}\{#MyAppExeName}
; "ArchitecturesAllowed=x64compatible" specifies that Setup cannot run
; on anything but x64 and Windows 11 on Arm.
ArchitecturesAllowed=x64compatible
; "ArchitecturesInstallIn64BitMode=x64compatible" requests that the
; install be done in "64-bit mode" on x64 or Windows 11 on Arm,
; meaning it should use the native 64-bit Program Files directory and
; the 64-bit view of the registry.
ArchitecturesInstallIn64BitMode=x64compatible
DisableProgramGroupPage=yes
LicenseFile=../../LICENSE
; Uncomment the following line to run in non administrative install mode (install for current user only).
;PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
OutputDir=output
OutputBaseFilename=wispar_setup
SetupIconFile=../../website/static/img/favicon.ico
SolidCompression=yes
WizardStyle=modern

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "arabic"; MessagesFile: "compiler:Languages\Arabic.isl"
Name: "armenian"; MessagesFile: "compiler:Languages\Armenian.isl"
Name: "brazilianportuguese"; MessagesFile: "compiler:Languages\BrazilianPortuguese.isl"
Name: "bulgarian"; MessagesFile: "compiler:Languages\Bulgarian.isl"
Name: "catalan"; MessagesFile: "compiler:Languages\Catalan.isl"
Name: "corsican"; MessagesFile: "compiler:Languages\Corsican.isl"
Name: "czech"; MessagesFile: "compiler:Languages\Czech.isl"
Name: "danish"; MessagesFile: "compiler:Languages\Danish.isl"
Name: "dutch"; MessagesFile: "compiler:Languages\Dutch.isl"
Name: "finnish"; MessagesFile: "compiler:Languages\Finnish.isl"
Name: "french"; MessagesFile: "compiler:Languages\French.isl"
Name: "german"; MessagesFile: "compiler:Languages\German.isl"
Name: "hebrew"; MessagesFile: "compiler:Languages\Hebrew.isl"
Name: "hungarian"; MessagesFile: "compiler:Languages\Hungarian.isl"
Name: "italian"; MessagesFile: "compiler:Languages\Italian.isl"
Name: "japanese"; MessagesFile: "compiler:Languages\Japanese.isl"
Name: "korean"; MessagesFile: "compiler:Languages\Korean.isl"
Name: "norwegian"; MessagesFile: "compiler:Languages\Norwegian.isl"
Name: "polish"; MessagesFile: "compiler:Languages\Polish.isl"
Name: "portuguese"; MessagesFile: "compiler:Languages\Portuguese.isl"
Name: "russian"; MessagesFile: "compiler:Languages\Russian.isl"
Name: "slovak"; MessagesFile: "compiler:Languages\Slovak.isl"
Name: "slovenian"; MessagesFile: "compiler:Languages\Slovenian.isl"
Name: "spanish"; MessagesFile: "compiler:Languages\Spanish.isl"
Name: "swedish"; MessagesFile: "compiler:Languages\Swedish.isl"
Name: "tamil"; MessagesFile: "compiler:Languages\Tamil.isl"
Name: "turkish"; MessagesFile: "compiler:Languages\Turkish.isl"
Name: "ukrainian"; MessagesFile: "compiler:Languages\Ukrainian.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "../../build/windows/runner/Release/{#MyAppExeName}"; DestDir: "{app}"; Flags: ignoreversion
Source: "../../build/windows/runner/Release/flutter_inappwebview_windows_plugin.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "../../build/windows/runner/Release/flutter_local_notifications_windows.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "../../build/windows/runner/Release/flutter_windows.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "../../build/windows/runner/Release/msvcp140.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "../../build/windows/runner/Release/msvcp140_1.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "../../build/windows/runner/Release/msvcp140_2.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "../../build/windows/runner/Release/pdfium.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "../../build/windows/runner/Release/pdfrx.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "../../build/windows/runner/Release/permission_handler_windows_plugin.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "../../build/windows/runner/Release/share_plus_plugin.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "../../build/windows/runner/Release/url_launcher_windows_plugin.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "../../build/windows/runner/Release/vcruntime140.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "../../build/windows/runner/Release/vcruntime140_1.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "../../build/windows/runner/Release/WebView2Loader.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "../../build/windows/runner/Release/data\*"; DestDir: "{app}\data"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

