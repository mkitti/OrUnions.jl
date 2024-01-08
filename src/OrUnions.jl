module OrUnions

using MacroTools

# Export some rare symbols for convenience, do `using OrUnions: OrUnions` to just import the package name
export @orunion, ∨, @∨

const TypeOrTypeVar = Union{Type, TypeVar}

@inline ∨(@nospecialize(t::Type), @nospecialize(types::TypeOrTypeVar...)) = Union{t, types...}
@inline ∨(@nospecialize(t::TypeVar), @nospecialize(types::TypeOrTypeVar...)) = Union{t, types...}
@inline |(@nospecialize(t::Type), @nospecialize(types::TypeOrTypeVar...)) = Union{t, types...}
@inline |(@nospecialize(t::TypeVar), @nospecialize(types::TypeOrTypeVar...)) = Union{t, types...}

# Fallback method forwarding
@inline |(@nospecialize(args...)) = Base.:|(args...)

"""
    @orunion
    @∨
    OrUnions.@|

Macro that inverts the order of precedence between `::` and the logical "or" operators, `|` and `∨`.
* `@orunion x::T1 | T2` is turned into `x::Union{T2, T1}`
* `@orunion x::T1 | T2 | T3` is turned into `x::Union{T3, T2, T1}`
* `@orunion x::T1 | T2 | T3 | ... | TN` is turned into `x::Union{TN, ..., T3, T2, T1})`
* `@orunion function f(x::T1 | T2)` is turned into `function f(x::Union{T2, T1})`
* `@orunion function f(x::T1 | T2 | T3)` is turned into `function f(x::Union{T3, T2, T1})`
* `@orunion f(x::T1 | T2) = nothing` is turned into `f(x::Union{T2,T1}) = nothing`
* `@orunion (x::T1 | T2) -> nothing` is turned into `x::Union{T2, T1} -> nothing`
"""
macro orunion(ex)
    esc(macro_orunion!(ex))
end

# Aliases of @orunion
const var"@∨" = var"@orunion"
const var"@|" = var"@orunion"

## Dispatch on ex.head
function macro_orunion!(arg)
    return arg
end

function macro_orunion!(ex::Expr)
    macro_orunion!(Val(ex.head), ex)
end

function macro_orunion!(::Val, ex)
    return ex
end

function macro_orunion!(::Val{:struct}, ex)
    # Map type parameter declarations
    if ex isa Expr && ex.args[2].head == :curly
        for i in eachindex(ex.args[2].args)[2:end]
            if ex.args[2].args[i] isa Expr
                _, ex.args[2].args[i].args[2] = unionize_or!(ex.args[2].args[i].args[2])
            end
        end
    end
    # Map fields and constructors
    for i in eachindex(ex.args[3].args)
        ex.args[3].args[i] = macro_orunion!(ex.args[3].args[i])
    end
    return ex
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

# (arg::T1 | T2 -> ...) transforms to arg::Union{T2 | T1} -> ...
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

# arg::T1 | T2 | ... | TN transforms to arg::Union{TN, ..., T2, T1}
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

# T1 | T2 | T3 | ... TN transforms to Union{TN, ..., T3, T2, T1}
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

"""
    ∨(t::Union{Type,TypeVar}, types::Union{Type,TypeVar}...)
    a::Union{Type,TypeVar} ∨ b::Union{Type,TypeVar}

Logical "or" applied to types to form a `Union`. `∨` is exported from OrUnions.
* `∨(t1, t2, ...) === Union{t1, t2, ...}
* `a ∨ b === Union{a,b}`
"""
∨

"""
    OrUnion.:|(t::Union{Type,TypeVar}, types::Union{Type,TypeVar}...)
    a::Union{Type,TypeVar} | b::Union{Type,TypeVar}

Logical "or" applied to types to form a `Union` and forwards to `Base.:|`
which implements bitwise "or" for numerical types.

For `Type` or `TypeVar`, the following is true.
* `|(t1, t2, ...) === Union{t1, t2, ...}
* `a | b === Union{a,b}`

For all combinations of types, the implementation fallsback to `Base.:|` via forwarding.
* `|(a, b, ...) === Base.:|(a, b, ...)`
* `a | b === Base.:|(a, b)`
"""
|

end # module OrUnions
