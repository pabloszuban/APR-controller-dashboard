module DataAnalysis

using Plots
using Loess
using DataFrames
using Interpolations
using CSV


include("bt_data.jl")
include("mx_data.jl")

export update_data

function update_data()

    # generate a df with the previous values of bt_tao_df
    previous_bt_tao_df = CSV.read("data/bt_tao_df.csv", DataFrame)
    # get the block_number of the last row
    last_bt_tao_df = previous_bt_tao_df[end, :]
    initial_bt_block_number = last_bt_tao_df.block_number

    # get new bt data since the last block_number
    bt_tao_df = get_all_bt_data(initial_bt_block_number)
    println("length of new bt_tao_df: ", nrow(bt_tao_df))
    println("The last bt timestamp is: ", bt_tao_df.timestamp[end])

    # generate a df with the previous values of mx_tao_ls_df
    previous_tao_ls_df = CSV.read("data/mx_tao_ls_df.csv", DataFrame)
    # get the timestamp of the last row
    last_mx_tao_ls_df = previous_tao_ls_df[end, :]
    last_mx_tao_ls_df_timestamp = last_mx_tao_ls_df.timestamp
    println("The last timestamp of mx_tao_ls_df is: ", last_mx_tao_ls_df_timestamp)

    # get new mx data since the last timestamp and the last timestamp of bt_tao_df
    mx_tao_ls_df = get_mx_tao_data_tot(last_mx_tao_ls_df_timestamp, unix2datetime(bt_tao_df.timestamp[end] / 1000))
    # remove the first two rows of mx_tao_ls_df to avoid duplicated rows
    mx_tao_ls_df = mx_tao_ls_df[3:end, :]
    println("length of new mx_tao_ls_df: ", nrow(mx_tao_ls_df))

    # generate a concatenated dataframe with the previous and the new mx data
    mx_tao_ls_df = vcat(previous_tao_ls_df, mx_tao_ls_df)

    # generate a concatenated dataframe with the previous and the new bt data
    # from the previous bt data we just need the rows accumulated_rewards,total_staked,block_number,timestamp
    previous_bt_tao_new_df = previous_bt_tao_df[:, [:accumulated_rewards, :total_staked, :block_number, :timestamp]]
    # from the new bt data we need all the rows
    bt_tao_df = vcat(previous_bt_tao_new_df, bt_tao_df)

    # Drop bt_tao_df rows with duplicated
    unique!(bt_tao_df)

    # generate the column deltaGeneratedRewards as the difference between the current and the previous row and zero for the first row
    bt_tao_df.deltaGeneratedRewards = [0; diff(bt_tao_df.accumulated_rewards)]

    # define useful interpolators from multiversx data
    tao_ls_t = datetime2unix.(mx_tao_ls_df.timestamp)
    cash_itp = linear_interpolation(tao_ls_t, mx_tao_ls_df.cash, extrapolation_bc=Line())

    # define useful interpolators from bittensor data
    tao_bt_t = bt_tao_df.timestamp

    # assert tao_bt_t is sorted in increasing order
    @assert all(diff(tao_bt_t) .>= 0)

    # at every step in which we generate rewards at bittensor staking,
    # we should distribute cashMx(t) / stakeBt(t) * deltaRewards(t) at
    # multiversx tao liquid staking
    bt_tao_df.deltaRewardsForLsDistribution = zeros(BigFloat, nrow(bt_tao_df))
    for i in eachindex(bt_tao_df.timestamp)
        if isone(i)
            bt_tao_df.deltaRewardsForLsDistribution[i] = BigFloat(0)
            continue
        end
        t_prev = bt_tao_df.timestamp[i-1]
        t_prev_secs = t_prev / 1000
        bt_tao_df.deltaRewardsForLsDistribution[i] = cash_itp(t_prev_secs) * bt_tao_df.deltaGeneratedRewards[i] / bt_tao_df.total_staked[i-1]
    end

    bt_tao_df.rewardsForLsDistribution = cumsum(bt_tao_df.deltaRewardsForLsDistribution)

    # get the first element of previous_bt_tao_df.rewardsForLsDistribution
    first_bt_tao_df = previous_bt_tao_df.rewardsForLsDistribution[1]

    # add  last_bt_tao_df.rewardsForLsDistribution to every element of rewardsForLsDistribution to include past should have distributed values to new ones
    bt_tao_df.rewardsForLsDistribution = bt_tao_df.rewardsForLsDistribution .+ first_bt_tao_df

    # If the bt data frame reaches 15000 rows, remove the first 5000 rows. Then use the timestamp of the new first row and convertit to datetime and delete the rows from mvx data frame that are previous to this timestamp
    if nrow(bt_tao_df) > 10000
        println("Removing the first 5000 rows of bt_tao_df and the previous rows of mx_tao_ls_df")
        println("The length of bt_tao_df is: ", nrow(bt_tao_df))
        println("The length of mx_tao_ls_df is: ", nrow(mx_tao_ls_df))
        new_first_bt_tao_df_timestamp = bt_tao_df.timestamp[5000]
        first_bt_tao_df_timestamp = unix2datetime(new_first_bt_tao_df_timestamp / 1000)
        mx_tao_ls_df = mx_tao_ls_df[mx_tao_ls_df.timestamp.>first_bt_tao_df_timestamp, :]
        bt_tao_df = bt_tao_df[5000:end, :]
        println("The length of bt_tao_df is: ", nrow(bt_tao_df))
        println("The length of mx_tao_ls_df is: ", nrow(mx_tao_ls_df))
    end

    # save both dataframes to csv
    CSV.write("data/bt_tao_df.csv", bt_tao_df)
    CSV.write("data/mx_tao_ls_df.csv", mx_tao_ls_df)
end

end
