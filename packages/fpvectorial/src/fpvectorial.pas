{
fpvectorial.pas

Vector graphics document

License: The same modified LGPL as the Free Pascal RTL
         See the file COPYING.modifiedLGPL for more details

AUTHORS: Felipe Monteiro de Carvalho
         Pedro Sol Pegorini L de Lima
}
unit fpvectorial;

{$ifdef fpc}
  {$mode delphi}
{$endif}

interface

uses
  Classes, SysUtils;

type
  TvVectorialFormat = (
    { Multi-purpose document formats }
    vfPDF, vfPostScript, vfSVG, vfCorelDrawCDR, vfWindowsMetafileWMF,
    { CAD formats }
    vfDXF,
    { GCode formats }
    vfGCodeAvisoCNCPrototipoV5, vfGCodeAvisoCNCPrototipoV6);

const
  { Default extensions }
  { Multi-purpose document formats }
  STR_PDF_EXTENSION = '.pdf';
  STR_POSTSCRIPT_EXTENSION = '.ps';
  STR_SVG_EXTENSION = '.svg';
  STR_CORELDRAW_EXTENSION = '.cdr';
  STR_WINMETAFILE_EXTENSION = '.wmf';

type
  TSegmentType = (
    st2DLine, st2DBezier,
    st3DLine, st3DBezier, stMoveTo);

  {@@
    The coordinates in fpvectorial are given in millimiters and
    the starting point is in the bottom-left corner of the document.
    The X grows to the right and the Y grows to the top.
  }
  TPathSegment = record
    SegmentType: TSegmentType;
    X, Y, Z: Double; // Z is ignored in 2D segments
    X2, Y2, Z2: Double; // Z is ignored in 2D segments
    X3, Y3, Z3: Double; // Z is ignored in 2D segments
  end;

  TPath = record
    Len: Integer;
    // ToDo: make the array dynamic
    Points: array[0..255] of TPathSegment;
  end;

  PPath = ^TPath;

  {@@
    TvText represents a text in memory.

    At the moment fonts are unsupported, only simple texts
    up to 255 chars are supported.
  }

  TvText = record
    X, Y, Z: Double; // Z is ignored in 2D formats
    FontSize: integer;
    FontName: utf8string;
    Value: utf8string;
  end;

  PText = ^TvText;

type

  TvCustomVectorialWriter = class;
  TvCustomVectorialReader = class;

  { TvVectorialDocument }

  TvVectorialDocument = class
  private
    FPaths: TFPList;
    FTexts: TFPList;
    FTmpPath: TPath;
    FTmpText: TvText;
    procedure RemoveCallback(data, arg: pointer);
    function CreateVectorialWriter(AFormat: TvVectorialFormat): TvCustomVectorialWriter;
    function CreateVectorialReader(AFormat: TvVectorialFormat): TvCustomVectorialReader;
  public
    Name: string;
    Width, Height: Double; // in millimeters
    { Base methods }
    constructor Create;
    destructor Destroy; override;
    procedure WriteToFile(AFileName: string; AFormat: TvVectorialFormat);
    procedure WriteToStream(AStream: TStream; AFormat: TvVectorialFormat);
    procedure WriteToStrings(AStrings: TStrings; AFormat: TvVectorialFormat);
    procedure ReadFromFile(AFileName: string; AFormat: TvVectorialFormat);
    procedure ReadFromStream(AStream: TStream; AFormat: TvVectorialFormat);
    procedure ReadFromStrings(AStrings: TStrings; AFormat: TvVectorialFormat);
    class function GetFormatFromExtension(AFileName: string): TvVectorialFormat;
    function  GetDetailedFileFormat(): string;
    { Data reading methods }
    function  GetPath(ANum: Cardinal): TPath;
    function  GetPathCount: Integer;
    function  GetText(ANum: Cardinal): TvText;
    function  GetTextCount: Integer;
    { Data removing methods }
    procedure Clear;
    procedure RemoveAllPaths;
    procedure RemoveAllTexts;
    { Data writing methods }
    procedure AddPath(APath: TPath);
    procedure StartPath(AX, AY: Double);
    procedure AddLineToPath(AX, AY: Double); overload;
    procedure AddLineToPath(AX, AY, AZ: Double); overload;
    procedure AddBezierToPath(AX1, AY1, AX2, AY2, AX3, AY3: Double); overload;
    procedure AddBezierToPath(AX1, AY1, AZ1, AX2, AY2, AZ2, AX3, AY3, AZ3: Double); overload;
    procedure EndPath();
    procedure AddText(AX, AY, AZ: Double; FontName: string; FontSize: integer; AText: utf8string); overload;
    procedure AddText(AX, AY, AZ: Double; AStr: utf8string); overload;
    { properties }
    property PathCount: Integer read GetPathCount;
    property Paths[Index: Cardinal]: TPath read GetPath;
  end;

  {@@ TvVectorialReader class reference type }

  TvVectorialReaderClass = class of TvCustomVectorialReader;

  { TvCustomVectorialReader }

  TvCustomVectorialReader = class
  public
    { General reading methods }
    procedure ReadFromFile(AFileName: string; AData: TvVectorialDocument); virtual;
    procedure ReadFromStream(AStream: TStream; AData: TvVectorialDocument); virtual;
    procedure ReadFromStrings(AStrings: TStrings; AData: TvVectorialDocument); virtual;
  end;

  {@@ TvVectorialWriter class reference type }

  TvVectorialWriterClass = class of TvCustomVectorialWriter;

  {@@ TvCustomVectorialWriter }

  { TvCustomVectorialWriter }

  TvCustomVectorialWriter = class
  public
    { General writing methods }
    procedure WriteToFile(AFileName: string; AData: TvVectorialDocument); virtual;
    procedure WriteToStream(AStream: TStream; AData: TvVectorialDocument); virtual;
    procedure WriteToStrings(AStrings: TStrings; AData: TvVectorialDocument); virtual;
  end;

  {@@ List of registered formats }

  TvVectorialFormatData = record
    ReaderClass: TvVectorialReaderClass;
    WriterClass: TvVectorialWriterClass;
    ReaderRegistered: Boolean;
    WriterRegistered: Boolean;
    Format: TvVectorialFormat;
  end;

var
  GvVectorialFormats: array of TvVectorialFormatData;

procedure RegisterVectorialReader(
  AReaderClass: TvVectorialReaderClass;
  AFormat: TvVectorialFormat);
procedure RegisterVectorialWriter(
  AWriterClass: TvVectorialWriterClass;
  AFormat: TvVectorialFormat);

implementation

{@@
  Registers a new reader for a format
}
procedure RegisterVectorialReader(
  AReaderClass: TvVectorialReaderClass;
  AFormat: TvVectorialFormat);
var
  i, len: Integer;
  FormatInTheList: Boolean;
begin
  len := Length(GvVectorialFormats);
  FormatInTheList := False;

  { First search for the format in the list }
  for i := 0 to len - 1 do
  begin
    if GvVectorialFormats[i].Format = AFormat then
    begin
      if GvVectorialFormats[i].ReaderRegistered then
       raise Exception.Create('RegisterVectorialReader: Reader class for format ' {+ AFormat} + ' already registered.');

      GvVectorialFormats[i].ReaderRegistered := True;
      GvVectorialFormats[i].ReaderClass := AReaderClass;

      FormatInTheList := True;
      Break;
    end;
  end;

  { If not already in the list, then add it }
  if not FormatInTheList then
  begin
    SetLength(GvVectorialFormats, len + 1);

    GvVectorialFormats[len].ReaderClass := AReaderClass;
    GvVectorialFormats[len].WriterClass := nil;
    GvVectorialFormats[len].ReaderRegistered := True;
    GvVectorialFormats[len].WriterRegistered := False;
    GvVectorialFormats[len].Format := AFormat;
  end;
end;

{@@
  Registers a new writer for a format
}
procedure RegisterVectorialWriter(
  AWriterClass: TvVectorialWriterClass;
  AFormat: TvVectorialFormat);
var
  i, len: Integer;
  FormatInTheList: Boolean;
begin
  len := Length(GvVectorialFormats);
  FormatInTheList := False;

  { First search for the format in the list }
  for i := 0 to len - 1 do
  begin
    if GvVectorialFormats[i].Format = AFormat then
    begin
      if GvVectorialFormats[i].WriterRegistered then
       raise Exception.Create('RegisterVectorialWriter: Writer class for format ' + {AFormat +} ' already registered.');

      GvVectorialFormats[i].WriterRegistered := True;
      GvVectorialFormats[i].WriterClass := AWriterClass;

      FormatInTheList := True;
      Break;
    end;
  end;

  { If not already in the list, then add it }
  if not FormatInTheList then
  begin
    SetLength(GvVectorialFormats, len + 1);

    GvVectorialFormats[len].ReaderClass := nil;
    GvVectorialFormats[len].WriterClass := AWriterClass;
    GvVectorialFormats[len].ReaderRegistered := False;
    GvVectorialFormats[len].WriterRegistered := True;
    GvVectorialFormats[len].Format := AFormat;
  end;
end;

{ TsWorksheet }

{@@
  Helper method for clearing the records in a spreadsheet.
}
procedure TvVectorialDocument.RemoveCallback(data, arg: pointer);
begin
  if data <> nil then FreeMem(data);
end;

{@@
  Constructor.
}
constructor TvVectorialDocument.Create;
begin
  inherited Create;

  FPaths := TFPList.Create;
  FTexts := TFPList.Create;
end;

{@@
  Destructor.
}
destructor TvVectorialDocument.Destroy;
begin
  Clear;

  FPaths.Free;
  FTexts.Free;

  inherited Destroy;
end;

{@@
  Clears the list of Vectors and releases their memory.
}
procedure TvVectorialDocument.RemoveAllPaths;
begin
  FPaths.ForEachCall(RemoveCallback, nil);
  FPaths.Clear;
end;

procedure TvVectorialDocument.RemoveAllTexts;
begin
  FTexts.ForEachCall(RemoveCallback, nil);
  FTexts.Clear;
end;

procedure TvVectorialDocument.AddPath(APath: TPath);
var
  Path: PPath;
  Len: Integer;
begin
  Len := SizeOf(TPath);
  //WriteLn(':>TvVectorialDocument.AddPath 1 Len = ', Len);
  Path := GetMem(Len);
  //WriteLn(':>TvVectorialDocument.AddPath 2');
  Move(APath, Path^, Len);
  //WriteLn(':>TvVectorialDocument.AddPath 3');
  FPaths.Add(Path);
  //WriteLn(':>TvVectorialDocument.AddPath 4');
end;

{@@
  Starts writing a Path in multiple steps.
  Should be followed by zero or more calls to AddPointToPath
  and by a call to EndPath to effectively add the data.

  @see    StartPath, AddPointToPath
}
procedure TvVectorialDocument.StartPath(AX, AY: Double);
begin
  FTmpPath.Len := 1;
  FTmpPath.Points[0].SegmentType := stMoveTo;
  FTmpPath.Points[0].X := AX;
  FTmpPath.Points[0].Y := AY;
end;

{@@
  Adds one more point to the end of a Path being
  writing in multiple steps.

  Does nothing if not called between StartPath and EndPath.

  Can be called multiple times to add multiple points.

  @see    StartPath, EndPath
}
procedure TvVectorialDocument.AddLineToPath(AX, AY: Double);
var
  L: Integer;
begin
  L := FTmpPath.Len;
  Inc(FTmpPath.Len);
  FTmpPath.Points[L].SegmentType := st2DLine;
  FTmpPath.Points[L].X := AX;
  FTmpPath.Points[L].Y := AY;
end;

procedure TvVectorialDocument.AddLineToPath(AX, AY, AZ: Double);
var
  L: Integer;
begin
  L := FTmPPath.Len;
  Inc(FTmPPath.Len);
  FTmPPath.Points[L].SegmentType := st3DLine;
  FTmPPath.Points[L].X := AX;
  FTmPPath.Points[L].Y := AY;
  FTmPPath.Points[L].Z := AZ;
end;

procedure TvVectorialDocument.AddBezierToPath(AX1, AY1, AX2, AY2, AX3,
  AY3: Double);
var
  L: Integer;
begin
  L := FTmPPath.Len;
  Inc(FTmPPath.Len);
  FTmPPath.Points[L].SegmentType := st2DBezier;
  FTmPPath.Points[L].X := AX3;
  FTmPPath.Points[L].Y := AY3;
  FTmPPath.Points[L].X2 := AX1;
  FTmPPath.Points[L].Y2 := AY1;
  FTmPPath.Points[L].X3 := AX2;
  FTmPPath.Points[L].Y3 := AY2;
end;

procedure TvVectorialDocument.AddBezierToPath(AX1, AY1, AZ1, AX2, AY2, AZ2,
  AX3, AY3, AZ3: Double);
var
  L: Integer;
begin
  L := FTmPPath.Len;
  Inc(FTmPPath.Len);
  FTmPPath.Points[L].SegmentType := st3DBezier;
  FTmPPath.Points[L].X := AX3;
  FTmPPath.Points[L].Y := AY3;
  FTmPPath.Points[L].Z := AZ3;
  FTmPPath.Points[L].X2 := AX1;
  FTmPPath.Points[L].Y2 := AY1;
  FTmPPath.Points[L].Z2 := AZ1;
  FTmPPath.Points[L].X3 := AX2;
  FTmPPath.Points[L].Y3 := AY2;
  FTmPPath.Points[L].Z3 := AZ2;
end;

{@@
  Finishes writing a Path, which was created in multiple
  steps using StartPath and AddPointToPath,
  to the document.

  Does nothing if there wasn't a previous correspondent call to
  StartPath.

  @see    StartPath, AddPointToPath
}
procedure TvVectorialDocument.EndPath();
begin
  if FTmPPath.Len = 0 then Exit;
  AddPath(FTmPPath);
  FTmPPath.Len := 0;
end;

procedure TvVectorialDocument.AddText(AX, AY, AZ: Double; FontName: string; FontSize: integer; AText: utf8string);
var
  lText: PText;
begin
  lText := GetMem(SizeOf(TvText));
  SetLength(lText.Value, Length(AText));
  Move(AText[1], lText.Value[1], Length(AText));
  lText.X:=AX;
  lText.Y:=AY;
  lText.Z:=AZ;
  //lText.FontName:=FontName;
  SetLength(lText.FontName, Length(FontName));
  Move(FontName[1], lText.FontName[1], Length(FontName));
  lText.FontSize:=FontSize;
  FTexts.Add(lText);
end;

procedure TvVectorialDocument.AddText(AX, AY, AZ: Double; AStr: utf8string);
begin
  AddText(AX, AY, AZ, 'Arial', 10, AStr);
end;

{@@
  Convenience method which creates the correct
  writer object for a given vector graphics document format.
}
function TvVectorialDocument.CreateVectorialWriter(AFormat: TvVectorialFormat): TvCustomVectorialWriter;
var
  i: Integer;
begin
  Result := nil;

  for i := 0 to Length(GvVectorialFormats) - 1 do
    if GvVectorialFormats[i].Format = AFormat then
    begin
      Result := GvVectorialFormats[i].WriterClass.Create;

      Break;
    end;

  if Result = nil then raise Exception.Create('Unsuported vector graphics format.');
end;

{@@
  Convenience method which creates the correct
  reader object for a given vector graphics document format.
}
function TvVectorialDocument.CreateVectorialReader(AFormat: TvVectorialFormat): TvCustomVectorialReader;
var
  i: Integer;
begin
  Result := nil;

  for i := 0 to Length(GvVectorialFormats) - 1 do
    if GvVectorialFormats[i].Format = AFormat then
    begin
      Result := GvVectorialFormats[i].ReaderClass.Create;

      Break;
    end;

  if Result = nil then raise Exception.Create('Unsuported vector graphics format.');
end;

{@@
  Writes the document to a file.

  If the file doesn't exist, it will be created.
}
procedure TvVectorialDocument.WriteToFile(AFileName: string; AFormat: TvVectorialFormat);
var
  AWriter: TvCustomVectorialWriter;
begin
  AWriter := CreateVectorialWriter(AFormat);

  try
    AWriter.WriteToFile(AFileName, Self);
  finally
    AWriter.Free;
  end;
end;

{@@
  Writes the document to a stream
}
procedure TvVectorialDocument.WriteToStream(AStream: TStream; AFormat: TvVectorialFormat);
var
  AWriter: TvCustomVectorialWriter;
begin
  AWriter := CreateVectorialWriter(AFormat);

  try
    AWriter.WriteToStream(AStream, Self);
  finally
    AWriter.Free;
  end;
end;

procedure TvVectorialDocument.WriteToStrings(AStrings: TStrings;
  AFormat: TvVectorialFormat);
var
  AWriter: TvCustomVectorialWriter;
begin
  AWriter := CreateVectorialWriter(AFormat);

  try
    AWriter.WriteToStrings(AStrings, Self);
  finally
    AWriter.Free;
  end;
end;

{@@
  Reads the document from a file.

  Any current contents will be removed.
}
procedure TvVectorialDocument.ReadFromFile(AFileName: string;
  AFormat: TvVectorialFormat);
var
  AReader: TvCustomVectorialReader;
begin
  Self.Clear;

  AReader := CreateVectorialReader(AFormat);
  try
    AReader.ReadFromFile(AFileName, Self);
  finally
    AReader.Free;
  end;
end;

{@@
  Reads the document from a stream.

  Any current contents will be removed.
}
procedure TvVectorialDocument.ReadFromStream(AStream: TStream;
  AFormat: TvVectorialFormat);
var
  AReader: TvCustomVectorialReader;
begin
  Self.Clear;

  AReader := CreateVectorialReader(AFormat);
  try
    AReader.ReadFromStream(AStream, Self);
  finally
    AReader.Free;
  end;
end;

procedure TvVectorialDocument.ReadFromStrings(AStrings: TStrings;
  AFormat: TvVectorialFormat);
var
  AReader: TvCustomVectorialReader;
begin
  Self.Clear;

  AReader := CreateVectorialReader(AFormat);
  try
    AReader.ReadFromStrings(AStrings, Self);
  finally
    AReader.Free;
  end;
end;

class function TvVectorialDocument.GetFormatFromExtension(AFileName: string
  ): TvVectorialFormat;
var
  lExt: string;
begin
  lExt := ExtractFileExt(AFileName);
  if AnsiCompareText(lExt, STR_PDF_EXTENSION) = 0 then Result := vfPDF
  else if AnsiCompareText(lExt, STR_POSTSCRIPT_EXTENSION) = 0 then Result := vfPostScript
  else if AnsiCompareText(lExt, STR_SVG_EXTENSION) = 0 then Result := vfSVG
  else if AnsiCompareText(lExt, STR_CORELDRAW_EXTENSION) = 0 then Result := vfCorelDrawCDR
  else if AnsiCompareText(lExt, STR_WINMETAFILE_EXTENSION) = 0 then Result := vfWindowsMetafileWMF
  else
    raise Exception.Create('TvVectorialDocument.GetFormatFromExtension: The extension (' + lExt + ') doesn''t match any supported formats.');
end;

function  TvVectorialDocument.GetDetailedFileFormat(): string;
begin

end;

function TvVectorialDocument.GetPath(ANum: Cardinal): TPath;
begin
  if ANum >= FPaths.Count then raise Exception.Create('TvVectorialDocument.GetPath: Path number out of bounds');

  if FPaths.Items[ANum] = nil then raise Exception.Create('TvVectorialDocument.GetPath: Invalid Path number');

  Result := PPath(FPaths.Items[ANum])^;
end;

function TvVectorialDocument.GetPathCount: Integer;
begin
  Result := FPaths.Count;
end;

function TvVectorialDocument.GetText(ANum: Cardinal): TvText;
begin
  if ANum >= FTexts.Count then raise Exception.Create('TvVectorialDocument.GetText: Text number out of bounds');

  if FTexts.Items[ANum] = nil then raise Exception.Create('TvVectorialDocument.GetText: Invalid Text number');

  Result := PText(FTexts.Items[ANum])^;
end;

function TvVectorialDocument.GetTextCount: Integer;
begin
  Result := FTexts.Count;
end;

{@@
  Clears all data in the document
}
procedure TvVectorialDocument.Clear;
begin
  RemoveAllPaths();
  RemoveAllTexts();
end;

{ TvCustomVectorialReader }

procedure TvCustomVectorialReader.ReadFromFile(AFileName: string; AData: TvVectorialDocument);
var
  FileStream: TFileStream;
begin
  FileStream := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyNone);
  try
    ReadFromStream(FileStream, AData);
  finally
    FileStream.Free;
  end;
end;

procedure TvCustomVectorialReader.ReadFromStream(AStream: TStream;
  AData: TvVectorialDocument);
var
  AStringStream: TStringStream;
  AStrings: TStringList;
begin
  AStringStream := TStringStream.Create('');
  AStrings := TStringList.Create;
  try
    AStringStream.CopyFrom(AStream, AStream.Size);
    AStringStream.Seek(0, soFromBeginning);
    AStrings.Text := AStringStream.DataString;
    ReadFromStrings(AStrings, AData);
  finally
    AStringStream.Free;
    AStrings.Free;
  end;
end;

procedure TvCustomVectorialReader.ReadFromStrings(AStrings: TStrings;
  AData: TvVectorialDocument);
var
  AStringStream: TStringStream;
begin
  AStringStream := TStringStream.Create('');
  try
    AStringStream.WriteString(AStrings.Text);
    AStringStream.Seek(0, soFromBeginning);
    ReadFromStream(AStringStream, AData);
  finally
    AStringStream.Free;
  end;
end;

{ TsCustomSpreadWriter }

{@@
  Default file writting method.

  Opens the file and calls WriteToStream

  @param  AFileName The output file name.
                   If the file already exists it will be replaced.
  @param  AData     The Workbook to be saved.

  @see    TsWorkbook
}
procedure TvCustomVectorialWriter.WriteToFile(AFileName: string; AData: TvVectorialDocument);
var
  OutputFile: TFileStream;
begin
  OutputFile := TFileStream.Create(AFileName, fmCreate or fmOpenWrite);
  try
    WriteToStream(OutputFile, AData);
  finally
    OutputFile.Free;
  end;
end;

{@@
  The default stream writer just uses WriteToStrings
}
procedure TvCustomVectorialWriter.WriteToStream(AStream: TStream;
  AData: TvVectorialDocument);
var
  lStringList: TStringList;
begin
  lStringList := TStringList.Create;
  try
    WriteToStrings(lStringList, AData);
    lStringList.SaveToStream(AStream);
  finally
    lStringList.Free;
  end;
end;

procedure TvCustomVectorialWriter.WriteToStrings(AStrings: TStrings;
  AData: TvVectorialDocument);
begin

end;

finalization

  SetLength(GvVectorialFormats, 0);

end.

