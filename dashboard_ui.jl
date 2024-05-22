# I need the last values of loss, distributed rewards and should have distributed rewards at the left of loss plot but with a small size
cell(class="row", [
    #= cell(class="st-module", [
        h1("Last loss value"),
        p(last_loss_value)
    ]), =#
    cell(class="st-col col-10 col-sm st-module", [
        h4("Plot for loss"),
        plot(:loss_scatter_trace, layout=:loss_scatter_layout)
    ]),
])
cell(class="row", [
    cell(class="st-col col-4 col-sm st-module", [
        h4("Plot for Bittensor accumulated rewards, distributed rewards and should have distributed rewards"),
        plot(:scatter_trace, layout=:scatter_layout)
    ]),
])
cell(class="row", [
    cell(class="st-col col-4 col-sm st-module", [
        h4("Plot for APR"),
        plot(:apr_trace, layout=:apr_layout)
    ]),
])

