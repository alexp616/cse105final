# File for Alex Pan's source code for Task 2 of CSE 105 FA24's final
# Aside from StackExchange + Julia forum lookups for basic things, 
# like how to initialize an object outside the class definition.


mutable struct TuringMachine
    valid::Bool
    states::Set{String}
    inputAlphabet::Set{String}
    tapeAlphabet::Set{String}
    transitionFunction::Dict{Tuple{String, String}, Tuple{String, String, String}}
    startState::String
    acceptState::String
    rejectState::String

    # need this
    function TuringMachine(a, b, c, d, e, f, g, h)
        return new(a, b, c, d, e, f, g, h)
    end

    function TuringMachine(s::String)
        notvalid() = throw("")

        states = Set{String}()
        inputAlphabet = Set{String}()
        tapeAlphabet = Set{String}()
        transitionFunction = Dict{Tuple{String, String}, Tuple{String, String, String}}()
        startState = ""
        acceptState = ""
        rejectState = ""

        try
            parts = String.(split(s, "|"))

            if length(parts) != 7 # not a 7-tuple, I force a reject state
                notvalid()
            end

            stateNames = String.(split(parts[1], ","))
            inputSymbols = String.(split(parts[2], ","))
            tapeSymbols = String.(split(parts[3], ","))
            transitionFunctionStrs = String.(split(parts[4], ","))
            startStateStr = parts[5]
            acceptStateStr = parts[6]
            rejectStateStr = parts[7]

            # Getting states
            for stateName in stateNames
                # No duplicate states
                if stateName in states
                    notvalid()
                end
                push!(states, stateName)
            end

            # Getting input alphabet
            for symbol in inputSymbols
                # No duplicates, and can't be blank
                if symbol in inputAlphabet || symbol == "_"
                    notvalid()
                end
                push!(inputAlphabet, symbol)
            end

            for symbol in tapeSymbols
                # No duplicates
                if symbol in tapeAlphabet
                    notvalid()
                end
                push!(tapeAlphabet, symbol)
            end
            # Tape alphabet must contain blank
            if !("_" in tapeAlphabet)
                notvalid()
            end
            # Input alphabet must be subset of tape alphabet
            if !issubset(inputAlphabet, tapeAlphabet)
                notvalid()
            end

            # Getting transition function
            for str in transitionFunctionStrs
                inStateName, inTapeSymbol, outStateName, outTapeSymbol, direction = parse_transition_string(str)

                # States actually exist
                if !(inStateName in states && outStateName in states)
                    notvalid()
                end
                # Tape symbols actually exist
                if !(inTapeSymbol in tapeAlphabet && outTapeSymbol in tapeAlphabet)
                    notvalid()
                end
                # Direction is left or right
                if !(direction == "R" || direction == "L")
                    notvalid()
                end

                # Deterministic
                if haskey(transitionFunction, (inStateName, inTapeSymbol))
                    notvalid()
                end

                transitionFunction[(inStateName, inTapeSymbol)] = (outStateName, outTapeSymbol, direction)
            end

            # Check if start, accept, and reject states
            # are actually states
            startState = startStateStr
            if !(startState in states)
                notvalid()
            end

            acceptState = acceptStateStr
            if !(acceptState in states)
                notvalid()
            end

            # Also make sure rejectState != acceptState
            rejectState = rejectStateStr
            if !(rejectState in states) || rejectState == acceptState
                notvalid()
            end
            
            return new(true, states, inputAlphabet, tapeAlphabet, transitionFunction, startState, acceptState, rejectState)
        catch
            return new(false, states, inputAlphabet, tapeAlphabet, transitionFunction, startState, acceptState, rejectState)
        end
        
    end
end

function parse_transition_string(s::String)
    parts = split(s, ";")
    # f((q, a)) = (r, b, L)
    if length(parts) != 5
        throw("")
    end

    q = parts[1]
    a = parts[2]
    r = parts[3]
    b = parts[4]
    l = parts[5]

    return q, a, r, b, l
end

function string(tm::TuringMachine)
    if !tm.valid
        return "Not a valid TM"
    end

    statesStr = join(tm.states, ",")
    inputAlphabetStr = join(tm.inputAlphabet, ",")
    tapeAlphabetStr = join(tm.tapeAlphabet, ",")
    # some code golf
    transitionFunctionStr = join(["$a;$b;$(join(tm.transitionFunction[a, b], ";"))" for (a, b) in keys(tm.transitionFunction)], ",")
    startStateStr = tm.startState
    acceptStateStr = tm.acceptState
    rejectStateStr = tm.rejectState

    return join([
        statesStr,
        inputAlphabetStr,
        tapeAlphabetStr,
        transitionFunctionStr,
        startStateStr,
        acceptStateStr,
        rejectStateStr
        ], "|")
end

function f(s::String)
    NOT_IN_STRING = "qacc,qrej|0|0,_||qrej|qacc|qrej/qacc,qrej|0|0,_||qrej|qacc|qrej"

    # Parsing input string into <M> and w
    parts = String.(split(s, "/"))
    # Invalid inputs are sent to string in EQ_TM
    if length(parts) != 2
        return NOT_IN_STRING
    end
    M = TuringMachine(parts[1])
    w = parts[2]

    if !(M.valid)
        return NOT_IN_STRING
    end

    # Machine that rejects every input
    M1 = TuringMachine(
        true,
        Set(["qacc,qrej"]),
        M.inputAlphabet,
        M.tapeAlphabet,
        Dict{Tuple{String, String}, Tuple{String, String, String}}(),
        "qrej",
        "qacc",
        "qrej"
    )

    # Machine that ignores whatever its input is, 
    # and runs M on w. Start by making a copy of M
    M2 = TuringMachine(
        true,
        copy(M.states),
        copy(M.inputAlphabet),
        copy(M.tapeAlphabet),
        copy(M.transitionFunction),
        M.startState,
        M.acceptState,
        M.rejectState
    )

    # Add a state that erases the tape
    push!(M2.states, "qerase")
    M2.startState = "qerase"
    for symbol in M2.inputAlphabet
        M2.transitionFunction[("qerase", symbol)] = ("qerase", "_", "R")
    end

    # Case for where w is empty string
    if length(w) == 0
        M2.transitionFunction[("qerase", "_")] = (M.startState, "_", R)
        return "$(string(M1))/$(string(M2))"
    end

    # Add states that load w onto the tape
    for i in eachindex(w)
        push!(M2.states, "w$i")
    end
    # After qerase is done clearing the tape, send to w1
    M2.transitionFunction[("qerase", "_")] = ("w1", "_", "R")
    # Add actual functionality for loading w
    for i in 1:length(w) - 1
        M2.transitionFunction[("w$i", "_")] = ("w$(i+1)", "$(w[i])", "R")
    end
    # Add a state that goes all the way back to left
    push!(M2.states, "qleft")
    M2.transitionFunction[("w$(length(w))", "_")] = ("qleft", "$(w[end])", "R")
    
    for symbol in M2.inputAlphabet
        M2.transitionFunction[("qleft", symbol)] = ("qleft", symbol, "L")
    end
    # When qleft reads a blank, then move to the right, 
    # move to start state of M.
    M2.transitionFunction[("qleft", "_")] = ("$(M.startState)", "_", "R")
    
    return "$(string(M1))/$(string(M2))"
end

function test1()
    # This string is in A_TM because 00 is accepted by the provided TM
    # Expect output in complement(EQ_TM)
    input1 = "q0,qrej,qacc|0,1|0,1,_|q0;0;q0;0;R,q0;1;qrej;1;R,q0;_;qacc;_;R|q0|qacc|qrej/00"

    println(f(input1))
end

function test2()
    # This string is not in A_TM because 01 is not accepted by the provided TM
    # Expected output in EQ_TM
    input2 = "q0,qrej,qacc|0,1|0,1,_|q0;0;q0;0;R,q0;1;qrej;1;R,q0;_;qacc;_;R|q0|qacc|qrej/01"

    println(f(input2))
end