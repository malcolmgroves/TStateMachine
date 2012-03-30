{***************************************************************************}
{                                                                           }
{           Generics.Nullable                                               }
{                                                                           }
{           Copyright (C) Malcolm Groves                                    }
{                                                                           }
{           http://www.malcolmgroves.com                                    }
{                                                                           }
{                                                                           }
{***************************************************************************}
{                                                                           }
{  Licensed under the Apache License, Version 2.0 (the "License");          }
{  you may not use this file except in compliance with the License.         }
{  You may obtain a copy of the License at                                  }
{                                                                           }
{      http://www.apache.org/licenses/LICENSE-2.0                           }
{                                                                           }
{  Unless required by applicable law or agreed to in writing, software      }
{  distributed under the License is distributed on an "AS IS" BASIS,        }
{  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. }
{  See the License for the specific language governing permissions and      }
{  limitations under the License.                                           }
{                                                                           }
{***************************************************************************}

unit Generics.Nullable;

// based VERY heavily on code written by Allen Bauer and posted on his blog at
// http://blogs.embarcadero.com/abauer/2008/09/18/38869

interface

uses Generics.Defaults, SysUtils;

type
  TNullable<T> = record
  private
    FValue: T;
    FHasValue: IInterface;
    function GetValue: T;
    function GetHasValue: Boolean;
  public
    constructor Create(AValue: T);
    function GetValueOrDefault: T; overload;
    function GetValueOrDefault(Default: T): T; overload;
    property HasValue: Boolean read GetHasValue;
    property Value: T read GetValue;

    class operator NotEqual(ALeft, ARight: TNullable<T>): Boolean;
    class operator Equal(ALeft, ARight: TNullable<T>): Boolean;

    class operator Implicit(Value: TNullable<T>): T;
    class operator Implicit(Value: T): TNullable<T>;
    class operator Explicit(Value: TNullable<T>): T;
  end;

procedure SetFlagInterface(var Intf: IInterface);


implementation

  function NopAddref(inst: Pointer): Integer; stdcall;
  begin
    Result := -1;
  end;

  function NopRelease(inst: Pointer): Integer; stdcall;
  begin
    Result := -1;
  end;

  function NopQueryInterface(inst: Pointer; const IID: TGUID; out Obj)
    : HResult; stdcall;
  begin
    Result := E_NOINTERFACE;
  end;

procedure SetFlagInterface(var Intf: IInterface);
const
  FlagInterfaceVTable: array [0 .. 2] of Pointer = (@NopQueryInterface,
                                                    @NopAddref,
                                                    @NopRelease);
  FlagInterfaceInstance: Pointer = @FlagInterfaceVTable;

begin
  Intf := IInterface(@FlagInterfaceInstance);
end;

{ Nullable<T> }

constructor TNullable<T>.Create(AValue: T);
begin
  FValue := AValue;
  SetFlagInterface(FHasValue);
end;

class operator TNullable<T>.Equal(ALeft, ARight: TNullable<T>): Boolean;
var
  Comparer: IEqualityComparer<T>;
begin
  if ALeft.HasValue and ARight.HasValue then
  begin
    Comparer := TEqualityComparer<T>.Default;
    Result := Comparer.Equals(ALeft.Value, ARight.Value);
  end
  else
    Result := ALeft.HasValue = ARight.HasValue;
end;

class operator TNullable<T>.Explicit(Value: TNullable<T>): T;
begin
  Result := Value.Value;
end;

function TNullable<T>.GetHasValue: Boolean;
begin
  Result := FHasValue <> nil;
end;

function TNullable<T>.GetValue: T;
begin
  if not HasValue then
    raise Exception.Create('Invalid operation, Nullable type has no value');
  Result := FValue;
end;

function TNullable<T>.GetValueOrDefault: T;
begin
  if HasValue then
    Result := FValue
  else
    Result := Default (T);
end;

function TNullable<T>.GetValueOrDefault(Default: T): T;
begin
  if not HasValue then
    Result := Default
  else
    Result := FValue;
end;

class operator TNullable<T>.Implicit(Value: TNullable<T>): T;
begin
  Result := Value.Value;
end;

class operator TNullable<T>.Implicit(Value: T): TNullable<T>;
begin
  Result := TNullable<T>.Create(Value);
end;

class operator TNullable<T>.NotEqual(ALeft, ARight: TNullable<T>): Boolean;
var
  Comparer: IEqualityComparer<T>;
begin
  if ALeft.HasValue and ARight.HasValue then
  begin
    Comparer := TEqualityComparer<T>.Default;
    Result := not Comparer.Equals(ALeft.Value, ARight.Value);
  end
  else
    Result := ALeft.HasValue <> ARight.HasValue;
end;

end.
