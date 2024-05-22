module Dashboard
using GenieFramework
using CSV
using DataFrames
using PlotlyBase
using Interpolations
using Main.DataAnalysis

@genietools

# Define a function to update the data
function update_dataframes()
    update_data()
    global tao = CSV.read("data/bt_tao_df.csv", DataFrame) |> DataFrame
    global mx = CSV.read("data/mx_tao_ls_df.csv", DataFrame) |> DataFrame

    global mx_tiempo = datetime2unix.(mx.timestamp)
    global mx_tiempo_ms = mx_tiempo * 1000
    global distributed_rewards_itp = linear_interpolation(mx_tiempo_ms, mx.distributedRewards, extrapolation_bc=Line())
    global should_have_distributed_itp = linear_interpolation(tao.timestamp, tao.rewardsForLsDistribution, extrapolation_bc=Line())
end


function loss(t::Int)
    return distributed_rewards_itp(t) - should_have_distributed_itp(t)
end

function get_last_values()
    final_tao_timestamp = tao.timestamp[end]
    global last_loss = loss(final_tao_timestamp)
    println("The last loss is: ", last_loss)
    global last_distributed_rewards = distributed_rewards_itp(final_tao_timestamp)
    println("The last distributed rewards is: ", last_distributed_rewards)
    global last_should_have_distributed = should_have_distributed_itp(final_tao_timestamp)
    println("The last should have distributed rewards is: ", last_should_have_distributed)
end

@app begin
    @in refresh = false

    # inicializate the data
    update_dataframes()
    get_last_values()

    # Plot of loss evaluated in tao[:, "timestamp"] points versus unix2datetime.(tao[:, "timestamp"] // 1000)
    @out loss_scatter_trace = [scatter(
        x=unix2datetime.(tao[:, "timestamp"] // 1000),
        y=loss.(tao[:, "timestamp"]),
        mode="lines",
        line=attr(color="red"),
        name="Loss vs. Timestamp"
    )]
    @out loss_scatter_layout = PlotlyBase.Layout(
        xaxis_title="Time",
        yaxis_title="WTAO"
    )

    # Plot of accumulated_rewards vs. time, mx.distributedRewards vs, mx.timestamp and tao.rewardsForLsDistribution vs. time. The three in the same plot
    @out scatter_trace = [
        scatter(
            x=unix2datetime.(tao.timestamp // 1000),
            y=tao.accumulated_rewards,
            mode="lines",
            line=attr(color="green"),
            name="Bittensor Accumulated Rewards"
        ),
        scatter(
            x=mx.timestamp,
            y=mx.distributedRewards,
            mode="lines",
            line=attr(color="purple"),
            name="Distributed Rewards"
        ),
        scatter(
            x=unix2datetime.(tao.timestamp // 1000),
            y=tao.rewardsForLsDistribution,
            mode="lines",
            line=attr(color="orange"),
            name="Should have distributed rewards"
        )
    ]
    @out scatter_layout = PlotlyBase.Layout(
        xaxis_title="Time",
        yaxis_title="TAO"
    )

    # Plot the mx.apr vs. mx.timestamp
    @out apr_trace = [scatter(
        x=mx.timestamp,
        y=mx.apr,
        mode="lines",
        line=attr(color="blue"),
        name="APR"
    )]
    @out apr_layout = PlotlyBase.Layout(
        xaxis_title="Time",
        yaxis_title="APR"
    )

    # Output the final values
    @out last_loss_value = round(last_loss / 1e9, digits=3)
    @out last_distributed_rewards_value = round(last_distributed_rewards / 1e9, digits=2)
    @out last_should_have_distributed_value = round(last_should_have_distributed / 1e9, digits=2)
    @out last_apr_value = mx.apr[end]
    @out last_utilization_factor_value = round(mx.cash[end] / tao.total_staked[end] * 100, digits=2)

    @onbutton refresh begin
        update_dataframes()
        get_last_values()

        # Plot of loss evaluated in tao[:, "timestamp"] points versus unix2datetime.(tao[:, "timestamp"] // 1000)
        loss_scatter_trace = [scatter(
            x=unix2datetime.(tao[:, "timestamp"] // 1000),
            y=loss.(tao[:, "timestamp"]),
            mode="lines",
            line=attr(color="red"),
            name="Loss vs. Timestamp"
        )]
        loss_scatter_layout = PlotlyBase.Layout(
            xaxis_title="Time",
            yaxis_title="TAO"
        )

        # Plot of accumulated_rewards vs. time, mx.distributedRewards vs, mx.timestamp and tao.rewardsForLsDistribution vs. time. The three in the same plot
        scatter_trace = [
            scatter(
                x=unix2datetime.(tao.timestamp // 1000),
                y=tao.accumulated_rewards,
                mode="lines",
                line=attr(color="green"),
                name="Bittensor Accumulated Rewards"
            ),
            scatter(
                x=mx.timestamp,
                y=mx.distributedRewards,
                mode="lines",
                line=attr(color="purple"),
                name="Distributed Rewards"
            ),
            scatter(
                x=unix2datetime.(tao.timestamp // 1000),
                y=tao.rewardsForLsDistribution,
                mode="lines",
                line=attr(color="orange"),
                name="Should have distributed rewards"
            )
        ]
        scatter_layout = PlotlyBase.Layout(
            xaxis_title="Time",
            yaxis_title="TAO"
        )

        # Plot the mx.apr vs. mx.timestamp
        apr_trace = [scatter(
            x=mx.timestamp,
            y=mx.apr,
            mode="lines",
            line=attr(color="blue"),
            name="APR"
        )]
        apr_layout = PlotlyBase.Layout(
            xaxis_title="Time",
            yaxis_title="APR"
        )

        # Output the final values
        last_loss_value = round(last_loss / 1e9, digits=3)
        last_distributed_rewards_value = round(last_distributed_rewards / 1e9, digits=2)
        last_should_have_distributed_value = round(last_should_have_distributed / 1e9, digits=2)
        last_apr_value = mx.apr[end]
        last_utilization_factor_value = round(mx.cash[end] / tao.total_staked[end] * 100, digits=2)
    end
end

end
