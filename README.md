# OrUnions

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://mkitti.github.io/OrUnions.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://mkitti.github.io/OrUnions.jl/dev/)
[![Build Status](https://github.com/mkitti/OrUnions.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/mkitti/OrUnions.jl/actions/workflows/CI.yml?query=branch%3Amain)

OrUnions.jl is a prototype Julia package to implement using either the operators `|` and `∨` (\vee) to create a `Union` to mimic the syntax of Scala 3, TypeScript, or Python. These languages create union types using the `|` operator. This package does not define `Base.:|(t::Type, types::Type...)` because this would be committing type piracy. Rather this package provides the option of using either `∨` or the macro `@orunion`.

1. OrUnions.jl defines `@inline ∨(@nospecialize(t::Type), @nospecialize(types::Type...)) = Union{t, types...}` and exports the operator.
2. OrUnions.jl defines `@inline OrUnions.:|(@nospecialize(t::Type), @nospecialize(types::Type...)) = Union{t, types...}` and does *NOT* export the operator.
3. OrUnions.jl also defines forwarding of `OrUnions.:|` `Base.:|`: `@inline OrUnions.:|(@nospecialize(args...)) = Base.:|(args...)`.
4. OrUnions.jl defines the macro `@orunion`, which allows for the use of `|` or `∨` without parentheses in type delcaration expressions.

## Operator Precedence

The type declaration operator `::` takes precedence before the "or" operators, [`|`](https://github.com/JuliaLang/JuliaSyntax.jl/blob/a6f2d1580f7bbad11822033e8c83e607aa31f100/src/kinds.jl#L632) and [`∨`](https://github.com/JuliaLang/JuliaSyntax.jl/blob/a6f2d1580f7bbad11822033e8c83e607aa31f100/src/kinds.jl#L634), in Julia. As a consequence of this, the following expression will produce an error.

```julia
julia> using OrUnions

julia> 0x5::UInt8 ∨ Int8
ERROR: MethodError: no method matching ∨(::UInt8, ::Type{Int8})
```

The expression is evaluated as `∨(0x5::UInt8, Int8)`. The subexpression `0x5::UInt8` is evaluated first. Thus, we must use parentheses in the following manner.

```julia
julia> 0x5::(UInt8 ∨ Int8)
0x05

julia> 0x5::∨(UInt8, Int8)
0x05
```

## `∨` operator in function definitions

The recommended way to use this package is the `∨` infix operator with parentheses in function definitions. The implementation is a relatively simple definition of an infix operator.

```julia
julia> using OrUnions

julia> f(x::(Int8 ∨ UInt8 ∨ Int)) = x
f (generic function with 1 method)

julia> methods(f)
# 1 method for generic function "f" from Main:
 [1] f(x::Union{Int64, Int8, UInt8})
     @ REPL[46]:1

julia> g(x::∨(Int8, Int16)) = x
g (generic function with 1 method)

julia> methods(g)
# 1 method for generic function "g" from Main:
 [1] g(x::Union{Int16, Int8})
     @ REPL[48]:1
```

Because of the parentheses, the resulting syntax differs from that of other languages.

## The macro `@orunion`

The macro `@orunion` allows for the use of either `|` or `∨` without parentheses.

```julia
julia> @orunion 0x5::UInt8 ∨ Int8
0x05

julia> @macroexpand @orunion 0x5::UInt8 ∨ Int8
:(0x05::Union{Int8, UInt8})

julia> @orunion 0x5::Int8 | UInt8
0x05

julia> @macroexpand @orunion 0x5::Int8 | UInt8
:(0x05::Union{UInt8, Int8})
```

`@orunion` can be applied to function definitions.

```julia
julia> @orunion function foo(::Int8 | UInt8 | Int16) end
foo (generic function with 1 method)

julia> methods(foo)
# 1 method for generic function "foo" from Main:
 [1] foo(::Union{Int16, Int8, UInt8})
     @ REPL[34]:1

julia> @macroexpand @orunion function foo(::Int8 | UInt8 | Int16) end
:(function foo(::Union{Int16, UInt8, Int8})
      #= REPL[36]:1 =#
      #= REPL[36]:1 =#
  end)

julia> @orunion bar(x::Int8 | UInt8, y::Int16 | UInt16, z::(Int8 | UInt8) | Int) = nothing
bar (generic function with 1 method)

julia> methods(bar)
# 1 method for generic function "bar" from Main:
 [1] bar(x::Union{Int8, UInt8}, y::Union{Int16, UInt16}, z::Union{Int64, Int8, UInt8})
     @ REPL[38]:1

julia> @macroexpand @orunion bar(x::Int8 | UInt8, y::Int16 | UInt16, z::(Int8 | UInt8) | Int) = nothing
:(bar(x::Union{UInt8, Int8}, y::Union{UInt16, Int16}, z::Union{Int, Union{UInt8, Int8}}) = begin
          #= REPL[40]:1 =#
          nothing
      end)

julia> methods(@orunion (x::Int8 | UInt8)->5)
# 1 method for anonymous function "#35":
 [1] (::var"#35#36")(x::Union{Int8, UInt8})
```

### `@∨` and `OrUnion.@|` are aliases for `@orunion`

`@∨`, `@\vee[TAB]` and `OrUnion.@|` are provided as aliases for `@orunion`. `@∨` is exported. `OrUnion.@|` is not exported.

To create your own alias, do `const var"@myalias" = var"@orunion"`.

Here is some example usage of the macro aliases.

```julia
julia> using OrUnions

julia> @∨ function foo(x::Int ∨ UInt, y::Float64 ∨ Nothing) end
foo (generic function with 1 method)

julia> methods(foo)
# 1 method for generic function "foo" from Main:
 [1] foo(x::Union{Int64, UInt64}, y::Union{Nothing, Float64})
     @ REPL[2]:1

julia> using OrUnions: @|

julia> @| function bar(x::Int | UInt, y::Float64 | Nothing) end
bar (generic function with 1 method)

julia> methods(bar)
# 1 method for generic function "bar" from Main:
 [1] bar(x::Union{Int64, UInt64}, y::Union{Nothing, Float64})
     @ REPL[5]:1
```

## Using `OrUnion.:|`

While `OrUnion.:|` is not exported, the definition can be used in your current module's namespace before `|` is used by explicitly by `using` the symbol as follows.

```julia
julia> using OrUnions: |

julia> Int8 | UInt8
Union{Int8, UInt8}

julia> 1 | 2
3
```

If you use `|` before explicitly declaring `using OrUnions: |`, this fail.

```julia
julia> true | false
true

julia> using OrUnions: |
WARNING: ignoring conflicting import of OrUnions.| into Main

julia> Int8 | UInt8
ERROR: MethodError: no method matching |(::Type{Int8}, ::Type{UInt8})
```

## Discussion

This package was created in response to the following Discourse discussion:
https://discourse.julialang.org/t/proposed-alias-for-union-types/108205
