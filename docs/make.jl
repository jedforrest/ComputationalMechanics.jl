using ComputationalMechanics
using Documenter

DocMeta.setdocmeta!(ComputationalMechanics, :DocTestSetup, :(using ComputationalMechanics); recursive=true)

makedocs(;
    modules=[ComputationalMechanics],
    authors="jedforrest <forrest.j@unimelb.edu.au> and contributors",
    sitename="ComputationalMechanics.jl",
    format=Documenter.HTML(;
        canonical="https://jedforrest.github.io/ComputationalMechanics.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/jedforrest/ComputationalMechanics.jl",
    devbranch="main",
)
