using markusen_2_2

using MPSGE, JuMP, PATHSolver, DataFrames


# Initialize the MPSGE version of the model and verify the benchmark
mpsge = mpsge_2_2_taxes()
solve!(mpsge, cumulative_iteration_limit=0)


# Same as above with the algebraic version of the model
mcp = mcp_2_2_taxes()
set_attribute(mcp, "cumulative_iteration_limit", 0)
optimize!(mcp)
set_attribute(mcp, "cumulative_iteration_limit", 10_000)


## Counterfactual 1 - tax_pl = .1
set_parameter_value(mcp[:tax_pl], 0.1)
optimize!(mcp)

set_value!(mpsge[:tax_pl], 0.1)
solve!(mpsge)


## Verify the two solutions are the same
vars = [:X, :Y, :W, :PX, :PY, :PW, :PL, :PK, :CONS]

out = "| Variable | MPSGE | MCP |\n| --------- | ----- | --- |\n"
for var in vars
    out *= "| $(var) | $(round(value(mpsge[var]),digits=6)) | $(round(value(mcp[var]), digits=6)) |\n"
end

print(out)


## Extract the cost function of X from the MPSGE model
cost_function(mpsge[:X])









## Part 2: Add a parameter that controls elasticity on X
## Left to the reader to implement the algebraic version of this model.
function mpsge_2_2_taxes_new()

    M = MPSGEModel()

    @parameters(M, begin
        tax_pl, 0, (description = "Tax on labor in sector X")
        tax_pk, 0, (description = "Tax on capital in sector X")
        sigma, .5, (description = "Elasticity of substitution in sector X")
    end)

    @sectors(M, begin
        X
        Y
        W
    end)

    @commodities(M, begin
        PX
        PY
        PW
        PK
        PL
    end)

    @consumer(M, CONS)

    @production(M, X, [t=0, s=sigma, va=>s=1], begin
        @output(PX, 120, t)
        @input(PY, 20, s)
        @input(PL, 40, va, taxes=[Tax(CONS,tax_pl)])
        @input(PK, 60, va, taxes=[Tax(CONS,tax_pk)])
    end)

    @production(M, Y, [t=0, s=.75, va=>s=1], begin
        @output(PY, 120, t)
        @input(PX, 20, s)
        @input(PL, 60, va)
        @input(PK, 40, va)
    end)

    @production(M, W, [t=0, s=1], begin
        @output(PW, 200, t)
        @input(PX, 100, s)
        @input(PY, 100, s)
    end)

    @demand(M, CONS, begin
        @final_demand(PW, 200)
        @endowment(PL, 100)
        @endowment(PK, 100)
    end)

    fix(PW, 1)

    return M
end

M = mpsge_2_2_taxes_new()
solve!(M, cumulative_iteration_limit=0)


set_value!(M[:tax_pl], 0.1)
solve!(M)

df = generate_report(M) |>
    x -> transform(x,
        :var => ByRow(y->1) => :counterfactual
    )

set_value!(M[:sigma], 1)

solve!(M)

df = vcat(df, 
    generate_report(M) |>
        x -> transform(x,
            :var => ByRow(y->2) => :counterfactual
        )
)



set_value!(M[:sigma], 3)

solve!(M)

df = vcat(df, 
    generate_report(M) |>
        x -> transform(x,
            :var => ByRow(y->3) => :counterfactual
        )
)

set_value!(M[:tax_pk], .5)
solve!(M)

df = vcat(df, 
    generate_report(M) |>
        x -> transform(x,
            :var => ByRow(y->4) => :counterfactual
        )
)



df |> 
    x -> select(x, Not(:margin)) |>
    x -> unstack(x, :counterfactual, :value)


