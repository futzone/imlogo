; Imlo Go — Windows o'rnatuvchi (Inno Setup 6).
;
; CI (.github/workflows/windows.yml) quyidagilarni /D orqali uzatadi:
;   AppVersion  — pubspec.yaml dagi versiya, masalan 1.1.0
;   SourceDir   — `flutter build windows --release` natijasi (Release papkasi)
;   OutputDir   — tayyor Setup.exe yoziladigan papka
;
; Qo'lda yig'ish (Windows'da, loyiha ildizidan):
;   flutter build windows --release
;   iscc /DAppVersion=1.1.0 windows\installer\imlogo.iss
;
; Eslatma: Inno Setup'ning rasmiy tillar to'plamida o'zbek tili yo'q,
; shuning uchun ingliz (standart) va rus tillari ishlatiladi.

#ifndef AppVersion
  #define AppVersion "1.0.0"
#endif
#ifndef SourceDir
  #define SourceDir "..\..\build\windows\x64\runner\Release"
#endif
#ifndef OutputDir
  #define OutputDir "..\..\build\installer"
#endif

#define AppName "Imlo Go"
#define AppPublisher "Imlogo.uz"
#define AppURL "https://imlogo.uz"
#define AppExeName "dication.exe"

[Setup]
; AppId o'zgarmasligi kerak — yangilanishlar shu ID orqali eski versiya ustiga o'rnatiladi.
AppId={{3155704C-990E-41FC-B50A-F195C0EE67BB}
AppName={#AppName}
AppVersion={#AppVersion}
AppVerName={#AppName} {#AppVersion}
AppPublisher={#AppPublisher}
AppPublisherURL={#AppURL}
AppSupportURL={#AppURL}
AppUpdatesURL={#AppURL}
VersionInfoVersion={#AppVersion}
VersionInfoProductName={#AppName}
VersionInfoCompany={#AppPublisher}
DefaultDirName={autopf}\{#AppName}
DefaultGroupName={#AppName}
DisableProgramGroupPage=yes
; Administrator huquqisiz ham o'rnatish mumkin (foydalanuvchi o'zi tanlaydi).
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
SetupIconFile=..\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\{#AppExeName}
UninstallDisplayName={#AppName}
OutputDir={#OutputDir}
OutputBaseFilename=ImloGo-Setup-{#AppVersion}
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
CloseApplications=yes

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "russian"; MessagesFile: "compiler:Languages\Russian.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "{#SourceDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#AppName}"; Filename: "{app}\{#AppExeName}"
Name: "{group}\{cm:UninstallProgram,{#AppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#AppExeName}"; Description: "{cm:LaunchProgram,{#AppName}}"; Flags: nowait postinstall skipifsilent
