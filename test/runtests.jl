using OrUnions
using OrUnions: |, @|
using Test

@testset "OrUnions.jl" begin
    @test ∨(Int8, UInt8) == Union{Int8, UInt8}
    @test Int8 ∨ UInt8 == Union{Int8, UInt8}
    @test Int8 ∨ UInt8 ∨ Int16 == Union{Int8, UInt8, Int16}

    @orunion(0x5::UInt8 ∨ Int8) == 5
    @orunion(0x5::Int8 | UInt8) == 5

    function foo1(x::(Int8 ∨ UInt8)) end
    @test methods(foo1).ms[1].sig.parameters[2] == Union{Int8, UInt8}

    @orunion function foo2(x::Int16 ∨ UInt16) end
    @test methods(foo2).ms[1].sig.parameters[2] == Union{Int16, UInt16}

    @orunion function foo3(x::Int16 ∨ UInt16 ∨ Bool) end
    @test methods(foo3).ms[1].sig.parameters[2] == Union{Int16, UInt16, Bool}

    @orunion function foo4(x::Int16 ∨ UInt16 ∨ Bool, y::UInt8 ∨ Int8) end
    @test methods(foo4).ms[1].sig.parameters[2] == Union{Int16, UInt16, Bool}
    @test methods(foo4).ms[1].sig.parameters[3] == Union{UInt8, Int8}

    @orunion function foo5(x::Int32 | UInt32, y::Int16 | Int32)::(Int8 | UInt8) end
    @test methods(foo5).ms[1].sig.parameters[2] == Union{Int32, UInt32}
    @test methods(foo5).ms[1].sig.parameters[3] == Union{Int16, Int32}

    @orunion foo6(x::Int8, y::Int32 | UInt32) = nothing
    @test methods(foo6).ms[1].sig.parameters[2] == Int8
    @test methods(foo6).ms[1].sig.parameters[3] == Union{Int32, UInt32}

    @test methods(@orunion((x::Int8 | Int16 | Int32 | Int64)->x)).ms[1].sig.parameters[2] == Int8 ∨ Int16 ∨ Int32 ∨ Int64
    @test methods(@orunion((x::Int8 | Int16, y::Int32 | Int64)->x)).ms[1].sig.parameters[2] == Int8 ∨ Int16
    @test methods(@orunion((x::Int8 | Int16, y::Int32 | Int64)->x)).ms[1].sig.parameters[3] == Int32 ∨ Int64

    struct MyType{T <: AbstractVector}
        x::(T | Nothing)
    end
    @test fieldtype(MyType{Vector{Int}},1) == Union{Vector{Int}, Nothing}
    struct MyType2{T <: AbstractVector}
        x::(Nothing ∨ T)
    end
    @test fieldtype(MyType2{Vector{Int}},1) == Union{Vector{Int}, Nothing}
    struct MyType3{T <: AbstractVector, N <: Number}
        x::(Nothing | T | N)
        y::(Nothing ∨ T ∨ N)
        z::(T | Nothing ∨ N)
    end
    @test fieldtype(MyType3{Vector{Int}, Float64},1) == Union{Vector{Int}, Nothing, Float64}
    @test fieldtype(MyType3{Vector{Int}, Float64},2) == Union{Vector{Int}, Nothing, Float64}
    @test fieldtype(MyType3{Vector{Int}, Float64},3) == Union{Vector{Int}, Nothing, Float64}
    @| struct MyType4{T <: Number | Integer}
        x::T | UInt
        y::T | Float64
        z::T | Nothing
        MyType4() = new{Int}(1,1,1)
    end
    @test fieldtype(MyType4{Int}, 1) == Union{Int, UInt}
    @test fieldtype(MyType4{Int}, 2) == Union{Int, Float64}
    @test fieldtype(MyType4{Int}, 3) == Union{Int, Nothing}
    @test |(Int) == Int
    @test ∨(Float64) == Float64

    # TODO:
    # @test methods(@orunion((x::Int8 | Int16)::(Int8 ∨ Int16) -> x))[1].sig.parameters[2] == Int8 ∨ Int16

    # Test forwarding of OrUnions.:| to Base.:|
    @test 1 | 2 == 3
    @test 1 | 3 == 3
    @test 2 | 3 == 3
    @test 0x8 | 0x10 == 0x18
    @test ismissing(5 | missing)
    @test ismissing(missing | 5)
    @test ismissing(|(missing))
    @test big"5" | big"7" == 7
end
