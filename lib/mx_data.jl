using JSON
using Plots
using Dates
using Diana
using DataFrames

const GRAPHQL_API_URL = "https://mainnet-api.hatom.com/graphql"

function get_indexer_data(query_name, query)
    response = Queryclient(GRAPHQL_API_URL, query)
    json = JSON.parse(response.Data)["data"]
    return first(json[query_name])
end

function set_df_types!(df, vars)
    for (var_name, var_type) in vars
        if var_type == DateTime
            df[!, var_name] = DateTime.(df[!, var_name], "yyyy-mm-ddTHH:MM:SSZ")
            continue
        end
        df[!, var_name] = parse.(var_type, df[!, var_name])
    end
end

function get_mx_tao_response(tao_vars)
    tao_query_name = "queryWrappedTao"

    tao_query = """
    {
        $(tao_query_name) {
            stateHistory(first: 10000,  order: { asc: timestamp }) {
                $(join(string.(first.(tao_vars)), "\n"))
            }
            mints(first: 10000, order: { asc: timestamp }) {
                timestamp
                amount
            }
            burns(first: 10000, order: { asc: timestamp }) {
                timestamp
                bridgeAmount
            }
        }
    }
    """

    return get_indexer_data(tao_query_name, tao_query)
end

function get_mx_tao_ls_response(tao_ls_vars, initial_datetime, datetime)
    tao_ls_query_name = "queryWrappedTaoLiquidStaking"

    tao_ls_query = """
    {
    	$(tao_ls_query_name) {
    		stateHistory(first: 10000, filter: { timestamp: { between: { min: "$(initial_datetime)", max: "$(datetime)" } } },  order: { asc: timestamp }) {
    			$(join(string.(first.(tao_ls_vars)), "\n"))
    		}
    	}
    }
    """

    return get_indexer_data(tao_ls_query_name, tao_ls_query)
end

function get_mx_tao_data_tot(last_mx_tao_ls_df_timestamp::DateTime, last_bt_tao_timestamp::DateTime)

    tao_ls_vars = (
        :timestamp => DateTime,
        :cash => BigInt,
        :apr => Float64,
        :distributedRewards => BigInt
    )

    # Initialize the dataframe
    tao_ls_df = DataFrame(; Dict(tao_ls_vars)...)

    actual_datetime = Dates.format(last_bt_tao_timestamp, "yyyy-mm-ddTHH:MM:SSZ")
    number_of_queries = 0
    initial_datetime = Dates.format(last_mx_tao_ls_df_timestamp, "yyyy-mm-ddTHH:MM:SSZ")

    while number_of_queries < 1
        tao_ls_response = get_mx_tao_ls_response(tao_ls_vars, initial_datetime, actual_datetime)

        tao_ls_state_history = tao_ls_response["stateHistory"]

        new_tao_ls_df = vcat(DataFrame.(tao_ls_state_history)...)

        set_df_types!(new_tao_ls_df, tao_ls_vars)

        tao_ls_df = vcat(tao_ls_df, new_tao_ls_df)

        actual_datetime = tao_ls_df.timestamp[end]

        number_of_queries += 1
    end

    return tao_ls_df
end
