{***************************************************************************}
{                                                                           }
{           Generics.StateMachine                                           }
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

unit Generics.StateMachine;

interface

uses
  System.SysUtils, Generics.Collections, Generics.Nullable;

type
  EStateMachineException = class(Exception);
  EGuardFailure = class(EStateMachineException);
  EUnknownTrigger = class(EStateMachineException);
  EUnknownState = class(EStateMachineException);
  EInvalidStateMachine = class(EStateMachineException);

  TGuardProc<TTrigger> = reference to function(Trigger : TTrigger): boolean;
  TTransitionProc = reference to procedure;

  TTriggerHolder<TState, TTrigger> = class
  strict private
    FTrigger: TTrigger;
    FDestination: TState;
    FGuard: TGuardProc<TTrigger>;
  public
    constructor Create(ATrigger: TTrigger; ADestination: TState;
      AGuard: TGuardProc<TTrigger> = nil); virtual;
    function CanExecute: boolean;
    property Destination: TState read FDestination;
  end;

  TStateMachine<TState, TTrigger> = class;

  TTStateHolder<TState, TTrigger> = class
  strict private
    FTriggers: TObjectDictionary<TTrigger, TTriggerHolder<TState, TTrigger>>;
    FState: TState;
    FStateMachine: TStateMachine<TState, TTrigger>;
    FOnEntry: TTransitionProc;
    FOnExit: TTransitionProc;
    function GetTriggerCount: Integer;
  protected
    procedure Enter;
    procedure Exit;
  public
    constructor Create(AStateMachine: TStateMachine<TState, TTrigger>;
      AState: TState); virtual;
    destructor Destroy; override;
    function Destinations : TList<TState>;
    function Trigger(ATrigger: TTrigger; ADestination: TState;
      AGuard: TGuardProc<TTrigger> = nil): TTStateHolder<TState, TTrigger>;
    function OnEntry(AOnEntry: TTransitionProc)
      : TTStateHolder<TState, TTrigger>;
    function OnExit(AOnExit: TTransitionProc)
      : TTStateHolder<TState, TTrigger>;
    function Initial: TTStateHolder<TState, TTrigger>;
    procedure Execute(ATrigger: TTrigger);
    function TriggerExists(ATrigger: TTrigger) : boolean;
    property TriggerCount: Integer read GetTriggerCount;
    property State: TState read FState;
  end;

  /// <summary>
  /// TStateMachine is a simple state machine that uses generic types to
  /// specify the different possible states and also the triggers that
  /// transition between the states.
  /// </summary>
  /// <typeparam name="TState">
  /// The type you wish to use to specify the different possible states of
  /// your state machine.
  /// </typeparam>
  /// <typeparam name="TTrigger">
  /// The type you wish to use to specify the different triggers in your
  /// state machine. A trigger is how you tell the state machine to
  /// transition from one state to another.
  /// </typeparam>
  TStateMachine<TState, TTrigger> = class
  strict private
    FStates: TObjectDictionary<TState, TTStateHolder<TState, TTrigger>>;
    FCurrentState: TState;
    FInitialState: TNullable<TState>;
    FActive: boolean;
    function GetStateCount: Integer;
    procedure SetActive(const Value: boolean);
    function GetInitialState: TTStateHolder<TState, TTrigger>;
    function GetCurrentState: TTStateHolder<TState, TTrigger>;
  protected
    procedure TransitionToState(const AState: TState;
      AFirstTime: boolean = False);
    procedure SetInitialState(const AState: TState);
  public
    constructor Create; virtual;
    destructor Destroy; override;
    /// <summary>
    /// Add a new state to the state machine.
    /// </summary>
    /// <param name="AState">
    /// The state you wish to have added.
    /// </param>
    /// <returns>
    /// Returns a TTStateCaddy for the state specified in the AState
    /// parameter.
    /// </returns>
    function State(AState: TState): TTStateHolder<TState, TTrigger>;
    procedure Validate;
    property StateCount: Integer read GetStateCount;
    property CurrentState: TTStateHolder<TState, TTrigger>
      read GetCurrentState;
    property InitialState: TTStateHolder<TState, TTrigger>
      read GetInitialState;
    property Active: boolean read FActive write SetActive;
  end;

implementation

{ TTriggerCaddy<TState, TTrigger> }

function TTriggerHolder<TState, TTrigger>.CanExecute: boolean;
begin
  if Assigned(FGuard) then
    Result := FGuard(FTrigger)
  else
    Result := True;
end;

constructor TTriggerHolder<TState, TTrigger>.Create(ATrigger: TTrigger;
  ADestination: TState; AGuard: TGuardProc<TTrigger>);
begin
  inherited Create;
  FTrigger := ATrigger;
  FDestination := ADestination;
  FGuard := AGuard;
end;

{ TTStateCaddy<TState, TTrigger> }

function TTStateHolder<TState, TTrigger>.Trigger(ATrigger: TTrigger;
  ADestination: TState; AGuard: TGuardProc<TTrigger>): TTStateHolder<TState, TTrigger>;
var
  LConfiguredTrigger: TTriggerHolder<TState, TTrigger>;
begin
  LConfiguredTrigger := TTriggerHolder<TState, TTrigger>.Create(ATrigger,
    ADestination, AGuard);
  FTriggers.Add(ATrigger, LConfiguredTrigger);
  Result := self;
end;

constructor TTStateHolder<TState, TTrigger>.Create(AStateMachine
  : TStateMachine<TState, TTrigger>; AState: TState);
begin
  inherited Create;
  FStateMachine := AStateMachine;
  FTriggers := TObjectDictionary < TTrigger, TTriggerHolder < TState,
    TTrigger >>.Create([doOwnsValues]);
  FState := AState;
end;

function TTStateHolder<TState, TTrigger>.Destinations: TList<TState>;
var
  LTriggerHolder: TTriggerHolder<TState, TTrigger>;
begin
  Result := TList<TState>.Create;
  for LTriggerHolder in FTriggers.Values do
    Result.Add(LTriggerHolder.Destination);
end;

destructor TTStateHolder<TState, TTrigger>.Destroy;
begin
  FreeAndNil(FTriggers);
  inherited;
end;

procedure TTStateHolder<TState, TTrigger>.Enter;
begin
  if Assigned(FOnEntry) then
    FOnEntry;
end;

procedure TTStateHolder<TState, TTrigger>.Execute(ATrigger: TTrigger);
var
  LTrigger: TTriggerHolder<TState, TTrigger>;
begin
  if not FStateMachine.Active then
    raise EStateMachineException.Create('StateMachine not active');

  if not FTriggers.TryGetValue(ATrigger, LTrigger) then
    raise EUnknownTrigger.Create('Requested Trigger not found');

  if not LTrigger.CanExecute then
    raise EGuardFailure.Create('Guard on trigger prevented execution');

  FStateMachine.TransitionToState(LTrigger.Destination);
end;

procedure TTStateHolder<TState, TTrigger>.Exit;
begin
  if not FStateMachine.Active then
    raise EStateMachineException.Create('StateMachine not active');

  if Assigned(FOnExit) then
    FOnExit;
end;

function TTStateHolder<TState, TTrigger>.GetTriggerCount: Integer;
begin
  if Assigned(FTriggers) then
    Result := FTriggers.Count;
end;

function TTStateHolder<TState, TTrigger>.Initial
  : TTStateHolder<TState, TTrigger>;
begin
  FStateMachine.SetInitialState(FState);
  Result := self;
end;

function TTStateHolder<TState, TTrigger>.TriggerExists(
  ATrigger: TTrigger): boolean;
var
  LTrigger: TTriggerHolder<TState, TTrigger>;
begin
  Result := FTriggers.TryGetValue(ATrigger, LTrigger);
end;

function TTStateHolder<TState, TTrigger>.OnEntry(AOnEntry: TTransitionProc)
  : TTStateHolder<TState, TTrigger>;
begin
  FOnEntry := AOnEntry;
  Result := self;
end;

function TTStateHolder<TState, TTrigger>.OnExit(AOnExit: TTransitionProc)
  : TTStateHolder<TState, TTrigger>;
begin
  FOnExit := AOnExit;
  Result := self;
end;

constructor TStateMachine<TState, TTrigger>.Create;
begin
  inherited Create;
  FStates := TObjectDictionary <TState, TTStateHolder<TState, TTrigger>>.Create([doOwnsValues]);
end;

destructor TStateMachine<TState, TTrigger>.Destroy;
begin
  FStates.Free;
  inherited;
end;

function TStateMachine<TState, TTrigger>.GetCurrentState
  : TTStateHolder<TState, TTrigger>;
var
  LCurrentState: TTStateHolder<TState, TTrigger>;
begin
  if not FStates.TryGetValue(FCurrentState, LCurrentState) then
    raise EUnknownState.Create('Unable to find Current State');

  Result := LCurrentState;
end;

function TStateMachine<TState, TTrigger>.GetInitialState
  : TTStateHolder<TState, TTrigger>;
var
  LInitialState: TTStateHolder<TState, TTrigger>;
begin
  if not FInitialState.HasValue then
    raise EInvalidStateMachine.Create('StateMachine has no initial state');

  if not FStates.TryGetValue(FInitialState, LInitialState) then
    raise EUnknownState.Create('Unable to find Initial State');

  Result := LInitialState;
end;

function TStateMachine<TState, TTrigger>.GetStateCount: Integer;
begin
  if Assigned(FStates) then
    Result := FStates.Count;
end;

procedure TStateMachine<TState, TTrigger>.SetActive(const Value: boolean);
begin
  if FActive <> Value then
  begin
    if Value and not FInitialState.HasValue then
      raise EInvalidStateMachine.Create('StateMachine has no initial state specified');

    FActive := Value;
    if FActive then
      TransitionToState(FInitialState, True);
  end;
end;

procedure TStateMachine<TState, TTrigger>.SetInitialState(const AState: TState);
begin
  if FInitialState.HasValue then
    raise EInvalidStateMachine.Create('StatMachine cannot have two Initial States');

  FInitialState := AState;
end;

procedure TStateMachine<TState, TTrigger>.TransitionToState
  (const AState: TState; AFirstTime: boolean);
begin
  if not Active then
    raise EStateMachineException.Create('StateMachine not active');

  if not FStates.ContainsKey(AState) then
    raise EUnknownState.Create('Unable to find Configured State');

  // only exit if not the first transition to initial state
  if not AFirstTime then
    CurrentState.Exit;

  FCurrentState := AState;

  CurrentState.Enter;
end;

procedure TStateMachine<TState, TTrigger>.Validate;
var
  LUnreachableStates : TList<TState>;
  LStateHolder, LInitialState : TTStateHolder<TState, TTrigger>;
  LState: TState;
  LDestinations : TList<TState>;
  LValid : boolean;
begin
  // State Machine has initial state?
  LInitialState := InitialState;
  // all states are reachable?
  LUnreachableStates := TList<TState>.Create;
  try
    // fill all states
    for LState in FStates.Keys do
    begin
      LUnreachableStates.Add(LState);
    end;
    // remove initial state, as it is valid to have an initial state with
    // no incoming trigger
    LUnreachableStates.Remove(InitialState.State);
    // remove those which are destinations of triggers
    for LStateHolder in FStates.Values do
    begin
      LDestinations := LStateHolder.Destinations;
      try
        for LState in LDestinations do
          LUnreachableStates.Remove(LState);
      finally
        LDestinations.Free;
      end;
    end;
    if LUnreachableStates.Count > 0 then
    begin
      LValid := False;
      // would be nice to include the states in the message, however will need to
      // research generic way to convert TState to string
      raise EInvalidStateMachine.Create(Format('State Machine has %d unreachable state(s)', [LUnreachableStates.Count]));
    end;
  finally
    LUnreachableStates.Free;
  end;

end;

function TStateMachine<TState, TTrigger>.State(AState: TState)
  : TTStateHolder<TState, TTrigger>;
begin
  Result := TTStateHolder<TState, TTrigger>.Create(self, AState);
  FStates.Add(AState, Result);
end;

end.
