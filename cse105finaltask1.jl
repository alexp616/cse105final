# File for Alex Pan's source code for Task 1 of CSE 105 FA24's final
# Aside some StackExchange + Julia forum lookups for basic things, 
# like how to declare a empty dict, no other resources were consulted
# Things implemented: DFA struct, string -> DFA, algorithm that 
# decides E_DFA

import Base.==
import Base.display
import Base.hash

mutable struct State
    name::String
    accepts::Bool
end

# For checking if in set
function Base.:(==)(x::State, y::State)
    return x.name == y.name
end

# Also for checking if in set
function Base.hash(x::State, h::UInt)
    return hash(x.name, h)
end

mutable struct DFA
    valid::Bool
    states::Set{State}
    alphabet::Set{String}
    # Dict to allow lookup and access.
    transitionFunction::Dict{Tuple{State, String}, State}
    startState::State
    acceptStates::Set{State}

    function DFA(s::String)
        notvalid() = throw("")

        states = Set{State}()
        alphabet = Set{String}()
        transitionFunction = Dict{Tuple{State, String}, State}()
        startState = State("", false)
        acceptStates = Set{State}()

        # Because efficiency isn't important, I just throw an error
        # whenever the input string isn't valid, and an invalid DFA object
        # is returned.
        try
            parts = String.(split(s, "|"))

            if length(parts) != 5 # not a 5-tuple
                notvalid()
            end

            stateNames = String.(split(parts[1], ","))
            symbols = String.(split(parts[2], ","))
            transitionFunctionStrs = String.(split(parts[3], ","))
            startStateStr = parts[4]
            acceptStateStrs = String.(split(parts[5], ","))

            # Getting states
            for stateName in stateNames
                # No duplicate states
                S = State(stateName, false)
                if S in states
                    notvalid()
                end
                push!(states, S)
            end

            # Getting symbols
            for symbol in symbols
                # No duplicate symbols
                if symbol in alphabet
                    notvalid()
                end
                push!(alphabet, symbol)
            end

            # Getting transition function
            for str in transitionFunctionStrs
                inStateName, symbol, outStateName = parse_transition_string(str)
                # Statenames in transition function not found
                inState = State(inStateName, false)
                outState = State(outStateName, false)
                if !(inState in states && outState in states)
                    notvalid()
                end
                if !(symbol in alphabet)
                    notvalid()
                end
                # Must be deterministic (only one output per input)
                if haskey(transitionFunction, (inState, symbol))
                    notvalid()
                end

                transitionFunction[(inState, symbol)] = outState
            end

            # Check to make sure is deterministic (every state has transition for all
            # symbols in alphabet)
            for state in states
                tempAlphabet = copy(alphabet)
                for transInput in keys(transitionFunction)
                    if transInput[1] == state
                        delete!(tempAlphabet, transInput[2])
                    end
                end
                if !isempty(tempAlphabet)
                    notvalid()
                end
            end

            # Getting start state
            startState = State(startStateStr, false)
            # Make sure startState is actually a state
            if !(startState in states)
                notvalid()
            end

            # Getting accept states
            for stateName in acceptStateStrs
                S = State(stateName, false)
                # Make sure accept state is a state
                if !(S in states)
                    notvalid()
                end
                # Make sure no duplicate accept states
                if State(stateName, true) in acceptStates
                    notvalid()
                end
                # Update accept value
                delete!(states, S)
                S.accepts = true
                push!(states, S)

                # Push to accept states
                push!(acceptStates, S)
            end

            return new(true, states, alphabet, transitionFunction, startState, acceptStates)
        catch e
            # Something errored, or not a valid DFA.
            return new(false, states, alphabet, transitionFunction, startState, acceptStates)
        end
    end
end

function parse_transition_string(s)
    idx1 = first(findfirst(";", s))
    idx2 = first(findfirst(">", s))
    
    state = s[1:idx1 - 1]
    symbol = s[idx1 + 1:idx2 - 1]
    outputState = s[idx2 + 1:end]

    return state, symbol, outputState
end

# For debugging purposes
function display(dfa::DFA)
    if !dfa.valid 
        println("invalid dfa")
        return
    end

    println("States: ")
    for state in dfa.states
        println("  $(state.name)")
    end
    println()

    println("Symbols: ")
    for symbol in dfa.alphabet
        println("  $symbol")
    end
    println()
    
    println("Transitions: ")
    for transition in keys(dfa.transitionFunction)
        println("  $(transition[1].name), $(transition[2]) → $(dfa.transitionFunction[transition].name)")
    end
    println()

    println("Start state: ")
    println("  $(dfa.startState.name)")
    println()

    println("Accept states: ")
    for state in dfa.acceptStates
        println("  $(state.name)")
    end

    return 
end

function in_E_DFA(str::String)
    dfa = DFA(str)
    # Type check
    if !(dfa.valid)
        println("Invalid DFA!")
        return false
    end

    markedStates = Set{State}()
    
    # Mark start state
    push!(markedStates, dfa.startState)
    newStateMarked = true

    while newStateMarked
        # For each state S
        newStateMarked = false
        for S in dfa.states
            # If S is already marked, ignore
            if !(S in markedStates)
                # Go through all transition functions
                for input in keys(dfa.transitionFunction)
                    # If output is S and input state is marked, mark S.
                    if dfa.transitionFunction[input] == S && input[1] in markedStates
                        push!(markedStates, S)
                        newStateMarked = true
                        break
                    end
                end
            end
        end
    end

    if isempty(intersect(markedStates, dfa.acceptStates))
        return true
    else
        return false
    end
end

# All of these are explained in write-up
function test1()
    D1 = "q0,q1,q2|0,1|q0;1>q1,q1;0>q1,q0;0>q2,q2;0>q2,q2;1>q2,q1;1>q2|q0|q1"
    println(in_E_DFA(D1))
end

function test2()
    D2 = "q0,q1,q2|0,1|q0;0>q1,q0;1>q1,q1;0>q0,q1;1>q0,q2;0>q2,q2;1>q2|q0|q2"
    println(in_E_DFA(D2))
end

function test3()
    D3 = "q0,q1,q2|0,1,2|q0;0>q1,q0;1>q1,q1;0>q0,q1;1>q0,q2;0>q2,q2;1>q2|q0|q2"
    println(in_E_DFA(D3))
end