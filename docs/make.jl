using OrUnions
using Documenter

DocMeta.setdocmeta!(OrUnions, :DocTestSetup, :(using OrUnions); recursive=true)

makedocs(;
    modules=[OrUnions],
    authors="Mark Kittisopikul <markkitt@gmail.com> and contributors",
    repo="https://github.com/mkitti/OrUnions.jl/blob/{commit}{path}#{line}",
    sitename="OrUnions.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://mkitti.github.io/OrUnions.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/mkitti/OrUnions.jl",
    devbranch="main",
)
