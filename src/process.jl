abstract type AbstractProcess{T} end

#-------------------------------------------------------------------------------------------
struct SyntheticProcess{T} <: AbstractProcess{T}
    seed::Int
    alphabet::Set{T}
    machine::EpsilonMachine{T}
end


#-------------------------------------------------------------------------------------------
struct EmpiricalProcess{T} <: AbstractProcess{T}

end
