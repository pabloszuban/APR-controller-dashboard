using JSON
using HTTP
using Plots
using Dates
using DataFrames
using Statistics
using Diana

using DataFrames

BT_INITIAL_BLOCK_NUMBER = 2645867

const BITTENSOR_GRAPHQL_API_URL = "https://tao-indexer.hatom.com/graphql"

function get_all_bt_data(initial_block::Int)
    all_bt_data = DataFrame()
    # Get the last block number
    last_block = get_last_block_number()
    actual_block = initial_block
    while actual_block < last_block
        println("Obtaining blocks from ", actual_block, " until ", actual_block + 10000)
        try
            bt_df = get_bt_indexer_data(actual_block, actual_block + 10000)
            append!(all_bt_data, bt_df)
        catch e
            println("Error obtaining bt data: ", e)
        end
        actual_block += 10000
    end
    println("Data until present was obtained successfully ", all_bt_data)
    return all_bt_data
end

function get_bt_indexer_data(from_block_number::Int, to_block_number::Union{Int,Nothing})

    x_data = get_last_account_states_from_block_number_to_block_number(from_block_number, to_block_number)

    accumulated_rewards = [entry["accumulatedRewards"] for entry in x_data]
    total_staked = [entry["totalStaked"] for entry in x_data]
    block_number = [entry["blockNumber"] for entry in x_data]
    timestamps = [entry["block"]["timestamp"] for entry in x_data]

    df = DataFrame(
        accumulated_rewards=parse.(BigInt, accumulated_rewards),
        total_staked=parse.(BigInt, total_staked),
        block_number=block_number,
        timestamp=timestamps
    )
    return df
end

function get_last_account_states_from_block_number_to_block_number(from_block_number::Int, to_block_number::Int)

    query_name = "accountStates"
    query = """
    {
        accountStates(
            fromBlockNumber: $from_block_number,
            toBlockNumber: $to_block_number 
            ) {
                blockNumber
                accumulatedRewards
                totalStaked
                block{
                    timestamp
                }
            }
    }
    """

    response = Queryclient(BITTENSOR_GRAPHQL_API_URL, query)
    json = JSON.parse(response.Data)["data"]
    return json[query_name]

end

function get_last_block_number()
    query_name = "latestBlock"
    query = """
    {
        latestBlock{
            blockHash
            blockNumber
            parentHash
            timestamp
        }
    }
    """

    response = Queryclient(BITTENSOR_GRAPHQL_API_URL, query)
    json = JSON.parse(response.Data)["data"]
    return json[query_name]["blockNumber"]
end



