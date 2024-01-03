module OrUnions

using MacroTools

export @orunion, ∨

@inline ∨(@nospecialize(t::Type), @nospecialize(types::Type...)) = Union{t, types...}
@inline |(@nospecialize(t::Type), @nospecialize(types::Type...)) = Union{t, types...}

# Fallback method forwarding
@inline |(@nospecialize(args...)) = Base.:|(args...)

macro orunion(ex)
    esc(macro_orunion!(ex))
end

function macro_orunion!(ex)
    macro_orunion!(Val(ex.head), ex)
end

function macro_orunion!(::Val{:function}, ex)
    if ex.args[1].head == :(::)
        # call expression for function arguments
        ex.args[1].args[1].args[2:end] .= map(ex.args[1].args[1].args[2:end]) do argex
            unionize_arg!(argex)
        end
        # return type assertion
        _, ex.args[1].args[2] = unionize_or!(ex.args[1].args[2])
        return ex
    end
    ex.args[1].args[2:end] .= map(ex.args[1].args[2:end]) do argex
        unionize_arg!(argex)
    end
    return ex
end

# Or use MacroTools.longdef
function macro_orunion!(::Val{:(=)}, ex)
    ex.args[1].args[2:end] .= map(ex.args[1].args[2:end]) do argex
        unionize_arg!(argex)
    end
    return ex
end

function macro_orunion!(::Val{:call}, ex)
    unionize_arg!(ex)
end

function macro_orunion!(::Val{:(::)}, ex)
    unionize_arg!(ex)
end

function macro_orunion!(::Val{:(->)}, ex)
    if ex.args[1].head == :call
        ex.args[1] = unionize_arg!(ex.args[1])
        return ex
    elseif ex.args[1].head == :tuple
        ex.args[1].args .= map(ex.args[1].args) do argex
            unionize_arg!(argex)
        end
        return ex
    elseif ex.args[1].head == :(::)
        throw(ArgumentError("@orunion for anonymous functions with return types is not implemented"))
    end
end

function unionize_arg!(ex)
    if ex.head == :(::)
        _, ex.args[end] = unionize_or!(ex.args[end])
        return ex
    end
    ex, union_ex = unionize_or!(ex)
    if ex.head == :(::)
        if ex.args[end] isa Symbol
            # Just append the type
            push!(union_ex.args, ex.args[end])
        else
            # Expression
            _, union_ex2 = unionize_or!(ex.args[end])
            push!(union_ex.args, union_ex2)
        end
        ex.args[end] = union_ex
        if length(ex.args) > 2
            resize!(ex.args, 2)
        end
    else
        throw(ArgumentError("Tried to unionize an argument that is not a type assertion"))
    end
    return ex
end

function unionize_or!(ex::Expr)
    types = Symbol[]
    while ex isa Expr && ex.head == :call && (ex.args[1] == :| || ex.args[1] == :∨)
        append!(types, @view ex.args[3:end])
        ex = ex.args[2]
    end
    if ex isa Symbol
        push!(types, ex)
    end
    return ex, Expr(:curly, :Union, types...)
end
unionize_or!(ex::Symbol) = ex, ex

end # module OrUnions
