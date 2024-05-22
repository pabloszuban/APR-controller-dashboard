module App
using GenieFramework
@genietools
include("dashboard.jl")

@page("/dashboard", "dashboard_ui.jl.html", layout = "layout.jl", model = Dashboard)
route("/") do
    redirect(:get_dashboard)
end
end
