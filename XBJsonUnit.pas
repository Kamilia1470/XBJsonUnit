unit XBJsonUnit;

interface

uses System.Classes,IdHTTP,JSon,FMX.Dialogs,
     REST.Response.Adapter, REST.Client,
     Data.Bind.Components, Data.Bind.ObjectScope,
     Datasnap.DBClient
     ,IPPeerClient //不USE 可以過 但會跳一個很奇怪的錯誤 (要拉REST元件 才會自動USE這個)
     ;

type
  TRestJsonCDS=class(TClientDataSet)
    RESTClient: TRESTClient;
    RESTRequest: TRESTRequest;
    RESTResponse: TRESTResponse;
    RESTResponseDataSetAdapter: TRESTResponseDataSetAdapter;
  public
    constructor Create(AOwner: TComponent;BaseURL:String;ParaTs:TStrings=nil); overload;
    constructor Create(AOwner: TComponent;BaseURL:String;ParaStr:array of String); overload;
    destructor destroy; override;
  end;

function GetPostReturn(URL:string;ParaTs:TStrings;var ReturnStr:String):Boolean; overload;
function GetPostReturn(URL:string;ParaTs:TStrings):string; overload;

function GetXBJson(BaseUrl,MainFunctionName,SubFunctionName:string;ParaTs:TStrings):string; overload;
function GetXBJson(BaseUrl,MainFunctionName,SubFunctionName:string;ParaStr:array of String):string; overload;

function GetXBJSonCDS(BaseURL,MainFunctionName,SubFunctionName:string;ParaTs:TStrings=nil):TRestJsonCDS; overload; //此函數將自動產生一個CDS 需自行釋放
function GetXBJSonCDS(BaseURL,MainFunctionName,SubFunctionName:string;ParaStr:array of String):TRestJsonCDS; overload; //此函數將自動產生一個CDS 需自行釋放

function GetXBJsonOneField(BaseURL,MainFunctionName,SubFunctionName:string;ParaStr:array of String;FieldName:String):string;

Const EmptyRecord=''; //當CDS為完全空值時回傳此字串 未來有可能會回傳空字串時可以修改這裡 以區分空值跟空DB

implementation

uses REST.Types;

function GetFullURL(BaseUrl,MainFunctionName,SubFunctionName:string):String;
begin
  result:= BaseUrl+'/'+MainFunctionName+'/'+SubFunctionName;
end;

function GetPostReturn(URL:string;ParaTs:TStrings;var ReturnStr:String):Boolean;
var idhttp:TIdHttp;
begin
  Result:=True;
  ReturnStr:='';
  idhttp:=TIdHttp.Create(nil);
  try
    try
      showmessage('URL>>'+URL+#13+ParaTs.Text);
      ReturnStr:=IdHTTP.Post(URL,ParaTs);
    except
      Result:=False;
    end;
  finally
    idhttp.Free;
  end;
end;

function GetPostReturn(URL:string;ParaTs:TStrings):string; overload;
begin
  //ShowMessage('GetPostReturn URL >> '+URL);
  GetPostReturn(URL,ParaTs,Result);
end;

function GetXBJson(BaseUrl,MainFunctionName,SubFunctionName:string;ParaTs:TStrings):string;
begin
  Result:=GetPostReturn(GetFullURL(BaseUrl,MainFunctionName,SubFunctionName),ParaTs);
end;

//ParaStr 省去TStrings的麻煩 但一定要 Name Value Name Value 若Length為奇數 則 取消 返回
function GetXBJson(BaseUrl,MainFunctionName,SubFunctionName:string;ParaStr:array of String):string;
var ts:TStrings;
  I: Integer;
begin
  if Length(ParaStr) mod 2 = 1 then
  begin
    Showmessage('ParaStr Error');
    Exit;
  end;
  ts:=TStringList.Create;
  try
    for I := 0 to (Length(ParaStr) div 2)-1 do
      ts.Values[ParaStr[i*2]]:=ParaStr[i*2+1];
    //ShowMessage(ts.Text);
    Result:=GetXBJson(BaseUrl,MainFunctionName,SubFunctionName,ts);
  finally
    ts.Free;
  end;
end;

function GetXBJSonCDS(BaseURL,MainFunctionName,SubFunctionName:string;ParaTs:TStrings):TRestJsonCDS; //此函數將自動產生一個CDS 需自行釋放
begin
  Result:=TRestJsonCDS.Create(nil,GetFullURL(BaseURL,MainFunctionName,SubFunctionName),ParaTS);
end;

function GetXBJSonCDS(BaseURL,MainFunctionName,SubFunctionName:string;ParaStr:array of String):TRestJsonCDS; overload; //此函數將自動產生一個CDS 需自行釋放
var ts:TStrings;
  I: Integer;
begin
  if Length(ParaStr) mod 2 = 1 then
  begin
    Showmessage('ParaStr Error');
    Exit;
  end;
  ts:=TStringList.Create;
  try
    for I := 0 to (Length(ParaStr) div 2)-1 do
      ts.Values[ParaStr[i*2]]:=ParaStr[i*2+1];
    //ShowMessage(ts.Text);
    Result:=GetXBJSonCDS(BaseUrl,MainFunctionName,SubFunctionName,ts);
  finally
    ts.Free;
  end;
end;

function GetXBJsonOneField(BaseURL,MainFunctionName,SubFunctionName:string;ParaStr:array of String;FieldName:String):string;
begin
  with GetXBJSonCDS(BaseURL,MainFunctionName,SubFunctionName,ParaStr) do
  begin
    if FindField(FieldName)<>nil then
      Result:=FieldByName(FieldName).AsString
    else
    begin
      //ShowMessage('Field Not Found!');
      Result:=EmptyRecord;
    end;
    Free;
  end;
end;

{ TRestJsonCDS }

constructor TRestJsonCDS.Create(AOwner: TComponent;BaseURL:String;ParaTs:TStrings=nil);
var i:integer;
begin
  inherited Create(AOwner);
  RESTClient:=TRESTClient.Create(Self);
  RESTRequest:=TRESTRequest.Create(Self);
  RESTResponse:=TRESTResponse.Create(Self);
  RESTResponseDataSetAdapter:=TRESTResponseDataSetAdapter.Create(Self);

  RESTRequest.Client:=RESTClient;
  RESTRequest.Response:=RESTResponse;

  RESTResponseDataSetAdapter.Response:=RESTResponse;
  RESTResponseDataSetAdapter.Dataset:=Self;

  RESTClient.BaseURL:=BaseURL;

  if ParaTs<>nil then
  begin
    RESTRequest.Method := rmPOST;
    for I := 0 to ParaTs.Count-1 do
      RESTRequest.Params.AddItem(ParaTs.Names[i],ParaTs.ValueFromIndex[i]);
  end;

  RESTRequest.Execute;
end;

constructor TRestJsonCDS.Create(AOwner: TComponent; BaseURL: String;
  ParaStr: array of String);
var ts:TStrings;
  I: Integer;
begin
  if Length(ParaStr) mod 2 = 1 then
  begin
    Showmessage('ParaStr Error');
    Exit;
  end;
  ts:=TStringList.Create;
  try
    for I := 0 to (Length(ParaStr) div 2)-1 do
      ts.Values[ParaStr[i*2]]:=ParaStr[i*2+1];
    //ShowMessage(ts.Text);
    inherited Create(AOwner);
    RESTClient:=TRESTClient.Create(Self);
    RESTRequest:=TRESTRequest.Create(Self);
    RESTResponse:=TRESTResponse.Create(Self);
    RESTResponseDataSetAdapter:=TRESTResponseDataSetAdapter.Create(Self);

    RESTRequest.Client:=RESTClient;
    RESTRequest.Response:=RESTResponse;

    RESTResponseDataSetAdapter.Response:=RESTResponse;
    RESTResponseDataSetAdapter.Dataset:=Self;

    RESTClient.BaseURL:=BaseURL;

    RESTRequest.Method := rmPOST;
    for I := 0 to ts.Count-1 do
      RESTRequest.Params.AddItem(ts.Names[i],ts.ValueFromIndex[i]);

    RESTRequest.Execute;
  finally
    ts.Free;
  end;
end;

destructor TRestJsonCDS.destroy;
begin
  RESTResponseDataSetAdapter.Free;
  RESTResponse.Free;
  RESTRequest.Free;
  RESTClient.Free;
  inherited destroy;
end;

end.
