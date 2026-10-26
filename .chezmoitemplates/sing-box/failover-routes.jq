[.endpoints[]? | select(.type == "openconnect") | .tag] as $vpns
| [.outbounds[] | select(.type == "selector" and (.outbounds | index("Egress")))
   | select(any(.outbounds[:(.outbounds | index("Egress"))][]; . as $member | $vpns | index($member))) | .tag] as $managed
| .outbounds[] | select(.type == "selector" and .tag != "Egress" and (.outbounds | index("Egress")))
| select(.tag as $tag | $managed | index($tag) | not)
| select(all(.outbounds[]; . as $member | $managed | index($member) | not))
| {tag, auto: .outbounds[:(.outbounds | index("Egress"))]}
