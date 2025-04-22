using windc_household_model

using DataFrames, MPSGE, PlotlyJS


data = load_data(2017)

household = household_model(data);
solve!(household, cumulative_iteration_limit=0)

#zero_profit(household[:KS])

# Set all tariffs to 20%
set_value!.(household[:tm], .2)

solve!(household)


# Create a graph of the percent change in real wages

# This could be automated, but needs work to do
vars = Dict(
    :PC => Dict(:domain => (:region, :household)),
    :PLS => Dict(:domain => (:region, :household)),
    :C => Dict(:domain => (:region, :household)),
    :RA => Dict(:domain => (:region, :household)),
    :LS => Dict(:domain => (:region, :household)),
    :PD => Dict(:domain => (:region, :good)),
    :RK => Dict(:domain => (:region, :good)),
    :PY => Dict(:domain => (:region, :good)),
    :X => Dict(:domain => (:region, :good)),
    :A => Dict(:domain => (:region, :good)),
    :PA => Dict(:domain => (:region, :good)),
    :Y => Dict(:domain => (:region, :good)),
    :PM => Dict(:domain => (:region, :margin)),
    :MS => Dict(:domain => (:region, :margin)),
    :PN => Dict(:domain => (:good,)),
    :PL => Dict(:domain => (:region,)),
    :RKS => Dict(:domain => ()),
    :NYSE => Dict(:domain => ()),
    :GOVT_DEMAND => Dict(:domain => ()),
    :GOVT => Dict(:domain => ()),
    :PK => Dict(:domain => ()),
    :KS => Dict(:domain => ()),
    :INVEST_COMMODITY => Dict(:domain => ()),
    :GOVT_COMMODITY => Dict(:domain => ()),
    :PFX => Dict(:domain => ()),
    :INVEST_DEMAND => Dict(:domain => ()),
    :INVEST => Dict(:domain => ()),
)
function var_to_df(M::MPSGEModel, var::Symbol; value = :value, var_dict = vars)
    variable_to_dataframe(M[var], var_dict[var][:domain]...; value_name = value)
end




## Overall Welfare
description(household[:PC])
description(household[:PL])

#(PL/PC-1)*100

PC = var_to_df(household, :PC)
PL = var_to_df(household, :PL)

innerjoin(
        PC,
        PL,
        on = :region,
        renamecols = "" => "_wage"
    ) |>
    x -> transform(x,
        [:value, :value_wage] => ByRow((pc,pl) -> (pl/pc-1)*100) => :real_value
    ) |>
    x -> sort(x, :real_value) |>
    X -> plot(
        X, 
        x = :region, 
        y = :real_value, 
        color = :household, 
        type = :bar, 
        Layout(
            title = "Real wages",
            #yaxis_range = [bounds[1,:min], bounds[1,:max]])
        )
    )