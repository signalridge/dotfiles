# shellcheck shell=bash
# Make aqua-managed CLIs (gopass, jq, ...) runnable from a bootstrap script.
# On a fresh machine ~/.zshenv has not been sourced yet, so the aqua shims are
# off PATH and, worse, fail with "command is not found" (aqua code 004) when
# AQUA_GLOBAL_CONFIG is unset. Same paths as dot_zshenv.
aqua_bin_dir="${AQUA_ROOT_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/aquaproj-aqua}/bin"
if [[ -d "$aqua_bin_dir" ]]; then
    case ":$PATH:" in
    *":$aqua_bin_dir:"*) ;;
    *) export PATH="$aqua_bin_dir:$PATH" ;;
    esac
fi
aqua_config_path="${XDG_CONFIG_HOME:-$HOME/.config}/aquaproj-aqua/aqua.yaml"
if [[ -f "$aqua_config_path" ]]; then
    case ":${AQUA_GLOBAL_CONFIG:-}:" in
    *":$aqua_config_path:"*) ;;
    *) export AQUA_GLOBAL_CONFIG="${aqua_config_path}${AQUA_GLOBAL_CONFIG:+:${AQUA_GLOBAL_CONFIG}}" ;;
    esac
fi
aqua_policy_path="${XDG_CONFIG_HOME:-$HOME/.config}/aquaproj-aqua/aqua-policy.yaml"
if [[ -f "$aqua_policy_path" ]]; then
    case ":${AQUA_POLICY_CONFIG:-}:" in
    *":$aqua_policy_path:"*) ;;
    *) export AQUA_POLICY_CONFIG="${aqua_policy_path}${AQUA_POLICY_CONFIG:+:${AQUA_POLICY_CONFIG}}" ;;
    esac
fi
