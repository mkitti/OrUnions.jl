using OrUnions
using Test

@testset "OrUnions.jl" begin
    @test ∨(Int8, UInt8) == Union{Int8, UInt8}
    @test Int8 ∨ UInt8 == Union{Int8, UInt8}
    @test Int8 ∨ UInt8 ∨ Int16 == Union{Int8, UInt8, Int16}

    @orunion(0x5::UInt8 ∨ Int8) == 5
    @orunion(0x5::Int8 | UInt8) == 5

    function foo1(x::(Int8 ∨ UInt8)) end
    @test methods(foo1)[1].sig.parameters[2] == Union{Int8, UInt8}

    @orunion function foo2(x::Int16 ∨ UInt16) end
    @test methods(foo2)[1].sig.parameters[2] == Union{Int16, UInt16}

    @orunion function foo3(x::Int16 ∨ UInt16 ∨ Bool) end
    @test methods(foo3)[1].sig.parameters[2] == Union{Int16, UInt16, Bool}

    @orunion function foo4(x::Int16 ∨ UInt16 ∨ Bool, y::UInt8 ∨ Int8) end
    @test methods(foo4)[1].sig.parameters[2] == Union{Int16, UInt16, Bool}
    @test methods(foo4)[1].sig.parameters[3] == Union{UInt8, Int8}

    @orunion function foo5(x::Int32 | UInt32, y::Int16 | Int32)::(Int8 | UInt8) end
    @test methods(foo5)[1].sig.parameters[2] == Union{Int32, UInt32}
    @test methods(foo5)[1].sig.parameters[3] == Union{Int16, Int32}

    @orunion foo6(x::Int8, y::Int32 | UInt32) = nothing
    @test methods(foo6)[1].sig.parameters[2] == Int8
    @test methods(foo6)[1].sig.parameters[3] == Union{Int32, UInt32}

    @test methods(@orunion((x::Int8 | Int16 | Int32 | Int64)->x))[1].sig.parameters[2] == Int8 ∨ Int16 ∨ Int32 ∨ Int64
    @test methods(@orunion((x::Int8 | Int16, y::Int32 | Int64)->x))[1].sig.parameters[2] == Int8 ∨ Int16
    @test methods(@orunion((x::Int8 | Int16, y::Int32 | Int64)->x))[1].sig.parameters[3] == Int32 ∨ Int64

    # TODO:
    # @test methods(@orunion((x::Int8 | Int16)::(Int8 ∨ Int16) -> x))[1].sig.parameters[2] == Int8 ∨ Int16
end
