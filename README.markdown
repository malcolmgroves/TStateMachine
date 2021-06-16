What is TStateMachine?
======================
TStateMachine is a framework for declaring and running state machines in Delphi. It supports generic types for states and triggers, anonymous methods for Guards and Effects (State.OnEntry? and State.OnExit?), and a Fluid interface for configuring the State Machine.

What does all that mean?
------------------------
If you have an object that can be in multiple different states, with rules that determine when it can move between those states, and things that should happen when it changes state, you typically have a few choices:

1. Try to model it all correctly using a bunch of different boolean fields.
2. Follow the State Machine design pattern, define a base State and make descendants for each state with trigger methods between them.

For a trivial statemachine, use 1) and move on with your life.

For a non-trivial statemachine, 1) becomes a complex nightmare very quickly, and 2) not only takes too long but also makes it difficult to see in one place the full configuration of your states.

TStateMachine gives you a third option: Configure the framework to run the state machine for you.

Example
-------
For example, the following state diagram represents the different states of a Bug Report, along with the Triggers to move between states:

![bug states](http://www.malcolmgroves.com/images/googlecode/bugstates.png)

That same state diagram configured to run in TStateMachine looks like:

    TBugStates = (New, Assigned, Reproduced, Fixed, Tested, Released, Returned, Withdrawn);
    TBugTriggers = (Assign, Reproduce, Return, Update, Cancel, Fix, Test, Release, Withdraw, Reject);
 
    FBugState := TStateMachine<TBugStates, TBugTriggers>.Create;
    FBugState.State(TBugStates.New)
               .Initial
               .Trigger(TBugTriggers.Assign, TBugStates.Assigned)
               .Trigger(TBugTriggers.Withdraw, TBugStates.Withdrawn);
    FBugState.State(TBugStates.Assigned)
               .Trigger(TBugTriggers.Reproduce, TBugStates.Reproduced)
               .Trigger(TBugTriggers.Return, TBugStates.Returned)
               .Trigger(TBugTriggers.Reject, TBugStates.New);
    FBugState.State(TBugStates.Reproduced)
               .Trigger(TBugTriggers.Fix, TBugStates.Fixed);
    FBugState.State(TBugStates.Returned)
               .Trigger(TBugTriggers.Update, TBugStates.New)
               .Trigger(TBugTriggers.Withdraw, TBugStates.Withdrawn);
    FBugState.State(TBugStates.Fixed)
               .Trigger(TBugTriggers.Test, TBugStates.Tested)
               .Trigger(TBugTriggers.Return, TBugStates.Assigned);
    FBugState.State(TBugStates.Tested)
               .Trigger(TBugTriggers.Release, TBugStates.Released);
    FBugState.State(TBugStates.Released);
    FBugState.State(TBugStates.Withdrawn);
   
    FBugState.Validate;
    FBugState.Active := True;

TODO
----
More xmldoc, demos, the usual

Credits
-------
TStateMachine owes an obvious debt to the [Stateless project](http://code.google.com/p/stateless/). I was partway through implementing TStateMachine when I came across Stateless, and it definitely influenced the direction from that point on.
