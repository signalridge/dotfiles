#!/usr/bin/env bash
set -euo pipefail
platform=${1:-darwin}
temporary=$(mktemp -d)
trap 'rm -rf "$temporary"' EXIT
store="$temporary/.local/share/gopass/stores/root"
mkdir -p "$store/jaist/cert" "$store/jaist/sso" "$store/easytier" "$store/sing-box"
touch "$store/jaist/cert/"{p12,password}.age "$store/jaist/sso/"{username,password}.age "$store/easytier/exit-ss-password.age" "$store/sing-box/clash-api-secret.age"
prefix="{{- \$ctx := deepCopy . -}}{{- \$_ := set \$ctx.chezmoi \"homeDir\" \"$temporary\" -}}{{- \$_ := set \$ctx.chezmoi \"os\" \"$platform\" -}}{{- \$_ := set \$ctx \"work\" false -}}{{- \$_ := set \$ctx \"headless\" true -}}{{- \$_ := set \$ctx \"hostname\" \"ci-host\" -}}"
render_config() {
    chezmoi execute-template "$prefix{{ includeTemplate \"sing-box/config.tmpl\" (dict \"root\" \$ctx \"password\" (printf \"%s=\" (repeat 43 \"A\")) \"secret\" \"fixture-api\" \"tun\" true) }}" >"$temporary/config.json"
}
render_config
jq -e '.outbounds[] | select(.tag == "jaist auto") | .outbounds == ["gpuserver","nas","JAIST VPN","Egress"]' "$temporary/config.json" >/dev/null
jq -e '.outbounds[] | select(.tag == "jaist") | .default == "jaist auto" and (.outbounds | index("JAIST VPN")) < (.outbounds | index("Egress"))' "$temporary/config.json" >/dev/null
test -z "$(jq -c -f .chezmoitemplates/sing-box/failover-routes.jq "$temporary/config.json")"
chezmoi execute-template "$prefix{{ includeTemplate \"private_dot_config/private_sing-box/openconnect-auto.json.tmpl\" \$ctx }}" >"$temporary/auth.json"
jq -e '.fallbacks == [{parent:"jaist",selector:"jaist auto",preferred:["gpuserver","nas"],fallback:"Egress",probeURL:"https://www.jaist.ac.jp/"}]' "$temporary/auth.json" >/dev/null
printf 'ok - %s: priority, manual choices and single ownership of failover\n' "$platform"
rm "$store/jaist/cert/p12.age"
render_config
jq -e '[.outbounds[] | select(.tag == "jaist auto")] | length == 0' "$temporary/config.json" >/dev/null
jq -e -f .chezmoitemplates/sing-box/failover-routes.jq "$temporary/config.json" | jq -e '.tag == "jaist" and .auto == ["gpuserver","nas"]' >/dev/null
printf 'ok - %s: incomplete credentials retain existing mesh failover\n' "$platform"
