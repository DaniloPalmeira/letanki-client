; Instalador do LeTanki: empacota build\ (a saida do package.ps1).
;
; Compila com o installer.ps1, que roda o package.ps1 antes -- assim o
; instalador nunca sai de um build velho.
;
; Inno Setup de proposito: o instalador original do LeTanki era Inno, e o
; unins000.exe/unins000.dat que ele deixava no disco e a assinatura disso.
; O adt tem -target native, mas ele embarca o runtime do proprio SDK (AIR 32)
; e o cliente roda no AIR 22 de deps\ -- por isso o empacotamento fica fora
; do adt.

#define AppName "LeTanki"
#define AppVersion "1.1"

[Setup]
; AppId nunca muda: e por ele que o Windows reconhece uma instalacao
; existente para atualizar em vez de duplicar.
AppId={{D68AA629-7BB0-43C6-9910-2FED8FF53D0C}
AppName={#AppName}
AppVersion={#AppVersion}
DefaultDirName={autopf}\LeTanki Online
DefaultGroupName={#AppName}
UninstallDisplayIcon={app}\LeTanki.exe
; Program Files exige elevacao. Da para instalar ai porque o cliente nao
; escreve ao lado do exe: o que ele guarda vai para %APPDATA%\LeTanki.
PrivilegesRequired=admin
; Sem isso o {autopf} de um instalador 32 bits cai em "Program Files (x86)".
ArchitecturesInstallIn64BitMode=x64compatible
; O .ico e montado pelo installer.ps1 a partir de icons\.
SetupIconFile=obj\LeTanki.ico
DisableProgramGroupPage=yes
OutputDir=dist
OutputBaseFilename=LeTanki-setup
Compression=lzma2/max
SolidCompression=yes

[Languages]
Name: "brazilianportuguese"; MessagesFile: "compiler:Languages\BrazilianPortuguese.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
; build\ inteiro: exe, META-INF, mimetype, icones, o SWF e o runtime captive.
Source: "build\*"; DestDir: "{app}"; Flags: recursesubdirs createallsubdirs ignoreversion

[Icons]
Name: "{group}\{#AppName}"; Filename: "{app}\LeTanki.exe"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\LeTanki.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\LeTanki.exe"; Description: "{cm:LaunchProgram,{#AppName}}"; Flags: nowait postinstall skipifsilent
