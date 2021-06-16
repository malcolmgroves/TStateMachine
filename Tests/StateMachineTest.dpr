program StateMachineTest;
{

  Delphi DUnit Test Project
  -------------------------
  This project contains the DUnit test framework and the GUI/Console test runners.
  Add "CONSOLE_TESTRUNNER" to the conditional defines entry in the project options
  to use the console test runner.  Otherwise the GUI test runner will be used by
  default.

}

{$IFDEF CONSOLE_TESTRUNNER}
{$APPTYPE CONSOLE}
{$ENDIF}

uses
  Forms,
// Only one of the next two lines should be uncommented.
  DUnitTestRunner, // uncomment to use DUnit, or
//  TestInsight.Dunit, // uncomment to use TestInsight
  Generics.StateMachine in '..\source\Generics.StateMachine.pas',
  Generics.StateMachine.Test in 'Generics.StateMachine.Test.pas',
  Generics.StateMachine.Test.BugStates in 'Generics.StateMachine.Test.BugStates.pas',
  Generics.Nullable in '..\source\Generics.Nullable.pas';

{ R *.RES }

begin
  ReportMemoryLeaksOnShutdown := True;
  Application.Initialize;
  RunRegisteredTests;
end.
