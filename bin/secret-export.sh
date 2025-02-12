secret-tool-export() {
    if [ "$#" -lt 3 ] || [ $(( $# % 2 )) -ne 1 ]; then
        echo "Usage: secret_export <env_var_name> <attribute1> <value1> [<attribute2> <value2> ...]"
        return 1
    fi

    local env_var_name="$1"
    shift

    local secret_value
    secret_value=$(secret-tool lookup "$@")

    if [ -z "$secret_value" ]; then
        echo "Error: No secret found for the provided attributes"
        return 1
    fi

    # export "$env_var_name"="$secret_value"
    export "$env_var_name=$secret_value"

    echo "view with: echo \"\$$env_var_name\""
}
