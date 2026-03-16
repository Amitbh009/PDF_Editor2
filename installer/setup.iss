[Setup]
AppName=PDF Editor Pro
AppVersion=1.0.0
AppPublisher=PDF Editor Pro
DefaultDirName={autopf}\PDF Editor Pro
DefaultGroupName=PDF Editor Pro
OutputBaseFilename=PDFEditorProSetup
OutputDir=installer_output
Compression=lzma
SolidCompression=yes

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\PDF Editor Pro"; Filename: "{app}\pdf_editor_pro.exe"
Name: "{group}\{cm:UninstallProgram,PDF Editor Pro}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\PDF Editor Pro"; Filename: "{app}\pdf_editor_pro.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\pdf_editor_pro.exe"; Description: "{cm:LaunchProgram,PDF Editor Pro}"; Flags: nowait postinstall skipifsilent
