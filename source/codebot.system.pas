(********************************************************)
(*                                                      *)
(*  Codebot Pascal Library                              *)
(*  http://cross.codebot.org                            *)
(*  Modified March 2015                                 *)
(*                                                      *)
(********************************************************)

{ <include docs/codebot.system.txt> }
unit Codebot.System;

{$i codebot.inc}

interface

uses
  { Codebot core unit }
  Codebot.Core,
  { Free pascal units }
  SysUtils, Classes, FileUtil;

{$region types}
type
  Float = Single;
  PFloat = ^Float;
  LargeInt = Int64;
  PLargeInt = ^LargeInt;
  LargeWord = QWord;
  PLargeWord = ^LargeWord;
  HFile = Pointer;
{$endregion}

{$region dynamic library support}
type
  HModule = Codebot.Core.HModule;

const
  ModuleNil = Codebot.Core.ModuleNil;
  SharedSuffix = Codebot.Core.SharedSuffix;
  HiByte = High(Byte);

function LibraryLoad(const Name: string): HModule;
function LibraryUnload(Module: HModule): Boolean;
function LibraryGetProc(Module: HModule; const ProcName: string): Pointer;

type
  ELibraryException = class(Exception)
  private
    FModuleName: string;
    FProcName: string;
  public
    constructor Create(const ModuleName, ProcName: string);
    property ModuleName: string read FModuleName;
    property ProcName: string read FProcName;
  end;
{$endregion}

{$region system}
procedure FillZero(out Buffer; Size: UIntPtr); inline;
{$endregion}

{$region events}
type
  { Arguments for an empty event [group event] }
  TEmptyArgs = record end;
  { TEventHandler\<T\> is a generic event prototype [group event] }
  TEventHandler<T> = procedure(Sender: TObject; var Args: T) of object;
  { TEmptyEvent is for events which take no arguments [group event] }
  TEmptyEvent = TEventHandler<TEmptyArgs>;

  { Arguments for an event which handles text [group event] }
  TTextEventArgs = record
    Text: string;
  end;
  { TTextEvent is for events which handle text [group event] }
  TTextEvent = TEventHandler<TTextEventArgs>;

  { Arguments for a transfer operations such as uploading, or downloading file [group event] }
  TTransferArgs = record
    { Number of bytes expected to be transfered in total }
    Size: LargeWord;
    { Number of bytes transfered so far }
    Sent: LargeWord;
  end;
  { TTransferEvent is for transfer operations such as uploading, or downloading file [group event] }
  TTransferEvent = TEventHandler<TTransferArgs>;

var
  { EmptyArgs provides a blank argument for <link Codebot.System.TEmptyEvent, TEmptyEvent> type events [group event] }
  EmptyArgs: TEmptyArgs;
{$endregion}

{$region generic containers}
{ TArray<T> is a shortvut to a dtyped dynamic array }

type
  TArray<T> = array of T;

{ TCompare\<T\> is used to compare two items }
  TCompare<T> = function(constref A, B: T): Integer;
{ TConvert\<Source, Target\> is used to convert from one type to another }
  TConvert<TItem, T> = function(constref Item: TItem): T;
{ TConvertString\<T\> is used to convert a type to a string }
  TConvertString<TItem> = function(constref Item: TItem): string;

{ ICloneable\<T\> represents an object which can clone T
  See also
  <link Overview.Codebot.System.ICloneable, ICloneable members> }

  ICloneable<T> = interface
  ['{2AF4D64F-3CA2-4777-AAAC-0CDC42B8C34A}']
    { Create a clone of T }
    function Clone: T;
  end;

{doc off}
  TArrayEnumerator<T> = class(TInterfacedObject, IEnumerator<T>)
  private
    FItems: TArray<T>;
    FPosition: Integer;
    FCount: Integer;
  public
    constructor Create(Items: TArray<T>; Count: Integer = -1);
    { IEnumerator<T> }
    function GetCurrent: T;
    function MoveNext: Boolean;
    procedure Reset;
  end;
{doc on}

{ TArrayList\<T\> is a simple extension to dynamic arrays
  See also
  <link Overview.Codebot.System.TArrayList, TArrayList\<T\> members> }

  TArrayList<T> = record
  public
    {doc ignore}
    type TArrayListEnumerator = class(TArrayEnumerator<T>) end;
    { Get the enumerator for the list }
    function GetEnumerator: IEnumerator<T>;
  private
    procedure QuickSort(Compare: TCompare<T>; L, R: Integer);
    function GetIsEmpty: Boolean;
    function GetFirst: T;
    procedure SetFirst(const Value: T);
    function GetLast: T;
    procedure SetLast(const Value: T);
    function GetLength: Integer;
    procedure SetLength(Value: Integer);
    function GetData: Pointer;
     function GetItem(Index: Integer): T;
    procedure SetItem(Index: Integer; const Value: T);
  public
    class var DefaultCompare: TCompare<T>;
    class var DefaultConvertString: TConvertString<T>;
    { The array acting as a list }
    var Items: TArray<T>;
    class function Convert: TArrayList<T>; static;
    { Convert a list to an array }
    class operator Implicit(const Value: TArrayList<T>): TArray<T>;
    { Convert an array to a list }
    class operator Implicit(const Value: TArray<T>): TArrayList<T>;
    { Convert an open array to a list }
    class operator Implicit(const Value: array of T): TArrayList<T>;
    { Returns the lower bounds of the list }
    function Lo: Integer;
    { Returns the upper bounds of the list }
    function Hi: Integer;
    { Reverses theitems in the list }
    procedure Reverse;
    { Swap two items in the list }
    procedure Exchange(A, B: Integer);
    { Adds and item to the end of the list }
    procedure Push(const Item: T);
    { Appends an array of items to the list }
    procedure PushRange(const Collection: array of T);
    { Remove an item from the end of the list }
    function Pop: T;
    { Remove an item from the end of the list }
    function PopRandom: T;
    { Removes an item by index from the list and decresaes the count by one }
    procedure Delete(Index: Integer);
    { Removes all items setting the count of the list to 0 }
    procedure Clear;
    { Sort the items using a comparer }
    procedure Sort(Comparer: TCompare<T> = nil);
    { Attempt to find the item using DefaultCompare }
    function IndexOf(const Item: T): Integer;
    { Join a the array into a string using a separator }
    function Join(const Separator: string; Convert: TConvertString<T> = nil): string;
    { Returns true if ther are no items in the list }
    property IsEmpty: Boolean read GetIsEmpty;
    { First item in the list }
    property First: T read GetFirst write SetFirst;
    { Last item in the list }
    property Last: T read GetLast write SetLast;
    { Number of items in the list }
    property Length: Integer read GetLength write SetLength;
    { Address where to the first item is located }
    property Data: Pointer read GetData;
    { Get or set an item }
    property Item[Index: Integer]: T read GetItem write SetItem; default;
  end;

{doc off}
  StringArray = TArrayList<string>;
  IntArray = TArrayList<Integer>;
  Int64Array = TArrayList<Int64>;
  FloatArray = TArrayList<Float>;
  BoolArray = TArrayList<Boolean>;

function DefaultStringCompare(constref A, B: string): Integer;
function DefaultStringConvertString(constref Item: string): string;
function DefaultIntCompare(constref A, B: Integer): Integer;
function DefaultIntConvertString(constref Item: Integer): string;
function DefaultInt64Compare(constref A, B: Int64): Integer;
function DefaultInt64ConvertString(constref Item: Int64): string;
function DefaultFloatCompare(constref A, B: Float): Integer;
function DefaultFloatConvertString(constref Item: Float): string;
{doc on}

{$endregion}

{$region math routines}
{ Return the even division of a quotient }
function Divide(const Quotient, Divisor: Float): Float;
{ Return the remainder of an even division }
function Remainder(const Quotient, Divisor: Float): Float;
{ Bind a value between 0 and 1 }
function Clamp(Percent: Float): Float;
{ Convert degrees to radians }
function DegToRad(D: Float): Float;
{ Convert radians to degrees }
function RadToDeg(R: Float): Float;
{$endregion}

{$region time routines}
{ Access to highly accurate time }
function TimeQuery: Double;

{ IStopwatch represents a highly accurate way to measure time
  See also
  <link Overview.Codebot.System.IStopwatch, IStopwatch members>
  <link Codebot.System.StopwatchCreate, StopwatchCreate function> }

type
  IStopwatch = interface(IInterface)
  ['{8E3ACC66-EE90-4289-B8C9-DF1F26E016A9}']
    {doc off}
    function GetTime: Double;
    function GetPaused: Boolean;
    procedure SetPaused(Value: Boolean);
    {doc on}
    { Update the time by querying for an accurate time }
    function Calculate: Double;
    { Reset the timer to zero }
    procedure Reset;
    { Time expired between the last calculate and reset }
    property Time: Double read GetTime;
    { Pauses time calculation }
    property Paused: Boolean read GetPaused write SetPaused;
  end;

{ Create a highly accurate stopwatch
  See also
  <link Codebot.System.IStopwatch, IStopwatch interface> }
function StopwatchCreate: IStopwatch;
{$endregion}

{$region string routines}
{ These string routines support UTF8 text (needs testing) }

const
  { End of line characters used by various operating systems [group string] }
  LineBreakStyles: array[TTextLineBreakStyle] of string = (#10, #13#10, #13);
  { The character used to begin command line switches [group string] }
  SwitchChar = '-';

{ Convert a string to uppercase [group string] }
function StrUpper(const S: string): string;
{ Convert a string to lowercase [group string] }
function StrLower(const S: string): string;
{ Copies a substring given a start and length [group string] }
function StrCopy(const S: string; Start: Integer; Len: Integer = 0): string;
{ Copy a memory buffer into a string [group string] }
function StrCopyData(P: Pointer; Len: Integer): string;
{ Inserts a substring into a string at a position [group string] }
function StrInsert(const S, SubStr: string; Position: Integer): string;
{ Compares two strings optionally ignoring case returning -1 if A comes before
  before B, 1 if A comes after b, ord 0 if A and B are equal [group string] }
function StrCompare(const A, B: string; IgnoreCase: Boolean = False): Integer;
{ Searches a string for a substring optionally ignoring case [group string] }
function StrFind(const S, SubStr: string; IgnoreCase: Boolean = False): Integer; overload;
{ Searches a string for a substring from a start position optionally ignoring case [group string] }
function StrFind(const S, SubStr: string; Start: Integer; IgnoreCase: Boolean = False): Integer; overload;
{ Returns the number of a substring matches within a string [group string] }
function StrFindCount(const S, SubStr: string; IgnoreCase: Boolean = False): Integer;
{ Returns an array of indices of a substring matches within a string [group string] }
function StrFindIndex(const S, SubStr: string; IgnoreCase: Boolean = False): IntArray;
{ Replaces every instance of a pattern in a string [group string] }
function StrReplace(const S, OldPattern, NewPattern: string; IgnoreCase: Boolean = False): string;
{ Replaces the first instance of a pattern in a string [group string] }
function StrReplaceOne(const S, OldPattern, NewPattern: string; IgnoreCase: Boolean = False): string;
{ Replaces everything aftger the first instance of a pattern in a string [group string] }
function StrReplaceAfter(const S, OldPattern, NewPattern: string; IgnoreCase: Boolean = False): string;
{ Trims white space from both sides of a string [group string] }
function StrTrim(const S: string): string;
{ Returns true if a case insensitive string matches a value [group string] }
function StrEquals(const S: string; Value: string): Boolean; overload;
{ Returns true if a case insensitive string matches a set of value [group string] }
function StrEquals(const S: string; const Values: array of string): Boolean; overload;
{ Returns the index of a string in a string array or -1 if there is no match [group string] }
function StrIndex(const S: string; const Values: array of string): Integer;
{ Splits a string into a string array using a separator [group string] }
function StrSplit(const S, Separator: string): StringArray;
{ Splits a string into a int array using a separator [group string] }
function StrSplitInt(const S, Separator: string): IntArray;
{ Splits a string into a int64 array using a separator [group string] }
function StrSplitInt64(const S, Separator: string): Int64Array;
{ Join a string array into a string using a separator [group string] }
function StrJoin(const A: StringArray; const Separator: string): string;
{ Join an int array into a string using a separator [group string] }
function StrJoinInt(const A: IntArray; const Separator: string): string;
{ Returns the first subsection of a string if it were split using a separator [group string] }
function StrFirstOf(const S, Separator: string): string;
{ Returns the second subsection of a string if it were split using a separator [group string] }
function StrSecondOf(const S, Separator: string): string;
{ Returns the last subsection of a string if it were split using a separator [group string] }
function StrLastOf(const S, Separator: string): string;
{ Search a string for a substring optionally ignoring case [group string] }
function StrContains(const S, SubStr: string; IgnoreCase: Boolean = False): Boolean;
{ Returns true if a string begins with a substring while optionally ignoring case [group string] }
function StrBeginsWith(const S, SubStr: string; IgnoreCase: Boolean = False): Boolean;
{ Returns true if a string end with a substring while optionally ignoring case [group string] }
function StrEndsWith(const S, SubStr: string; IgnoreCase: Boolean = False): Boolean;
{ Returns a string of a given length filled with one repeating character [group string] }
function StrOf(C: Char; Len: Integer): string;
{ Returns a string made to fit a given length padded on the left with a character [group string] }
function StrPadLeft(const S: string; C: Char; Len: Integer): string;
{ Returns a string made to fit a given length padded on the right with a character [group string] }
function StrPadRight(const S: string; C: Char; Len: Integer): string;
{ Returns a string surrounded by quotes if it contains whitespace [group string] }
function StrQuote(const S: string): string;
{ Returns true if a string contains only whitespace characters [group string] }
function StrIsBlank(const S: string): Boolean;
{ Returns true if a string matches to rules of an identifier [group string] }
function StrIsIdent(const S: string): Boolean;
{ Returns true if a string matches to rules of an attribute [group string] }
function StrIsAttr(const S: string): Boolean;
{ Returns the line break style for a block of text [group string] }
function StrLineBreakStyle(const S: string): TTextLineBreakStyle;
{ Converts the line break style of a block of text using the desired style [group string] }
function StrAdjustLineBreaks(const S: string; Style: TTextLineBreakStyle): string; overload;
{ Converts the line break style of a block of text using the system defined style [group string] }
function StrAdjustLineBreaks(const S: string): string; overload;
{ Convert a string to a wide string }
function StrToWide(const S: string): WideString;
{ Convert a wide string to string }
function WideToStr(const S: WideString): string;

{ Returns true if a program has a matching switch
  See also
  <link Codebot.System.SwitchIndex, SwitchIndex function>
  <link Codebot.System.SwitchValue, SwitchValue function> [group string] }
function SwitchExists(const Switch: string): Boolean;
{ Returns the index if of a program's matching switch or -1 if no match was found
  See also
  <link Codebot.System.SwitchExists, SwitchExists function>
  <link Codebot.System.SwitchValue, SwitchValue function> [group string] }
function SwitchIndex(const Switch: string): Integer;
{ Returns the value if of a program's switch
  See also
  <link Codebot.System.SwitchExists, SwitchExists function>
  <link Codebot.System.SwitchIndex, SwitchIndex function> [group string] }
function SwitchValue(const Switch: string): string;
{ Convert an integer to a string [group string] }
function IntToStr(Value: Integer): string;
{ Convert a string to an integer. Can throw an EConvertError exception. [group string] }
function StrToInt(const S: string): Integer;
{ Convert a string an integer. Returns a default value if conversion cannot be done. [group string] }
function StrToIntDef(const S: string; Default: Integer): Integer;
{ Convert a float to a string [group string] }
function FloatToStr(Value: Extended): string; overload;
{ Convert a float to a string with a given number of decimals [group string] }
function FloatToStr(Value: Extended; Decimals: Integer): string; overload;
{ Convert a float to a comma string with a given number of decimals [group string] }
function FloatToCommas(Value: Extended; Decimals: Integer = 0): string;
{ Convert a string to a float. Can throw an EConvertError exception. [group string] }
function StrToFloat(const S: string): Extended;
{ Convert a string a float. Returns a default value if conversion cannot be done. [group string] }
function StrToFloatDef(const S: string; Default: Extended): Extended;
{ Search for and return a named environment variable }
function StrEnvironmentVariable(const Name: string): string;
{ Formats a series of argument into a string [group string] }
function StrFormat(const S: string; Args: array of const): string;
{ Retrieve the compoent heirarchy [group string] }
function StrCompPath(Component: TComponent): string;
{$endregion}

{$region helpers}
{ StringHelper }

type
  StringHelper = record helper for string
  private
    function GetIsEmpty: Boolean;
    function GetIsWhitespace: Boolean;
    function GetIsIdentifier: Boolean;
    function GetIsAttribute: Boolean;
    function GetLength: Integer;
    procedure SetLength(Value: Integer);
  public
    { Convert to a string representation }
    function ToString: string;
    { Make a string unique, reducing its reference count to one }
    procedure Unique;
    { Repeat a character a given length a into string }
    procedure CharInto(C: Char; Len: Integer);
    { Copy a memory buffer into string }
    procedure CopyInto(P: Pointer; Len: Integer);
    { Inserts a substring at a position into string }
    procedure InsertInto(const SubStr: string; Position: Integer);
    { Returns true if a string matches a case insensitive value }
    function Equals(const Value: string; IgnoreCase: Boolean = False): Boolean; overload;
    { Returns true if a string matches any in a set of case insensitive values }
    function Equals(const Values: array of string; IgnoreCase: Boolean = False): Boolean; overload;
    { Compares two strings optionally ignoring case returning -1 if string comes before
      before value, 1 if string comes after value, ord 0 if string and value are equal }
    function Compare(const Value: string; IgnoreCase: Boolean = False): Integer;
    { Convert a string to uppercase }
    function ToUpper: string;
    { Convert a string to lowercase }
    function ToLower: string;
    { Copies a substring given a start and length }
    function Copy(Start: Integer; Len: Integer = 0): string;
    { Insert a substring given a start and length }
    function Insert(const SubStr: string; Position: Integer): string;
    { Searches a string for a substring optionally ignoring case }
    function IndexOf(const SubStr: string; IgnoreCase: Boolean = False): Integer; overload;
    { Searches a string for a substring from a start position optionally ignoring case }
    function IndexOf(const SubStr: string; Start: Integer; IgnoreCase: Boolean = False): Integer; overload;
    { Returns the number of a substring matches within a string }
    function MatchCount(const SubStr: string; IgnoreCase: Boolean = False): Integer;
    { Returns an array of indices of a substring matches within a string }
    function Matches(const SubStr: string; IgnoreCase: Boolean = False): IntArray;
    { Replaces every instance of a pattern in a string }
    function Replace(const OldPattern, NewPattern: string; IgnoreCase: Boolean = False): string;
    { Replaces the first instance of a pattern in a string }
    function ReplaceOne(const OldPattern, NewPattern: string; IgnoreCase: Boolean = False): string;
    { Replaces everything aftger the first instance of a pattern in a string }
    function ReplaceAfter(const OldPattern, NewPattern: string; IgnoreCase: Boolean = False): string;
    { Trims white space from both sides of a string }
    function Trim: string;
    { Returns the index of a string in a string array or -1 if there is no match }
    function ArrayIndex(const Values: array of string): Integer;
    { Splits a string into a string array using a separator }
    function Split(Separator: string): StringArray;
    { Splits a string into a int array using a separator }
    function SplitInt(const Separator: string): IntArray;
    { Splits a string into a int64 array using a separator }
    function SplitInt64(const Separator: string): Int64Array;
    { Splits a string into word separated by whitespace }
    function Words(MaxColumns: Integer = 0): StringArray;
    { Returns the first subsection of a string if it were split using a separator }
    function FirstOf(const Separator: string): string;
    { Returns the second subsection of a string if it were split using a separator }
    function SecondOf(const Separator: string): string;
    { Returns the last subsection of a string if it were split using a separator }
    function LastOf(const Separator: string): string;
    { Returns the text exclusive between markers A and B }
    function Between(const MarkerA, MarkerB: string): string;
    { Search a string for a substring optionally ignoring case }
    function Contains(const SubStr: string; IgnoreCase: Boolean = False): Boolean;
    { Returns true if a string begins with a substring while optionally ignoring case }
    function BeginsWith(const SubStr: string; IgnoreCase: Boolean = False): Boolean;
    { Returns true if a string end with a substring while optionally ignoring case }
    function EndsWith(const SubStr: string; IgnoreCase: Boolean = False): Boolean;
    { Returns a string made to fit a given length padded on the left with a character }
    function PadLeft(C: Char; Len: Integer): string;
    { Returns a string made to fit a given length padded on the right with a character }
    function PadRight(C: Char; Len: Integer): string;
    { Returns a string surrounded by quotes if it contains whitespace }
    function Quote: string;
    { Formats a series of argument into a string }
    function Format(Args: array of const): string;
    { Analyze a string and find its line break style }
    function LineBreakStyle: TTextLineBreakStyle;
    { Converts the line break style of a string to a the desired style }
    function AdjustLineBreaks(Style: TTextLineBreakStyle): string; overload;
    { Converts the line break style of a string to the system preferred defined style }
    function AdjustLineBreaks: string; overload;
    { Gets true if a string contains only whitespace characters }
    property IsEmpty: Boolean read GetIsEmpty;
    { Gets true if a string contains only whitespace characters }
    property IsWhitespace: Boolean read GetIsWhitespace;
    { Gets true if a string matches to rules of an identifier }
    property IsIdentifier: Boolean read GetIsIdentifier;
    { Gets true if a string matches to rules of an attribute }
    property IsAttribute: Boolean read GetIsAttribute;
    {  Gets or sets the length allocated for the string }
    property Length: Integer read GetLength write SetLength;
  end;

{ IntHelper }

  IntHelper = record helper for Integer
  public
    { Convert to a string representation }
    function ToString: string;
    { Check if a number is inclusively between a range}
    function Between(Low, High: Integer): Boolean;
  end;

{ TDateTimeHelper }

  TDateTimeHelper = record helper for TDateTime
  public
    { Convert to a string representation }
    function ToString(Format: string = ''): string;
    { Convert to a string representation }
    function AddMinutes(const A: Integer): TDateTime;
    { Return the year portion of the date }
    function Year: Word;
    { Return the month portion of the date }
    function Month: Word;
    { Return the day  portion of the date }
    function Day: Word;
  end;

{ TStringsHelper }

  TStringsHelper = class helper for TStrings
  public
    procedure AddLine;
    procedure AddFormat(const S: string; const Args: array of const);
    function Contains(const S: string; IgnoreCase: Boolean = False): Boolean;
  end;
{$endregion}

{$region file management routines}
{ These file management routines support UTF8 file operations (needs testing) }

{ Delete a file }
function FileDelete(const FileName: string): Boolean;
{ Copy a file optionally preserving file time }
function FileCopy(const SourceName, DestName: string; PreserveTime: Boolean = False): Boolean;
{ Rename a file }
function FileRename(const OldName, NewName: String): Boolean;
{ Determine if a file exists }
function FileExists(const FileName: string): Boolean;
{ Get the size of a file in bytes }
function FileSize(const FileName: string): LargeWord;
{ Get the modified date of a file in bytes }
function FileDate(const FileName: string): TDateTime;
{ Extract the name portion of a file name [group files] }
function FileExtractName(const FileName: string): string;
{ Extract the extension portion of a file name [group files] }
function FileExtractExt(const FileName: string): string;
{ Change the extension portion of a file name [group files] }
function FileChangeExt(const FileName, Extension: string): string;
{ Extract the path of a file or directory }
function FileExtractPath(const FileName: string): string;
{ Write the contents of a file }
procedure FileWriteStr(const FileName: string; const Contents: string);
{ Read the contents of a file }
function FileReadStr(const FileName: string): string;
{ Write a line to a file }
procedure FileWriteLine(const FileName: string; const Line: string);
{ Create a directory }
function DirCreate(const Dir: string): Boolean;
{ Get the current working directory }
function DirGetCurrent: string;
{ Set the current working directory }
function DirSetCurrent(const Dir: string): Boolean;
{ Get the temporary directory }
function DirGetTemp(Global: Boolean = False): string;
{ Delete a directory or optionaly only its contents }
function DirDelete(const Dir: string; OnlyContents: Boolean = False): Boolean;
{ Determine if a directory exists }
function DirExists(const Dir: string): Boolean;
{ Force a directory to exist }
function DirForce(const Dir: string): Boolean;
{ Change path delimiter to match system settings [group files] }
function PathAdjustDelimiters(const Path: string): string;
{ Combine two paths }
function PathCombine(const A, B: string): string;
{ Expand a path to the absolute path }
function PathExpand(const Path: string): string;
{ Include the end delimiter for a path }
function PathIncludeDelimiter(const Path: string): string;
{ Exclude the end delimiter for a path }
function PathExcludeDelimiter(const Path: string): string;
{ Returns the location of the application configuration file }
function ConfigAppFile(Global: Boolean; CreateDir: Boolean = False): string;
{ Returns the location of the application configuration directory }
function ConfigAppDir(Global: Boolean; CreateDir: Boolean = False): string;
{ FindOpen corrects path delimiters and convert search to an output parameter }
function FindOpen(const Path: string; Attr: Longint; out Search: TSearchRec): LongInt;
{ Find files in a path returning a strings object }
function FindFiles(const Path: string): TStrings;
{ Find files from ParamStr at start index returning a strings object }
function FindFileParams(StartIndex: Integer): TStrings;
{$endregion}

{ TNamedValues\<T\> is a simple case insensitive string based dictionary
  See also
  <link Overview.Codebot.System.TNamedValues, TNamedValues\<T\> members> }

type
  TNamedValues<T> = record
  public
    { Get the enumerator for the dictionary names }
    function GetEnumerator: IEnumerator<string>;
  private
    FNames: TArrayList<string>;
    FValues: TArrayList<T>;
    function GetCount: Integer;
    function GetEmpty: Boolean;
    function GetName(Index: Integer): string;
    function GetValue(const Name: string): T;
  public
    { Adds or replace a named value in the dictionary }
    procedure Add(const Name: string; const Value: T);
    { Removed a named value from the dictionary }
    procedure Remove(const Name: string);
    { Removes an item by index from the dictionary and decresaes the count by one }
    procedure Delete(Index: Integer);
    { Removes all named values setting the count of the dictionary to 0 }
    procedure Clear;
    { The number of key value pairs in the dictionary }
    property Count: Integer read GetCount;
    { Returns true if ther are no named values in the dictionary }
    property Empty: Boolean read GetEmpty;
    { Names indexed by an integer }
    property Names[Index: Integer]: string read GetName;
    { Values indexed by a name }
    property Values[Name: string]: T read GetValue; default;
  end;

{ TNamedStrings is a dictionary of string name value pairs }

  TNamedStrings = TNamedValues<string>;

{ IDelegate\<T\> allows event subscribers to add or remove their event handlers
  See also
  <link Overview.Codebot.System.IDelegate, IDelegate\<T\> members> }

  IDelegate<T> = interface
  ['{ADBC29C1-4F3D-4E4C-9A79-C805E8B9BD92}']
    { Check if there are no subscribers }
    function GetIsEmpty: Boolean;
    { A subscriber calls add to register an event handler }
    procedure Add(const Handler: T);
    { A subscriber calls remove to unregister an event handler }
    procedure Remove(const Handler: T);
    { Empty is true when there are no subscribers }
    property IsEmpty: Boolean read GetIsEmpty;
  end;

{doc off}
  IDelegateContainer<T> = interface
  ['{ED255F00-3112-4315-9E25-3C1B3064C932}']
    function GetEnumerator: IEnumerator<T>;
    function GetDelegate: IDelegate<T> ;
    property Delegate: IDelegate<T> read GetDelegate;
  end;

  TDelegateImpl<T> = class(TInterfacedObject, IDelegate<T>)
  private
    FList: TArrayList<T>;
    function IndexOf(Event: T): Integer;
  protected
    function GetIsEmpty: Boolean;
    procedure Add(const Event: T);
    procedure Remove(const Event: T);
  end;

  TDelegateContainerImpl<T> = class(TInterfacedObject, IDelegateContainer<T>)
  private
    type TDelegateClass = TDelegateImpl<T>;
    var FDelegateClass: TDelegateClass;
    var FDelegate: IDelegate<T>;
  protected
    { IDelegateContainer<T> }
    function GetEnumerator: IEnumerator<T>;
    function GetDelegate: IDelegate<T>;
  end;
{doc on}

{ TDelegate\<T\> allows an event publisher accept multiple subscribers
  See also
  <link Overview.Codebot.System.TDelegate, TDelegate\<T\> members> }

  TDelegate<T> = record
  private
    type TDelegateContainer = TDelegateContainerImpl<T>;
    var FContainer: IDelegateContainer<T>;
    function GetContainer: IDelegateContainer<T>;
  public
    { Convert a delegate into an interface suitable for subscribers }
    class operator Implicit(var Delegate: TDelegate<T>): IDelegate<T>;
    { Get the enumerator of subscriber's events }
    function GetEnumerator: IEnumerator<T>;
    { Check is there are no subscribers }
    function GetIsEmpty: Boolean;
    { Add an event handler }
    procedure Add(const Handler: T);
    { Remove an event handler }
    procedure Remove(const Handler: T);
    { Returns true is there a no subscribers }
    property IsEmpty: Boolean read GetIsEmpty;
  end;

  { Notify event publisher }
  TNotifyDelegate = TDelegate<TNotifyEvent>;
  { Notify event subscriber }
  INotifyDelegate = IDelegate<TNotifyEvent>;
  { Vanilla method }
  TMethodEvent = procedure of object;
  { Method event publisher }
  TMethodDelegate = TDelegate<TMethodEvent>;
  { Method event subscriber }
  IMethodDelegate = IDelegate<TMethodEvent>;

{ TChangeNotifier allows components to be notified of changes to owned classes
  See also
  <link Overview.Codebot.System.TChangeNotifier, TChangeNotifier members> }

  TChangeNotifier = class(TPersistent)
  private
    FOnChange: TNotifyDelegate;
    function GetOnChange: INotifyDelegate;
  protected
    { Notify component subscribers of changes }
    procedure Change; virtual;
  public
    { Allow component subscribers to add or remove change notification }
    property OnChange: INotifyDelegate read GetOnChange;
  end;

{ Compare two block of memory returning true if they are the same }
function MemCompare(const A, B; Size: LongWord): Boolean;
{$endregion}

{$region classes}
{ TNullResult holds bytes written each second to a null stream
  See also
  <link Codebot.System.TNullStream, TNullStream class> }

type
  TNullResult = TArrayList<LongWord>;

{ TNullInfo holds information related to bytes read or written
  See also
  <link Overview.Codebot.System.TNullInfo, TNullInfo members>
  <link Codebot.System.TNullStream, TNullStream class> }

  TNullInfo = class(TObject)
  private
    FTime: Double;
    FCount: LongWord;
    FBytes: LongWord;
    FRate: LongWord;
    FRateBytes: LongWord;
    FRateTime: Double;
    FAvergage: LongWord;
    FAvergageTotal: LongWord;
    FAvergageCount: LongWord;
    FSeconds: LongWord;
    FResult: TNullResult;
  public
    { Resets the counting and return a recording of bytes transfered per second }
    function Reset: TNullResult;
    { Thread safe total bytes transfered  }
    property Bytes: LongWord read FBytes;
    { Thread safe realtime estimate of bytes transfered this second }
    property Rate: LongWord read FRate;
    { Thread safe realtime average bytes transfered in total }
    property Avergage: LongWord read FAvergage;
    { Thread safe number of seconds since the last reset }
    property Seconds: LongWord read FSeconds;
  end;

{ TNullStream does nothing other than records bytes read or written per second
  See also
  <link Overview.Codebot.System.TNullStream, TNullStream members> }

  TNullStream = class(TStream)
  private
    FReadInfo: TNullInfo;
    FWriteInfo: TNullInfo;
    procedure RecordInfo(Info: TNullInfo; Count: LongWord);
  protected
    {doc off}
    procedure SetSize(NewSize: Longint); override;
    procedure SetSize(const NewSize: Int64); override;
    {doc on}
  public
    { Create a new null stream }
    constructor Create;
    destructor Destroy; override;
    { Ignores buffer and records count read bytes
      Remarks
      If two seconds or more have passed since the last read the null stream
      will automatically read reset }
    function Read(var Buffer; Count: Longint): Longint; override;
    { Ignores buffer and records count written bytes
      Remarks
      If two seconds or more have passed since the last write the null stream
      will automatically write reset }
    function Write(const Buffer; Count: Longint): Longint; override;
    { Does nothing and returns zero }
    function Seek(const Offset: Int64; Origin: TSeekOrigin): Int64; override;
    { A log of read information }
    property ReadInfo: TNullInfo read FReadInfo;
    { A log of write information }
    property WriteInfo: TNullInfo read FWriteInfo;
  end;
{$endregion}


{$region threading}
{ IMutex allows threads to wait for an exclusive locked ownership of a mutex ibject
  Note
  On unix systems cthreads must be the first unit in your program source if you want thread support
  See also
  <link Overview.Codebot.System.IMutex, IMutex members> }

  IMutex = interface
    { Lock causes the current thread to wait for exclusive ownership of a mutex object }
    function Lock: LongInt;
    { Unlock releases exclusive access to a mutex object, allowing the next waiting thread to take ownership }
    function Unlock: LongInt;
  end;

{ IEvent allows many threads to wait until an event object signals them to continue
  Note
  On unix systems cthreads must be the first unit in your program source if you want thread support
  See also
  <link Overview.Codebot.System.IEvent, IEvent members> }

  IEvent = interface
    { Reset reverts an event object to a non signaled state }
    procedure Reset;
    { Signals threads waiting for the event object to continue }
    procedure Signal;
    { Wait causes the current thread to suspsend execution until the event object is signaled }
    procedure Wait;
  end;

{ Create a new mutex object }
function MutexCreate: IMutex;
{ Create a new event object }
function EventCreate: IEvent;
{$endregion}

{$region waiting routines}
{ Definable message pump }
var
  PumpMessagesProc: procedure;

{ Retrieve messages from a queue while waiting }
procedure PumpMessages;
{$endregion}

implementation

{$region dynamic library support}

function LibraryLoad(const Name: string): HModule;
begin
  Result := Codebot.Core.LibraryLoad(Name);
end;

function LibraryUnload(Module: HModule): Boolean;
begin
  Result := Codebot.Core.LibraryUnload(Module);
end;

function LibraryGetProc(Module: HModule; const ProcName: string): Pointer;
begin
  Result := Codebot.Core.LibraryGetProc(Module, ProcName);
end;

{ ELibraryException }

constructor ELibraryException.Create(const ModuleName, ProcName: string);
const
  SLibraryModuleError = 'The dynamic library "%s" could not be located';
  SLibraryProcError = 'The function "%s" in dynamic library "%s" could not be loaded';
var
  S: string;
begin
  FModuleName := ModuleName;
  FProcName := ProcName;
  if FProcName <> '' then
    S := Format(SLibraryProcError, [FModuleName, FProcName])
  else
    S := Format(SLibraryModuleError, [FModuleName]);
  inherited Create(S);
end;

procedure LibraryExcept(const ModuleName: string; ProcName: string);
begin
  raise ELibraryException.Create(ModuleName, ProcName);
end;
{$endregion}

{$region system}
{$hints off}
procedure FillZero(out Buffer; Size: UIntPtr);
begin
  FillChar(Buffer, Size, 0);
end;
{$hints on}
{$endregion}

{$region math routines}
function Divide(const Quotient, Divisor: Float): Float;
begin
  if Divisor = 0 then
    Result := 0
  else
    Result := Round(Quotient / Divisor) * Divisor;
end;

function Remainder(const Quotient, Divisor: Float): Float;
begin
  if Divisor = 0 then
    Result := 0
  else
    Result := Quotient - (Trunc(Quotient) div Trunc(Divisor)) * Divisor;
end;

function Clamp(Percent: Float): Float;
begin
  if Percent < 0 then
    Result := 0
  else if Percent > 1 then
    Result := 1
  else
    Result := Percent;
end;

function DegToRad(D: Float): Float;
begin
  Result := D / 180 * Pi;
end;

function RadToDeg(R: Float): Float;
begin
  Result := R * 180 / Pi;
end;
{$endregion}

{$region time routines}
{$ifdef unix}
type
  TTimeVal = record
    Sec: LongWord;  { Seconds }
    MSec: LongWord; { Microseconds }
  end;
  PTimeVal = ^TTimeVal;

const
{$ifdef linux}
  libc = 'libc.so.6';
{$endif}
{$ifdef darwin}
  libc = 'libSystem.dylib';
{$endif}

function gettimeofday(out TimeVal: TTimeVal; TimeZone: PTimeVal): Integer; apicall; external libc;

function TimeQuery: Double;
var
  TimeVal: TTimeVal;
begin
  if gettimeofday(TimeVal, nil) = 0 then
    Result := TimeVal.Sec + TimeVal.MSec / 1000000
  else
    Result := 0;
end;
{$endif}

{$ifdef windows}
const
  kernel32  = 'kernel32.dll';

function QueryPerformanceCounter(var Counter: Int64): LongBool; apicall; external kernel32;
function QueryPerformanceFrequency(var Frequency: Int64): LongBool; apicall; external kernel32;

function TimeQuery: Double;
var
  C, F: Int64;
begin
  F := 0;
  C := 0;
  if QueryPerformanceFrequency(F) and QueryPerformanceCounter(C) then
    Result := C / F
  else
    Result := 0;
end;
{$endif}

{ TStopwatchImpl }

type
  TStopwatchImpl = class(TInterfacedObject, IStopwatch)
  private
    FPaused: Boolean;
    FTime: Double;
    FStart: Double;
    FStop: Double;
  public
    constructor Create;
    function GetTime: Double;
    function GetPaused: Boolean;
    procedure SetPaused(Value: Boolean);
    function Calculate: Double;
    procedure Reset;
  end;

constructor TStopwatchImpl.Create;
begin
  inherited Create;
  Reset;
end;

function TStopwatchImpl.GetTime: Double;
begin
  Result := FTime;
end;

function TStopwatchImpl.GetPaused: Boolean;
begin
  Result := FPaused;
end;

procedure TStopwatchImpl.SetPaused(Value: Boolean);
var
  Last: Double;
begin
  if Value <> FPaused then
  begin
    FPaused := Value;
    if not FPaused then
    begin
      Last := FStop;
      Calculate;
      FStart := FStart + (FStop - Last);
      FTime := FStop - FStart;
    end;
  end;
end;

function TStopwatchImpl.Calculate: Double;
begin
  if not FPaused then
  begin
    FStop := TimeQuery;
    FTime := FStop - FStart;
  end;
  Result := FTime;
end;

procedure TStopwatchImpl.Reset;
begin
  FStart := TimeQuery;
  FStop := FStart;
  FTime := 0;
end;

function StopwatchCreate: IStopwatch;
begin
  Result := TStopwatchImpl.Create;
end;
{$endregion}

{$region string routines}
function LineBreak: string;
begin
  Result := LineBreakStyles[DefaultTextLineBreakStyle];
end;

function StrUpper(const S: string): string;
begin
  Result := UpCase(S);
end;

function StrLower(const S: string): string;
begin
  Result := LowerCase(S);
end;

function StrBufCompareI(A, B: PChar): Integer;
const
  CharA = Ord('A');
  CharZ = Ord('Z');
  CharDelta = Ord('a') - Ord('A');
var
  B1: PByte absolute A;
  B2: PByte absolute B;
  C1, C2: Byte;
begin
  repeat
    C1 := B1^;
    C2 := B2^;
    if (C1 >= CharA) and (C1 <= CharZ) then
      Inc(C1, CharDelta);
    if (C2 >= CharA) and (C2 <= CharZ) then
      Inc(C2, CharDelta);
    Inc(B1);
    Inc(B2);
  until (C1 <> C2) or (C1 = 0);
  if C1 < C2 then
    Exit(-1);
  if C1 > C2 then
    Exit(1);
  Exit(0);
end;

function StrBufCompare(A, B: PChar): Integer;
var
  B1: PByte absolute A;
  B2: PByte absolute B;
  C1, C2: Byte;
begin
  repeat
    C1 := B1^;
    C2 := B2^;
    Inc(B1);
    Inc(B2);
  until (C1 <> C2) or (C1 = 0);
  if C1 < C2 then
    Exit(-1);
  if C1 > C2 then
    Exit(1);
  Exit(0);
end;

function StrCompare(const A, B: string; IgnoreCase: Boolean = False): Integer;
begin
  if (Length(A) = 0) and (Length(B) = 0) then
    Exit(0);
  if Length(A) = 0 then
    Exit(-1);
  if Length(B) = 0 then
    Exit(1);
  if IgnoreCase then
    Result := StrBufCompareI(PChar(A), PChar(B))
  else
    Result := StrBufCompare(PChar(A), PChar(B));
end;

function StrCopy(const S: string; Start: Integer; Len: Integer = 0): string;
  var
  A, B: PChar;
  I: Integer;
begin
  Result := '';
  if S = '' then
    Exit;
  if Start < 1 then
    Exit;
  I := Length(S);
  if Start > I then
    Exit;
  if Len < 1 then
    Len := Length(S);
  Dec(Start);
  if Start + Len > I then
    Len := I - Start;
  Setlength(Result, Len);
  A := PChar(S);
  B := PChar(Result);
  Inc(A, Start);
  Move(A^, B^, Len);
end;

function StrCopyData(P: Pointer; Len: Integer): string;
begin
  if Len < 1 then
    Exit('');
  SetLength(Result, Len);
  Move(P^, PChar(Result)^, Len);
end;

function StrInsert(const S, SubStr: string; Position: Integer): string;
begin
  if Position < 1 then
    Position := 1
  else if Position > Length(S) then
    Position := Length(S);
  if Position = 1 then
    Exit(SubStr + S);
  if Position = Length(S) then
    Exit(S + SubStr);
  Result := StrCopy(S, 1, Position - 1) + SubStr + StrCopy(S, Position);
end;

function StrFindBuffer(S, SubStr: PChar; SLen, SubStrLen: Integer): Integer;
var
  Current, Last: Char;
  Lookup: array[Low(Byte)..High(Byte)] of Integer;
  B: Byte;
  I, J, K: Integer;
begin
  Result := 0;
  if  (SLen = 0) or (SubStrLen = 0) then
    Exit;
  Dec(S);
  Dec(SubStr);
  for I := Low(Lookup) to High(Lookup) do
    Lookup[I] := SubStrLen;
  for I := 1 to SubStrLen - 1 do
  begin
    B := Ord(SubStr[I]);
    Lookup[B] := SubStrLen - I;
  end;
  Last := SubStr[SubStrLen];
  I := SubStrLen;
  while I <= SLen do
  begin
    Current := S[I];
    if Current = Last then
    begin
      J := I - SubStrLen;
      K := 1;
      while K < SubStrLen do
      begin
        if SubStr[K] <> S[J + K] then
          Break;
        Inc(K);
      end;
      if K = SubStrLen then
      begin
        Result := J + 1;
        Exit;
      end;
      B := Ord(Current);
      Inc(I, Lookup[B]);
    end
    else
    begin
      B := Ord(Current);
      Inc(I, Lookup[B]);
    end;
  end;
end;

function StrFindBufferI(S, SubStr: PChar; SLen, SubStrLen: Integer): Integer;
var
  Current, Last: Char;
  Lookup: array[Low(Byte)..High(Byte)] of Integer;
  B: Byte;
  I, J, K: Integer;
begin
  Result := 0;
  if (SubStrLen = 0) or (SLen = 0) then
    Exit;
  Dec(SubStr);
  Dec(S);
  for I := Low(Lookup) to High(Lookup) do
    Lookup[I] := SubStrLen;
  for I := 1 to SubStrLen - 1 do
  begin
    B := Ord(UpCase(SubStr[I]));
    Lookup[B] := SubStrLen - I;
  end;
  Last := UpCase(SubStr[SubStrLen]);
  I := SubStrLen;
  while I <= SLen do
  begin
    Current := UpCase(S[I]);
    if Current = Last then
    begin
      J := I - SubStrLen;
      K := 1;
      while K < SubStrLen do
      begin
        if UpCase(SubStr[K]) <> UpCase(S[J + K]) then
          Break;
        Inc(K);
      end;
      if K = SubStrLen then
      begin
        Result := J + 1;
        Exit;
      end;
      B := Ord(Current);
      Inc(I, Lookup[B]);
    end
    else
    begin
      B := Ord(Current);
      Inc(I, Lookup[B]);
    end;
  end;
end;

function StrTrim(const S: string): string;
const
  WhiteSpace = [#0..' '];
var
  Len, I: Integer;
begin
  Len := Length(S);
  while (Len > 0) and (S[Len] in WhiteSpace) do
   Dec(Len);
  I := 1;
  while ( I <= Len) and (S[I] in WhiteSpace) do
    Inc(I);
  Result := Copy(S, I, 1 + Len - I);
end;

function StrFind(const S, SubStr: string; IgnoreCase: Boolean = False): Integer;
begin
  if IgnoreCase then
    Result := StrFindBufferI(PChar(S), PChar(SubStr), Length(S), Length(SubStr))
  else
    Result := StrFindBuffer(PChar(S), PChar(SubStr), Length(S), Length(SubStr));
end;

function StrFind(const S, SubStr: string; Start: Integer; IgnoreCase: Boolean = False): Integer;
var
  P: PChar;
  I: Integer;
begin
  P := PChar(S);
  I := Length(S);
  if (Start < 1) or (Start > I) then
  begin
    Result := 0;
    Exit;
  end;
  Dec(Start);
  Inc(P, Start);
  Dec(I, Start);
  if IgnoreCase then
    Result := StrFindBufferI(P, PChar(SubStr), I, Length(SubStr))
  else
    Result := StrFindBuffer(P, PChar(SubStr), I, Length(SubStr));
  if Result > 0 then
    Inc(Result, Start);
end;

function StrFindCount(const S, SubStr: string; IgnoreCase: Boolean = False): Integer;
var
  Start, Index: Integer;
begin
  Result := 0;
  Start := 1;
  repeat
    Index := StrFind(S, SubStr, Start, IgnoreCase);
    if Index > 0 then
    begin
      Inc(Result);
      Start := Index + 1;
    end;
  until Index = 0;
end;

function StrFindIndex(const S, SubStr: string; IgnoreCase: Boolean = False): IntArray;
var
  Start, Index: Integer;
begin
  Result.Length := StrFindCount(S, SubStr, IgnoreCase);
  Start := 1;
  Index := 0;
  while Index < Result.Length do
  begin
    Start := StrFind(S, SubStr, Start, IgnoreCase);
    Result[Index] := Start;
    Inc(Start);
    Inc(Index);
  end;
end;

function StrReplace(const S, OldPattern, NewPattern: string; IgnoreCase: Boolean = False): string;
var
  PosIndex: IntArray;
  I, J, K, L: Integer;
begin
  PosIndex := StrFindIndex(S, OldPattern, IgnoreCase);
  if PosIndex.Length = 0 then
  begin
    Result := S;
    Exit;
  end;
  Result.length := S.Length + (NewPattern.Length - OldPattern.Length) * PosIndex.Length;
  I := 0;
  J := 1;
  K := 1;
  while K <= S.Length do
  begin
    if K = PosIndex[I] then
    begin
      if I < PosIndex.Hi then
        Inc(I);
      Inc(K, OldPattern.Length);
      for L := 1 to NewPattern.Length do
      begin
        Result[J] := NewPattern[L];
        Inc(J);
      end;
    end
    else
    begin
      Result[J] := S[K];
      Inc(J);
      Inc(K);
    end;
  end;
end;

function StrReplaceOne(const S, OldPattern, NewPattern: string; IgnoreCase: Boolean = False): string;
var
  I: Integer;
begin
  I := StrFind(S, OldPattern, IgnoreCase);
  if I > 0 then
    Result := Copy(S, 1, I - 1) + NewPattern + Copy(S, I + Length(OldPattern), Length(S))
  else
    Result := S;
end;

function StrReplaceAfter(const S, OldPattern, NewPattern: string; IgnoreCase: Boolean = False): string;
var
  I: Integer;
begin
  I := StrFind(S, OldPattern, IgnoreCase);
  if I > 0 then
    Result := Copy(S, 1, I - 1) + NewPattern
  else
    Result := S;
end;

function StrEquals(const S: string; Value: string): Boolean;
begin
  Result := StrCompare(S, Value, True) = 0;
end;

function StrEquals(const S: string; const Values: array of string): Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := Low(Values) to High(Values) do
    if StrCompare(S, Values[I], True) = 0 then
    begin
      Result := True;
      Break;
    end;
end;

function StrIndex(const S: string; const Values: array of string): Integer;
var
  I: Integer;
begin
  Result := -1;
  for I := Low(Values) to High(Values) do
    if S = Values[I] then
    begin
      Result := I;
      Break;
    end;
end;

function StrSplit(const S, Separator: string): StringArray;
var
  Splits: IntArray;
  Pos: Integer;
  I: Integer;
begin
  if S.Length < 1 then
    Exit;
  if Separator.Length < 1 then
    Exit;
  if StrFind(S, Separator) < 1 then
  begin
    Result.Length := 1;
    Result[0] := S;
    Exit;
  end;
  Splits := StrFindIndex(S, Separator);
  Result.Length := Splits.Length + 1;
  Pos := 1;
  for I := Splits.Lo to Splits.Hi do
  begin
    Result[I] := Copy(S, Pos, Splits[I] - Pos);
    Pos := Splits[I] + Separator.Length;
  end;
  Result.Items[Splits.Length] := Copy(S, Pos, S.Length);
end;

function StrSplitInt(const S, Separator: string): IntArray;
var
  Data: StringArray;
  I: Integer;
begin
  Data := StrSplit(S, Separator);
  Result.Length := Data.Length;
  try
    for I := Data.Lo to Data.Hi do
      Result[I] := SysUtils.StrToInt(Data[I]);
  except
    Result.Clear;
  end;
end;

function StrSplitInt64(const S, Separator: string): Int64Array;
var
  Data: StringArray;
  I: Integer;
begin
  Data := StrSplit(S, Separator);
  Result.Length := Data.Length;
  try
    for I := Data.Lo to Data.Hi do
      Result[I] := SysUtils.StrToInt64(Data[I]);
  except
    Result.Clear;
  end;
end;

function StrJoin(const A: StringArray; const Separator: string): string;
var
  I: Integer;
begin
  Result := '';
  if A.Length < 1 then
    Exit;
  Result := A.First;
  for I := A.Lo + 1 to A.Hi do
    Result := Result + Separator + A[I];
end;

function StrJoinInt(const A: IntArray; const Separator: string): string;
var
  I: Integer;
begin
  Result := '';
  if A.Length < 1 then
    Exit;
  Result := SysUtils.IntToStr(A.First);
  for I := A.Lo + 1 to A.Hi do
    Result := Result + Separator + SysUtils.IntToStr(A[I]);
end;

function StrFirstOf(const S, Separator: string): string;
var
  I: Integer;
begin
  I := StrFind(S, Separator);
  if I > 0 then
    if I = 1 then
      Result := ''
    else
      Result := StrCopy(S, 1, I - 1)
  else
    Result := S;
end;

function StrSecondOf(const S, Separator: string): string;
var
  I: Integer;
begin
  I := StrFind(S, Separator);
  if I > 0 then
    Result := StrCopy(S, I + Length(Separator))
  else
    Result := '';
end;

function StrLastOf(const S, Separator: string): string;
var
  A: StringArray;
begin
  A := StrSplit(S, Separator);
  if A.Length > 0 then
    Result := A.Last
  else
    Result := '';
end;

function StrContains(const S, SubStr: string; IgnoreCase: Boolean = False): Boolean;
begin
  if Length(S) < 1 then
    Exit(False);
  if Length(SubStr) < 1 then
    Exit(False);
  if Length(SubStr) > Length(S) then
    Exit(False);
  Result := StrFind(S, SubStr, IgnoreCase) > 0;
end;

function StrBeginsWith(const S, SubStr: string; IgnoreCase: Boolean = False): Boolean;
var
  C: string;
begin
  if Length(S) < 1 then
    Exit(False);
  if Length(SubStr) < 1 then
    Exit(False);
  if Length(SubStr) > Length(S) then
    Exit(False);
  C := StrCopy(S, 1, Length(SubStr));
  Result := StrCompare(C, SubStr, IgnoreCase) = 0;
end;

function StrEndsWith(const S, SubStr: string; IgnoreCase: Boolean = False): Boolean;
var
  C: string;
begin
  if Length(S) < 1 then
    Exit(False);
  if Length(SubStr) < 1 then
    Exit(False);
  if Length(SubStr) > Length(S) then
    Exit(False);
  C := StrCopy(S, Length(S) - Length(SubStr) + 1, Length(SubStr));
  Result := StrCompare(C, SubStr, IgnoreCase) = 0;
end;

function StrOf(C: Char; Len: Integer): string;
var
  I: Integer;
begin
  if Len < 1 then
    Exit;
  SetLength(Result, Len);
  for I := 1 to Len do
    Result[I] := C;
end;

function StrPadLeft(const S: string; C: Char; Len: Integer): string;
var
  I: Integer;
begin
  Result := '';
  I := Length(S);
  if I < 1 then
    Exit;
  if Len < 1 then
    Exit;
  if I > Len then
  begin
    Result := Copy(S, 1, Len);
    Exit;
  end;
  Result := S + StrOf(C, Len - I);
end;

function StrPadRight(const S: string; C: Char; Len: Integer): string;
var
  I: Integer;
begin
  Result := '';
  I := Length(S);
  if I > Len then
  begin
    Result := Copy(S, Len - I, Len);
    Exit;
  end;
  Result := StrOf(C,  Len - I) + S;
end;

function StrQuote(const S: string): string;
begin
  if StrContains(S, ' ' ) then
    Result := '"' + StrReplace(S, '"', '''') + '"'
  else
    Result := S;
end;

function IsAlpha(C: Char): Boolean;
begin
  Result := (C >= 'A') and (C <= 'Z');
  if Result then Exit;
  Result := (C >= 'a') and (C <= 'z');
end;

function IsUnderscore(C: Char): Boolean;
begin
  Result := C = '_';
end;

function IsNumeric(C: Char): Boolean;
begin
  Result := (C >= '0') and (C <= '9');
end;

function StrIsBlank(const S: string): Boolean;
var
  I: Integer;
begin
  for I := 1 to Length(S) do
    if S[I] > ' ' then
      Exit(False);
  Result := True;
end;

function StrIsIdent(const S: string): Boolean;
var
  AlphaFound: Boolean;
  C: Char;
  I: Integer;
begin
  Result := False;
  if Length(S) < 1 then
    Exit;
  C := S[1];
  AlphaFound := IsAlpha(C);
  if (not AlphaFound) and (not IsUnderscore(C)) then
    Exit;
  for I := 2 to Length(S) do
  begin
    C := S[I];
    AlphaFound := AlphaFound or IsAlpha(C);
    if IsAlpha(C) or IsUnderscore(C) or IsNumeric(C) then
      Continue;
    Exit;
  end;
  Result := AlphaFound;
end;

function StrIsAttr(const S: string): Boolean;
begin
  Result := False;
  if Length(S) < 2 then
    Exit;
  if S[1] <> '@' then
    Exit;
  Result := StrIsIdent(Copy(S, 2, Length(S) - 1));
end;

function StrLineBreakStyle(const S: string): TTextLineBreakStyle;
var
  Count: array[TTextLineBreakStyle] of Integer;
  I: TTextLineBreakStyle;
begin
  for I := Low(Count) to High(Count) do
    Count[I] := StrFindCount(S, LineBreakStyles[I]);
  Result := DefaultTextLineBreakStyle;
  for I := Low(Count) to High(Count) do
    if Count[I] > Count[Result] then
      Result := I;
end;

function StrAdjustLineBreaks(const S: string; Style: TTextLineBreakStyle): string;
var
  Line: string;
  I, J: Integer;
begin
  if Length(S) < 1 then
    Exit('');
  I := StrFindCount(S, #10) + StrFindCount(S, #13);
  SetLength(Result, Length(S) + I * 2);
  Line := LineBreakStyles[Style];
  I := 1;
  J := 1;
  while S[I] > #0  do
  begin
    if ((S[I] = #10) and (S[I + 1] = #13)) or ((S[I] = #13) and (S[I + 1] = #10)) then
    begin
      Result[J] := Line[1];
      Inc(J);
      if Style = tlbsCRLF then
      begin
        Result[J] := Line[2];
        Inc(J);
      end;
      Inc(I);
    end
    else if (S[I] = #10) or (S[I] = #13) then
    begin
      Result[J] := Line[1];
      Inc(J);
      if Style = tlbsCRLF then
      begin
        Result[J] := Line[2];
        Inc(J);
      end;
    end
    else
    begin
      Result[J] := S[I];
      Inc(J);
    end;
    Inc(I);
  end;
  SetLength(Result, J - 1);
end;

function StrAdjustLineBreaks(const S: string): string;
begin
  Result := StrAdjustLineBreaks(S, DefaultTextLineBreakStyle);
end;

function StrToWide(const S: string): WideString;
var
  I: Integer;
begin
  I := Length(S);
  if I < 1 then
    Exit('');
  SetLength(Result, I);
  StringToWideChar(S, PWideChar(Result), I + 1);
end;

function WideToStr(const S: WideString): string;
begin
  if Length(S) < 1 then
    Exit('');
  WideCharToStrVar(PWideChar(S), Result);
end;

function SwitchExists(const Switch: string): Boolean;
begin
  Result := SwitchIndex(Switch) > 0;
end;

function SwitchIndex(const Switch: string): Integer;
var
  S: string;
  I: Integer;
begin
  for I := 1 to ParamCount do
  begin
    S := ParamStr(I);
    if S = SwitchChar + Switch then
      Exit(I)
  end;
  Result := -1;
end;

function SwitchValue(const Switch: string): string;
var
  F: Boolean;
  S: string;
  I: Integer;
begin
  F := False;
  for I := 1 to ParamCount do
  begin
    S := ParamStr(I);
    if F then
      Exit(S);
    if S = SwitchChar + Switch then
      F := True;
  end;
  Result := '';
end;

function IntToStr(Value: Integer): string;
begin
  Str(Value, Result);
end;

function StrToInt(const S: string): Integer;
begin
  Result := SysUtils.StrToInt(S);
end;

function StrToIntDef(const S: string; Default: Integer): Integer;
begin
  Result := SysUtils.StrToIntDef(S, Default);
end;

function FloatToStr(Value: Extended): string;
const
  Epsilon = 0.0001;
var
  E: Extended;
  I: Integer;
begin
  E := Value - Trunc(Value);
  I := 0;
  while E > Epsilon do
  begin
    E := E * 10;
    E := E - Trunc(E);
    Inc(I);
  end;
  Str(Value:0:I, Result);
end;

function FloatToStr(Value: Extended; Decimals: Integer): string;
begin
  Str(Value:0:Decimals, Result);
end;

function FloatToCommas(Value: Extended; Decimals: Integer = 0): string;
begin
  Result := FloatToStrF(Value, ffNumber, 15 , Decimals);
end;

function StrToFloat(const S: string): Extended;
begin
  Result := SysUtils.StrToFloat(S);
end;

function StrToFloatDef(const S: string; Default: Extended): Extended;
begin
  Result := SysUtils.StrToFloatDef(S, Default);
end;

function StrEnvironmentVariable(const Name: string): string;
begin
  Result := GetEnvironmentVariableUTF8(Name);
end;

function StrFormat(const S: string; Args: array of const): string;
begin
  Result := Format(S, Args);
end;

function StrCompPath(Component: TComponent): string;
var
  S: string;
begin
  if Component = nil then
    Exit('nil');
  Result := '';
  while Component <> nil do
  begin
    if Component.ClassName = 'TApplication' then Exit;
    S := Component.Name;
    if S = '' then
      S := '(' + Component.ClassName + ')';
    if Result <> '' then
      Result := '.' + Result;
    Result := S + Result;
    Component := Component.Owner;
  end;
end;

{ StringHelper }

function StringHelper.ToString: string;
begin
  Result := Self;
end;

procedure StringHelper.Unique;
begin
  System.UniqueString(Self);
end;

procedure StringHelper.CharInto(C: Char; Len: Integer);
begin
  Self := StrOf(C, Len);
end;

procedure StringHelper.CopyInto(P: Pointer; Len: Integer);
begin
  Self := StrCopyData(P, Len);
end;

procedure StringHelper.InsertInto(const SubStr: string; Position: Integer);
begin
  Self := StrInsert(Self, SubStr, Position);
end;

function StringHelper.Equals(const Value: string; IgnoreCase: Boolean = False): Boolean;
begin
  Result := StrCompare(Self, Value, IgnoreCase) = 0;
end;

function StringHelper.Equals(const Values: array of string; IgnoreCase: Boolean = False): Boolean;
var
  S: string;
begin
  for S in Values do
    if StrCompare(Self, S, IgnoreCase) = 0 then
      Exit(True);
  Result := False;
end;

function StringHelper.Compare(const Value: string; IgnoreCase: Boolean = False): Integer;
begin
  Result := StrCompare(Self, Value, IgnoreCase);
end;

function StringHelper.ToUpper: string;
begin
  Result := StrUpper(Self);
end;

function StringHelper.ToLower: string;
begin
  Result := StrLower(Self);
end;

function StringHelper.Copy(Start: Integer; Len: Integer = 0): string;
begin
  Result := StrCopy(Self, Start, Len);
end;

function StringHelper.Insert(const SubStr: string; Position: Integer): string;
begin
  Result := StrInsert(Self, SubStr, Position);
end;

function StringHelper.IndexOf(const SubStr: string; IgnoreCase: Boolean = False): Integer;
begin
  Result := StrFind(Self, SubStr, IgnoreCase);
end;

function StringHelper.IndexOf(const SubStr: string; Start: Integer; IgnoreCase: Boolean = False): Integer;
begin
  Result := StrFind(Self, SubStr, Start, IgnoreCase);
end;

function StringHelper.MatchCount(const SubStr: string; IgnoreCase: Boolean = False): Integer;
begin
  Result := StrFindCount(Self, SubStr, IgnoreCase);
end;

function StringHelper.Matches(const SubStr: string; IgnoreCase: Boolean = False): IntArray;
begin
  Result := StrFindIndex(Self, SubStr, IgnoreCase);
end;

function StringHelper.Replace(const OldPattern, NewPattern: string; IgnoreCase: Boolean = False): string;
begin
  Result := StrReplace(Self, OldPattern, NewPattern, IgnoreCase);
end;

function StringHelper.ReplaceOne(const OldPattern, NewPattern: string; IgnoreCase: Boolean = False): string;
begin
  Result := StrReplaceOne(Self, OldPattern, NewPattern, IgnoreCase);
end;

function StringHelper.ReplaceAfter(const OldPattern, NewPattern: string; IgnoreCase: Boolean = False): string;
begin
  Result := StrReplaceAfter(Self, OldPattern, NewPattern, IgnoreCase);
end;

function StringHelper.Trim: string;
begin
  Result := StrTrim(Self);
end;

function StringHelper.ArrayIndex(const Values: array of string): Integer;
begin
  Result := StrIndex(Self, Values);
end;

function StringHelper.Split(Separator: string): StringArray;
begin
  Result := StrSplit(Self, Separator);
end;

function StringHelper.SplitInt(const Separator: string): IntArray;
begin
  Result := StrSplitInt(Self, Separator);
end;

function StringHelper.SplitInt64(const Separator: string): Int64Array;
begin
  Result := StrSplitInt64(Self, Separator);
end;

function StringHelper.Words(MaxColumns: Integer = 0): StringArray;
var
  W: string;
  C, I: Integer;
begin
  if MaxColumns < 1 then
    MaxColumns := High(Integer);
  C := 0;
  for I := 1 to Length do
  begin
    if C >= MaxColumns then
      W := W + Self[I]
    else if Self[I] <= ' ' then
    begin
      if W.Length > 0 then
      begin
        Result.Push(W);
        Inc(C);
      end;
      W := '';
    end
    else
      W := W + Self[I];
  end;
  if W.Length > 0 then
    Result.Push(W)
end;

function StringHelper.FirstOf(const Separator: string): string;
begin
  Result := StrFirstOf(Self, Separator);
end;

function StringHelper.SecondOf(const Separator: string): string;
begin
  Result := StrSecondOf(Self, Separator);
end;

function StringHelper.LastOf(const Separator: string): string;
begin
  Result := StrLastOf(Self, Separator);
end;

function StringHelper.Between(const MarkerA, MarkerB: string): string;
begin
  Result := Self.SecondOf(MarkerA).FirstOf(MarkerB);
end;

function StringHelper.Contains(const SubStr: string; IgnoreCase: Boolean = False): Boolean;
begin
  Result := StrContains(Self, SubStr, IgnoreCase);
end;

function StringHelper.BeginsWith(const SubStr: string; IgnoreCase: Boolean = False): Boolean;
begin
  Result := StrBeginsWith(Self, SubStr, IgnoreCase);
end;

function StringHelper.EndsWith(const SubStr: string; IgnoreCase: Boolean = False): Boolean;
begin
  Result := StrEndsWith(Self, SubStr, IgnoreCase);
end;

function StringHelper.PadLeft(C: Char; Len: Integer): string;
begin
  Result := StrPadLeft(Self, C, Len);
end;

function StringHelper.PadRight(C: Char; Len: Integer): string;
begin
  Result := StrPadRight(Self, C, Len);
end;

function StringHelper.Quote: string;
begin
  Result := StrQuote(Self);
end;

function StringHelper.Format(Args: array of const): string;
begin
  Result := SysUtils.Format(Self, Args);
end;

function StringHelper.LineBreakStyle: TTextLineBreakStyle;
begin
  Result := StrLineBreakStyle(Self);
end;

function StringHelper.AdjustLineBreaks(Style: TTextLineBreakStyle): string;
begin
  Result := StrAdjustLineBreaks(Self, Style);
end;

function StringHelper.AdjustLineBreaks: string;
begin
  Result := StrAdjustLineBreaks(Self);
end;

function StringHelper.GetIsEmpty: Boolean;
begin
  Result := Length = 0;
end;

function StringHelper.GetIsWhitespace: Boolean;
begin
  Result := StrIsBlank(Self);
end;

function StringHelper.GetIsIdentifier: Boolean;
begin
  Result := StrIsIdent(Self);
end;

function StringHelper.GetIsAttribute: Boolean;
begin
  Result := StrIsAttr(Self);
end;

function StringHelper.GetLength: Integer;
begin
  Result := System.Length(Self);
end;

procedure StringHelper.SetLength(Value: Integer);
begin
  System.SetLength(Self, Value);
end;

{ IntHelper }

function IntHelper.ToString: string;
begin
  Result := IntToStr(Self);
end;

function IntHelper.Between(Low, High: Integer): Boolean;
begin
  Result := (Self >= Low) and (Self <= High);
end;


{ TDateTimeHelper }

function TDateTimeHelper.ToString(Format: string = ''): string;
begin
  if Format = 'GMT' then
    Result := FormatDateTime('ddd, d mmm yyyy hh:nn:ss', Self) + ' GMT'
  else if Format = 'UTC' then
    Result := FormatDateTime('ddd, d mmm yyyy hh:nn:ss', Self) + ' UTC'
  else
    Result := FormatDateTime('yyyy-mm-dd hh:nn:ss', Self);
end;

function TDateTimeHelper.AddMinutes(const A: Integer): TDateTime;
const
  Minute = 1 / (24 * 60);
begin
  Result := Self + A * Minute;
end;

function TDateTimeHelper.Year: Word;
var
  Y, M, D: Word;
begin
  DecodeDate(Self, Y, M, D);
  Result := Y;
end;

function TDateTimeHelper.Month: Word;
var
  Y, M, D: Word;
begin
  DecodeDate(Self, Y, M, D);
  Result := M;
end;

function TDateTimeHelper.Day: Word;
var
  Y, M, D: Word;
begin
  DecodeDate(Self, Y, M, D);
  Result := D;
end;

{ TStringsHelper }

procedure TStringsHelper.AddLine;
begin
  Self.Add('');
end;

procedure TStringsHelper.AddFormat(const S: string; const Args: array of const);
begin
  Self.Add(Format(S, Args));
end;

function TStringsHelper.Contains(const S: string; IgnoreCase: Boolean = False): Boolean;
begin
  Result := StrContains(Text, S, IgnoreCase);
end;

{$endregion}

{$region file management routines}
function FileDelete(const FileName: string): Boolean;
begin
  Result := FileUtil.DeleteFileUTF8(FileName);
end;

function FileCopy(const SourceName, DestName: string;
  PreserveTime: Boolean = False): Boolean;
begin
  Result := CopyFile(SourceName, DestName, PreserveTime);
end;

function FileRename(const OldName, NewName: String): Boolean;
begin
  Result := FileUtil.RenameFileUTF8(OldName, NewName);
end;

function FileExists(const FileName: string): Boolean;
begin
  Result := FileUtil.FileExistsUTF8(FileName);
end;

function FileSize(const FileName: string): LargeWord;
begin
  Result := FileUtil.FileSize(FileName);
end;

function FileDate(const FileName: string): TDateTime;
begin
  SysUtils.FileAge(FileName, Result, False);
end;

function FileExtractName(const FileName: string): string;
begin
  Result := StrLastOf(PathAdjustDelimiters(FileName), DirectorySeparator);
end;

function FileExtractExt(const FileName: string): string;
begin
  Result := StrLastOf(PathAdjustDelimiters(FileName), DirectorySeparator);
  if StrFind(Result, '.') > 0 then
    Result := '.' + StrLastOf(Result, '.')
  else
    Result := '';
end;

function FileChangeExt(const FileName, Extension: string): string;
var
  S: string;
begin
  S := FileExtractExt(FileName);
  if S = '' then
    Result := FileName + Extension
  else
    Result := StrCopy(FileName, 1, Length(FileName) - Length(S)) + Extension;
end;

function FileExtractPath(const FileName: string): string;
var
  S: string;
begin
  S := StrLastOf(FileName, DirectorySeparator);
  if S = '' then
    Result := ''
  else
    Result := StrCopy(FileName, 1, Length(FileName) - Length(S) - 1);
end;

procedure FileWriteStr(const FileName: string; const Contents: string);
var
  F: TFileStream;
begin
  F := TFileStream.Create(FileName, fmCreate);
  try
    if Length(Contents) > 0 then
      F.Write(Contents[1], Length(Contents));
  finally
    F.Free;
  end;
end;

function FileReadStr(const FileName: string): string;
var
  F: TFileStream;
begin
  Result := '';
  if FileUtil.FileExistsUTF8(FileName) then
  begin
    F := TFileStream.Create(FileName, fmOpenRead);
    try
      SetLength(Result, F.Size);
      if Length(Result) > 0 then
        F.Read(Result[1], Length(Result));
    finally
      F.Free;
    end;
  end;
end;

procedure FileWriteLine(const FileName: string; const Line: string);
var
  F: TFileStream;
  S: string;
begin
  if FileUtil.FileExistsUTF8(FileName) then
    F := TFileStream.Create(FileName, fmOpenWrite)
  else
    F := TFileStream.Create(FileName, fmCreate);
  F.Seek(0, soFromEnd);
  try
    if Length(Line) > 0 then
      F.Write(Line[1], Length(Line));
    S := LineBreakStyles[DefaultTextLineBreakStyle];
    F.Write(S[1], Length(S));
  finally
    F.Free;
  end;
end;

function DirCreate(const Dir: string): Boolean;
begin
  Result := FileUtil.ForceDirectoriesUTF8(Dir);
end;

function DirGetCurrent: string;
begin
  Result := FileUtil.GetCurrentDirUTF8;
end;

function DirSetCurrent(const Dir: string): Boolean;
begin
  Result := FileUtil.SetCurrentDirUTF8(Dir);
end;

function DirGetTemp(Global: Boolean = False): string;
begin
  Result := SysUtils.GetTempDir(Global);
end;

function DirDelete(const Dir: string; OnlyContents: Boolean = False): Boolean;
begin
  Result := DeleteDirectory(Dir, OnlyContents);
end;

function DirExists(const Dir: string): Boolean;
begin
  Result := FileUtil.DirectoryExistsUTF8(Dir);
end;

function DirForce(const Dir: string): Boolean;
begin
  Result := ForceDirectoriesUTF8(Dir);
end;

function PathAdjustDelimiters(const Path: string): string;
begin
  {$warnings off}
  if DirectorySeparator = '/' then
    Result := StrReplace(Path, '\', DirectorySeparator)
  else
    Result := StrReplace(Path, '/', DirectorySeparator);
  {$warnings on}
end;

function PathCombine(const A, B: string): string;
begin
  Result := PathIncludeDelimiter(A) + PathExcludeDelimiter(B);
end;

function PathExpand(const Path: string): string;
begin
  Result := ExpandFileNameUTF8(Path);
end;

function PathIncludeDelimiter(const Path: string): string;
begin
  Result := IncludeTrailingPathDelimiter(Path);
end;

function PathExcludeDelimiter(const Path: string): string;
begin
  Result := ExcludeTrailingPathDelimiter(Path);
end;

function ConfigAppFile(Global: Boolean; CreateDir: Boolean = False): string;
begin
  Result := GetAppConfigFileUTF8(Global, False, CreateDir);
end;

function ConfigAppDir(Global: Boolean; CreateDir: Boolean = False): string;
begin
  Result := GetAppConfigDirUTF8(Global, CreateDir);
end;

function FindOpen(const Path: string; Attr: Longint; out Search: TSearchRec): LongInt;
begin
  Result := FindFirst(PathAdjustDelimiters(Path), Attr, Search);
end;

function FindFiles(const Path: string): TStrings;
var
  Name, Folder: string;
  Search: TSearchRec;
begin
  if DirectoryExists(Path) then
  begin
    Name := '*';
    Folder := Path;
  end
  else
  begin
    Name := FileExtractName(Path);
    Folder := FileExtractPath(Path);
    if Folder = Path then
      Folder := '.'
  end;
  Result := TStringList.Create;
  if FindOpen(PathCombine(Folder, Name), faAnyFile and (not faDirectory), Search) = 0 then
  begin
    repeat
      Result.Add(PathCombine(Folder, Search.Name));
    until FindNext(Search) <> 0;
    FindClose(Search);
  end;
end;

function FindFileParams(StartIndex: Integer): TStrings;
var
  Search: TStrings;
  S: string;
  I: Integer;
begin
  Result := TStringList.Create;
  if StartIndex < 1 then
    Exit;
  for I := StartIndex to ParamCount do
  begin
    S := ParamStrUTF8(I);
    if FileUtil.FileExistsUTF8(S) then
      Result.Add(S)
    else
    begin
      Search := FindFiles(S);
      Result.AddStrings(Search);
      Search.Free;
    end;
  end;
end;
{$endregion}

{$region generic containers}
{ TArrayEnumerator<T> }

constructor TArrayEnumerator<T>.Create(Items: TArray<T>; Count: Integer = -1);
begin
  inherited Create;
  FItems := Items;
  FPosition := -1;
  if Count < 0 then
    FCount := Length(Items)
  else
    FCount := Count;
end;

function TArrayEnumerator<T>.GetCurrent: T;
begin
  Result := FItems[FPosition];
end;

function TArrayEnumerator<T>.MoveNext: Boolean;
begin
  Inc(FPosition);
  Result := FPosition < FCount;
end;

procedure TArrayEnumerator<T>.Reset;
begin
  FPosition := -1;
end;

{ TArrayList<T> }

function TArrayList<T>.GetEnumerator: IEnumerator<T>;
begin
  Result := TArrayListEnumerator.Create(Items);
end;

class operator TArrayList<T>.Implicit(const Value: TArrayList<T>): TArray<T>;
begin
  Result := Value.Items;
end;

class operator TArrayList<T>.Implicit(const Value: TArray<T>): TArrayList<T>;
begin
  Result.Items := Value;
end;

class operator TArrayList<T>.Implicit(const Value: array of T): TArrayList<T>;
var
  I: T;
begin
  for I in Value do
    Result.Push(I);
end;

procedure TArrayList<T>.Reverse;
var
  Swap: T;
  I, J: Integer;
begin
  I := 0;
  J := Length;
  while I < J do
  begin
    Swap := Items[I];
    Items[I] := Items[J];
    Items[J] := Swap;
    Inc(I);
    Dec(J);
  end;
end;

function TArrayList<T>.Lo: Integer;
begin
  Result := Low(Items);
end;

function TArrayList<T>.Hi: Integer;
begin
  Result := High(Items);
end;

procedure TArrayList<T>.Exchange(A, B: Integer);
var
  Item: T;
begin
  if A <> B then
  begin
    Item := Items[A];
    Items[A] := Items[B];
    Items[B] := Item;
  end;
end;

procedure TArrayList<T>.Push(const Item: T);
var
  I: Integer;
begin
  I := Length;
  Length := I + 1;
  Items[I] := Item;
end;

procedure TArrayList<T>.PushRange(const Collection: array of T);
var
  I, J: Integer;
begin
  I := Length;
  J := High(Collection) - Low(Collection) + 1;
  if J < 1 then
    Exit;
  Length := I + J;
  for J := Low(Collection) to High(Collection) do
  begin
    Items[I] := Collection[J];
    Inc(I);
  end;
end;

function TArrayList<T>.Pop: T;
var
  I: Integer;
begin
  I := Length - 1;
  if I < 0 then
  begin
    Result := Default(T);
    Length := 0;
  end
  else
  begin
    Result := Items[I];
    Length := I;
  end;
end;

function TArrayList<T>.PopRandom: T;
var
  I: Integer;
begin
  I := Length;
  if I < 2 then
    Result := Pop
  else
  begin
    I := Random(I);
    Result := Items[I];
    Delete(I);
  end;
end;

procedure TArrayList<T>.Delete(Index: Integer);
var
  I, J: Integer;
begin
  I := Length - 1;
  for J := Index + 1 to I do
    Items[J - 1] := Items[J];
  Length := I;
end;

procedure TArrayList<T>.Clear;
begin
  Length := 0;
end;

procedure TArrayList<T>.QuickSort(Compare: TCompare<T>; L, R: Integer);
var
  I, J, P: Integer;
begin
  repeat
    I := L;
    J := R;
    P := (L + R) shr 1;
    repeat
      while Compare(Items[I], Items[P]) < 0 do Inc(I);
      while Compare(Items[J], Items[P]) > 0 do Dec(J);
      if I <= J then
      begin
        Exchange(I, J);
        if P = I then
          P := J
        else if P = J then
          P := I;
        Inc(I);
        Dec(J);
      end;
    until I > J;
    if L < J then QuickSort(Compare, L, J);
    L := I;
  until I >= R;
end;

procedure TArrayList<T>.Sort(Comparer: TCompare<T> = nil);
var
  I: Integer;
begin
  I := Length;
  if I < 2 then
    Exit;
  if Assigned(Comparer) then
    QuickSort(Comparer, 0, I - 1)
  else if Assigned(DefaultCompare) then
    QuickSort(DefaultCompare, 0, I - 1);
end;

function TArrayList<T>.IndexOf(const Item: T): Integer;
var
  I: Integer;
begin
  I := Length;
  if I < 1 then
    Result := -1
  else if Assigned(DefaultCompare) then
  begin
    for I := Lo to Hi do
      if DefaultCompare(Item, Items[I]) = 0 then
        Exit(I);
  end
  else
    Result := -1;
end;

function TArrayList<T>.Join(const Separator: string; Convert: TConvertString<T> = nil): string;
var
  I: Integer;
begin
  Result := '';
  if Length < 1 then
    Exit;
  if Assigned(Convert) then
  begin
    Result := Convert(First);
    for I := Low(Items) + 1 to High(Items) do
      Result := Result + Separator + Convert(Items[I]);
  end
  else if Assigned(DefaultConvertString) then
  begin
    Result := DefaultConvertString(First);
    for I := Low(Items) + 1 to High(Items) do
      Result := Result + Separator + DefaultConvertString(Items[I]);
  end;
end;

function TArrayList<T>.GetIsEmpty: Boolean;
begin
  Result := Length = 0;
end;

function TArrayList<T>.GetFirst: T;
begin
  Result := Items[0];
end;

procedure TArrayList<T>.SetFirst(const Value: T);
begin
  Items[0] := Value;
end;

function TArrayList<T>.GetLast: T;
begin
  Result := Items[Length - 1];
end;

procedure TArrayList<T>.SetLast(const Value: T);
begin
  Items[Length - 1] := Value;
end;

function TArrayList<T>.GetLength: Integer;
begin
  Result := System.Length(Items);
end;

procedure TArrayList<T>.SetLength(Value: Integer);
begin
  System.SetLength(Items, Value);
end;

function TArrayList<T>.GetData: Pointer;
begin
  Result := @Items[0];
end;

function TArrayList<T>.GetItem(Index: Integer): T;
begin
  Result := Items[Index];
end;

procedure TArrayList<T>.SetItem(Index: Integer; const Value: T);
begin
  Items[Index] := Value;
end;

class function TArrayList<T>.Convert: TArrayList<T>;
begin
  Result.Length := 0;
end;

{ TNamedValues<T> }

function TNamedValues<T>.GetEnumerator: IEnumerator<string>;
begin
  Result := FNames.GetEnumerator;
end;

procedure TNamedValues<T>.Add(const Name: string; const Value: T);
var
  S: string;
  I: Integer;
begin
  if Name = '' then
    Exit;
  S := StrUpper(Name);
  for I := 0 to FNames.Length - 1 do
    if S = StrUpper(FNames[I]) then
    begin
      FValues[I] := Value;
      Exit;
    end;
  FNames.Push(Name);
  FValues.Push(Value);
end;

procedure TNamedValues<T>.Remove(const Name: string);
var
  S: string;
  I: Integer;
begin
  if Name = '' then
    Exit;
  S := Name.ToUpper;
  for I := FNames.Lo to FNames.Hi - 1 do
    if S = FNames[I].ToUpper then
    begin
      Delete(I);
      Exit;
    end;
end;

procedure TNamedValues<T>.Delete(Index: Integer);
begin
  if (Index > -1) and (Index < FNames.Length) then
  begin
    FNames.Delete(Index);
    FValues.Delete(Index);
  end;
end;

procedure TNamedValues<T>.Clear;
begin
  FNames.Clear;
  FValues.Clear;
end;

function TNamedValues<T>.GetCount: Integer;
begin
  Result := FNames.Length;
end;

function TNamedValues<T>.GetEmpty: Boolean;
begin
  Result := FNames.Length < 1;
end;

function TNamedValues<T>.GetName(Index: Integer): string;
begin
  if (Index > -1) and (Index < FNames.Length) then
    Result := FNames[Index]
  else
    Result := '';
end;

function TNamedValues<T>.GetValue(const Name: string): T;
var
  S: string;
  I: Integer;
begin
  Result := default(T);
  if Name = '' then
    Exit;
  S := Name.ToUpper;
  for I := FNames.Lo to FNames.Hi do
    if S = FNames[I].ToUpper then
    begin
      Result := FValues[I];
      Exit;
    end;
end;

function MemCompare(const A, B; Size: LongWord): Boolean;
var
  C, D: PByte;
begin
  C := @A;
  D := @B;
  if (C = nil) or (D = nil) then
    Exit(False);
  while Size > 0 do
  begin
    if C^ <> D^ then
      Exit(False);
    Inc(C);
    Inc(D);
    Dec(Size);
  end;
  Result := True;
end;

{ TDelegateImpl<T> }

function TDelegateImpl<T>.IndexOf(Event: T): Integer;
var
  Item: T;
  I: Integer;
begin
  I := 0;
  for Item in FList do
    if MemCompare(Item, Event, SizeOf(T)) then
      Exit(I)
    else
      Inc(I);
  Result := -1;
end;

{ TDelegateImpl<T>.IDelegate<T> }

function TDelegateImpl<T>.GetIsEmpty: Boolean;
begin
  Result := FList.IsEmpty;
end;

procedure TDelegateImpl<T>.Add(const Event: T);
var
  I: Integer;
begin
  I := IndexOf(Event);
  if I < 0 then
    FList.Push(Event);
end;

procedure TDelegateImpl<T>.Remove(const Event: T);
var
  I: Integer;
begin
  I := IndexOf(Event);
  if I > -1 then
    FList.Delete(I);
end;

{ TDelegateContainerImpl<T>.IDelegateContainer<T> }

function TDelegateContainerImpl<T>.GetDelegate: IDelegate<T>;
begin
  if FDelegate = nil then
  begin
    FDelegate := TDelegateImpl<T>.Create;
    FDelegateClass := FDelegate as TDelegateClass;
  end;
  Result := FDelegate;
end;

function TDelegateContainerImpl<T>.GetEnumerator: IEnumerator<T>;
begin
  GetDelegate;
  Result := FDelegateClass.FList.GetEnumerator;
end;

{ TDelegate<T> }

class operator TDelegate<T>.Implicit(var Delegate: TDelegate<T>): IDelegate<T>;
begin
  Result := Delegate.GetContainer.Delegate;
end;

function TDelegate<T>.GetContainer: IDelegateContainer<T>;
begin
  if FContainer = nil then
    FContainer := TDelegateContainer.Create;
  Result := FContainer;
end;

function TDelegate<T>.GetEnumerator: IEnumerator<T>;
begin
  if FContainer = nil then
    FContainer := TDelegateContainer.Create;
  Result := FContainer.GetEnumerator;
end;

function TDelegate<T>.GetIsEmpty: Boolean;
begin
  Result := GetContainer.Delegate.IsEmpty;
end;

procedure TDelegate<T>.Add(const Handler: T);
begin
  GetContainer.Delegate.Add(Handler);
end;

procedure TDelegate<T>.Remove(const Handler: T);
begin
  GetContainer.Delegate.Remove(Handler);
end;

{ TChangeNotifier }

function TChangeNotifier.GetOnChange: INotifyDelegate;
begin
  Result := FOnChange;
end;

procedure TChangeNotifier.Change;
var
  Event: TNotifyEvent;
begin
  for Event in FOnChange do
    Event(Self);
end;

{$endregion}

{$region classes}
{ TNullInfo }

function TNullInfo.Reset: TNullResult;
begin
  FCount := 0;
  InterLockedExchange(FBytes, 0);
  InterLockedExchange(FRate, 0);
  InterLockedExchange(FSeconds, 0);
  InterLockedExchange(FAvergage, 0);
  FTime := 0;
  FRateTime := 0;
  FRateBytes := 0;
  FAvergageTotal := 0;
  FAvergageCount := 0;
  Result := FResult.Items;
  FResult.Clear;
end;

{ TNullStream }

constructor TNullStream.Create;
begin
  inherited Create;
  FReadInfo := TNullInfo.Create;
  FWriteInfo := TNullInfo.Create;
end;

destructor TNullStream.Destroy;
begin
  FReadInfo.Free;
  FWriteInfo.Free;
  inherited Destroy;
end;

procedure TNullStream.SetSize(NewSize: Longint);
begin
  { Do nothing }
end;

procedure TNullStream.SetSize(const NewSize: Int64);
begin
  { Do nothing }
end;

procedure TNullStream.RecordInfo(Info: TNullInfo; Count: LongWord);
const
  Poll = 1 / 10;
  TwoPoll = Poll * 2;
var
  Time: Double;
  Compliment, Section: LongWord;
begin
  Time := TimeQuery;
  if Info.FTime = 0 then
  begin
    Info.FTime := Time;
    Info.FCount := Count;
    InterLockedExchange(Info.FBytes, Info.FCount);
  end
  else if Time - Info.FTime < 1 then
  begin
    Info.FCount += Count;
    InterLockedExchange(Info.FBytes, Info.FBytes + Info.FCount);
  end
  else if Time - Info.FTime < 2 then
  begin
    Info.FResult.Push(Info.FCount);
    Info.FCount := Count;
    InterLockedExchange(Info.FBytes, Info.FBytes + Info.FCount);
    InterLockedIncrement(Info.FSeconds);
    Info.FTime += 1;
  end
  else
  begin
    Info.Reset;
    Info.FTime := Time;
    Info.FCount := Count;
    InterLockedExchange(Info.FBytes, Info.FCount);
  end;
  if Info.FRateTime = 0 then
    Info.FRateTime := Time;
  Time := Time - Info.FRateTime;
  if Time <= Poll then
    Info.FRateBytes += Count
  else if Time < TwoPoll then
  begin
    Compliment := Round(Count * ((Time - Poll) / Time));
    Info.FRateBytes += Count - Compliment;
    Section := Round(Info.FRateBytes / Poll);
    InterLockedExchange(Info.FRate, Section);
    Info.FRateBytes := Compliment;
    Info.FRateTime += Poll;
    Info.FAvergageTotal += Section;
    Inc(Info.FAvergageCount);
    Section := Round(Info.FAvergageTotal / Info.FAvergageCount);
    InterLockedExchange(Info.FAvergage, Section);
  end
  else
  begin
    Info.FAvergageTotal += Info.FRateBytes + Count;
    while Time > Poll do
    begin
      Time -= Poll;
      Inc(Info.FAvergageCount);
      Info.FRateTime += Poll;
    end;
    Section := Round(Info.FAvergageTotal / Info.FAvergageCount);
    InterLockedExchange(Info.FAvergage, Section);
    InterLockedExchange(Info.FRate, 0);
    Info.FRateBytes := 0;
    Info.FRateTime := 0;
  end;
end;

function TNullStream.Read(var Buffer; Count: Longint): Longint;
begin
  if Count > 0 then
    RecordInfo(FReadInfo, Abs(Count));
  Result := Count;
end;

function TNullStream.Write(const Buffer; Count: Longint): Longint;
begin
  if Count > 0 then
    RecordInfo(FWriteInfo, Abs(Count));
  Result := Count;
end;

function TNullStream.Seek(const Offset: Int64; Origin: TSeekOrigin): Int64;
begin
  Result := 0;
end;
{$endregion}

{$region threading}

var
  SemaphoreInit: TSempahoreInitHandler;
  SemaphoreDestroy: TSemaphoreDestroyHandler;
  SemaphorePost: TSemaphorePostHandler;
  SemaphoreWait: TSemaphoreWaitHandler;

procedure ThreadsInit;
var
  M: TThreadManager;
begin
  GetThreadManager(M);
  SemaphoreInit := M.SemaphoreInit;
  SemaphoreDestroy := M.SemaphoreDestroy;
  SemaphorePost := M.SemaphorePost;
  SemaphoreWait := M.SemaphoreWait;
end;

{ TMutexObject }

type
  TMutexObject = class(TInterfacedObject, IMutex)
  private
    FSemaphore: Pointer;
    FCounter: Integer;
  public
    constructor Create;
    destructor Destroy; override;
    function Lock: LongInt;
    function Unlock: LongInt;
  end;

{ TEventObject }

  TEventObject = class(TInterfacedObject, IEvent)
  private
    FEvent: Pointer;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Reset;
    procedure Signal;
    procedure Wait;
  end;

constructor TMutexObject.Create;
begin
  inherited Create;
  if @SemaphoreInit = nil then
    ThreadsInit;
  FSemaphore := SemaphoreInit;
end;

destructor TMutexObject.Destroy;
begin
  SemaphoreDestroy(FSemaphore);
  inherited Destroy;
end;

function TMutexObject.Lock: LongInt;
begin
  Result := InterLockedIncrement(FCounter);
  if Result > 1 then
    SemaphoreWait(FSemaphore);
end;

function TMutexObject.Unlock: LongInt;
begin
  Result := InterLockedDecrement(FCounter);
  if Result > 0 then
    SemaphorePost(FSemaphore);
end;

constructor TEventObject.Create;
begin
  inherited Create;
  FEvent := RTLEventCreate;
end;

destructor TEventObject.Destroy;
begin
  RTLEventDestroy(FEvent);
  inherited Destroy;
end;

procedure TEventObject.Reset;
begin
  RTLEventResetEvent(FEvent);
end;

procedure TEventObject.Signal;
begin
  RTLEventSetEvent(FEvent);
end;

procedure TEventObject.Wait;
begin
  RTLEventWaitFor(FEvent);
end;

function MutexCreate: IMutex;
begin
  Result := TMutexObject.Create;;
end;

function EventCreate: IEvent;
begin
  Result := TEventObject.Create;
end;
{$endregion}

{$region waiting routines}
procedure PumpMessages;
begin
  if Assigned(PumpMessagesProc) then
    PumpMessagesProc;
end;
{$endregion}

function DefaultStringCompare(constref A, B: string): Integer;
begin
  Result := StrCompare(A, B);
end;

function DefaultStringConvertString(constref Item: string): string;
begin
  Result := Item;
end;

function DefaultIntCompare(constref A, B: Integer): Integer;
begin
  Result := B - A;
end;

function DefaultIntConvertString(constref Item: Integer): string;
begin
  Result := IntToStr(Item);
end;

function DefaultInt64Compare(constref A, B: Int64): Integer;
begin
  Result := B - A;
end;

function DefaultInt64ConvertString(constref Item: Int64): string;
begin
  Result := IntToStr(Item);
end;

function DefaultFloatCompare(constref A, B: Float): Integer;
begin
  if A < B then
    Result := -1
  else if A > B then
    Result := 1
  else
    Result := 0;
end;

function DefaultFloatConvertString(constref Item: Float): string;
begin
  Result := FloatToStr(Item);
end;

initialization
  @LibraryExceptproc := @LibraryExcept;
  StringArray.DefaultCompare := DefaultStringCompare;
  StringArray.DefaultConvertString := DefaultStringConvertString;
  IntArray.DefaultCompare := DefaultIntCompare;
  IntArray.DefaultConvertString := DefaultIntConvertString;
  Int64Array.DefaultCompare := DefaultInt64Compare;
  Int64Array.DefaultConvertString := DefaultInt64ConvertString;
  FloatArray.DefaultCompare := DefaultFloatCompare;
  FloatArray.DefaultConvertString := DefaultFloatConvertString;
end.
