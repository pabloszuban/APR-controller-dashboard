
using GenieFramework
using HTTP
Genie.loadapp()
up(async=true)
HTTP.get("http://localhost:8000/");
HTTP.get("http://localhost:8000/dashboard");

