using Gumbo
using Cascadia
using HTTP
using Distributed

url_base = "https://eparlib.nic.in"
range = Integer.(7e5:8e5)

"""
Gets link from Indian congressional record website.
"""
function get_link(n::Integer)
    try
        r = HTTP.get("https://eparlib.nic.in/handle/123456789/$n"; readtimeout = 2, retry = false)
        h = parsehtml(String(r.body))
        link = eachmatch(Selector(".btn-primary"), h.root)[1].attributes["href"]
        println("adding $(url_base * link) to links file")
        open("data/raw/links.txt", "a") do file
            write(file, "\n" * url_base * link)
        end
    catch e
        @info e
    end
end

pmap(x -> get_link(x), range)
