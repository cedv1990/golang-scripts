#!/usr/bin/env zsh

# Steps to register the command "gocoverage", execute the following in the terminal:
# 1. touch ~/.oh-my-zsh/custom/gocoverage.zsh
# 2. open ~/.oh-my-zsh/custom/gocoverage.zsh
# 3. Save the content of this file there.
# 4. Restart the terminal or execute the command: source ~/.zshrc
# 5. To use it, execute: gocoverage
# 5.1. To use a different coverage percentage as a parameter: gocoverage -c 80
# 5.2. To exclude folders, pass a file name as a parameter: gocoverage -e excluded_dirs.txt
        # excluded_dirs.txt context example
        # internal/domains/...
        # internal/utils/...

function gocoverage() {
    local coverage=80
    local exclude=""

    local RED='\033[0;31m'
    local YELLOW='\033[0;33m'
    local BLUE='\033[0;34m'
    local PURPLE='\033[0;35m'
    local GREEN='\033[0;32m'
    local CYAN='\033[0;36m'

    local BOLD='\033[1m'
    local UNDERLINE='\033[4m'
    local RESET='\033[0m'

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

    if [ -z "$exclude" ]; then
        if ! go test -cover -coverprofile $file_name -race -count=1 ./...; then
            echo "${RED}There are errors in the tests and coverage could not be evaluated. Fix the tests and try again."

            rm -r $file_name

            return 1
        fi
    else 
        if ! go test -cover -coverprofile $file_name -race -count=1 $(go list ./... | grep -Ev "(${exclude%|})"); then
            echo "${RED}There are errors in the tests and coverage could not be evaluated. Fix the tests and try again."

            rm -r $file_name

            return 1
        fi
    fi

    echo ""
    echo "+--------------------------------+"
    echo "| .::: ${BLUE}${BOLD}Code Coverage Review${RESET} :::. |"
    echo "+--------------------------------+"
    echo "| => ${PURPLE}Threshold target: ${UNDERLINE}${BOLD}$coverage %${RESET}   <= |"

    totalCoverage=`go tool cover -func=$file_name | grep total | grep -Eo '[0-9]+\.[0-9]+'`

    if (( $(echo "$totalCoverage $coverage" | awk '{print ($1 > $2)}') )); then
        echo "| => ${GREEN}Current coverage: ${UNDERLINE}${BOLD}$totalCoverage %${RESET} <= |"
        echo "+--------------------------------+"
        echo ""
        echo "${GREEN}Sufficient coverage.${RESET}"
    else
        echo "| => ${CYAN}Current coverage: ${UNDERLINE}${BOLD}$totalCoverage %${RESET} <= |"
        echo "+--------------------------------+"
        echo ""
        echo "${YELLOW}Current test coverage is below threshold. ${UNDERLINE}Please add more unit tests.${RESET}"
        echo "${RED}Failed${RESET}"
    fi

    rm -r $file_name
}
