using Gumbo
using Cascadia
using HTTP

url_base = "https://eparlib.nic.in"
range = Integer.(7e5:8e5)

@time begin
    Threads.@threads for n in 760000:761000
        println("trying $n on thread $(Threads.threadid())")
        try
            r = HTTP.get("https://eparlib.nic.in/handle/123456789/$n"; readtimeout = 2, retry = false)
            h = parsehtml(String(r.body))
            link = eachmatch(Selector(".btn-primary"), h.root)[1].attributes["href"]
            open("data/raw/links.txt", "a") do file
                write(file, "\n" * url_base * link)
            end
        catch e
            @info e
        end
    end
end
