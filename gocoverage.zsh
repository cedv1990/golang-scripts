#!/usr/bin/env zsh

# Steps to register the command "gocoverage", execute the following in the terminal:
# 1. touch ~/.oh-my-zsh/custom/gocoverage.zsh
# 2. open ~/.oh-my-zsh/custom/gocoverage.zsh
# 3. Save the content of this file there.
# 4. Restart the terminal or execute the command: source ~/.zshrc
# 5. To use it, execute: gocoverage
# 5.1. To use a different coverage percentage as a parameter: gocoverage -c 80

function gocoverage() {
    local coverage=80

    # Parsear los argumentos de la línea de comandos
    while getopts ":c:" opt; do
        case $opt in
            c)
                if [[ "$OPTARG" =~ ^[0-9]+$ ]]; then
                    coverage="$OPTARG"
                else
                    echo "The -c argument must be an integer." >&2
                    return 1
                fi
                ;;
            \?)
                echo "Invalid option: -$OPTARG" >&2
                return 1
                ;;
        esac
    done
    shift $((OPTIND -1))

    current_date=$(date +"%Y%m%d%H%M%S")

    file_name="coverage_${current_date}.out"

    go test -cover -coverprofile $file_name -race -count=1 ./...

    echo "Code Coverage Review"
    echo "Threshold target: $coverage %"

    totalCoverage=`go tool cover -func=$file_name | grep total | grep -Eo '[0-9]+\.[0-9]+'`

    echo "Current coverage: $totalCoverage %"
    if (( $(echo "$totalCoverage $coverage" | awk '{print ($1 > $2)}') )); then
        echo "OK"
    else
        echo "Current test coverage is below threshold. Please add more unit tests."
        echo "Failed"
    fi

    rm -r $file_name
}
