#!/bin/bash

shopt -s nullglob
shopt -s globstar

TOTAL_LINE=$(cat **/*.c **/*.h *.c *.h 2>/dev/null | wc -l)
if [ "$TOTAL_LINE" -eq 0 ]; then
    echo "No .c or .h files"
	exit 1
fi
TOTAL_ERROR=$(norminette | grep "Error:" | wc -l)
TOTAL_RATIO=$(echo "scale=2; ($TOTAL_ERROR / $TOTAL_LINE) * 100" | bc)
TOTAL_FILE=$(expr $(ls -R | grep "\.c" | wc -l) + $(ls -R | grep "\.h" | wc -l))

echo "======================================================"
echo "📊 RATIO ERROR : $TOTAL_ERROR on $TOTAL_LINE lines for $TOTAL_FILE files"
echo "📈 ${TOTAL_RATIO}%"
echo "======================================================"
echo "$(ls -r | grep "\.c" | wc -l)"

check_norme_recursive()
{
    local target="$1"
    local indent="$2"

    if [[ "$target" == ".*" ]]; then
		return
    fi

	local errs=$(norminette "$target" 2>/dev/null | grep "Error:" | wc -l)

    local ratio="0%"
    if [ "$TOTAL_ERROR" -gt 0 ]; then
        ratio="$(( errs * 100 / TOTAL_ERROR ))%"
    fi

    if [ -d "$target" ]; then
        if [ "$errs" -eq 0 ]; then
            echo "${indent}✅ - $target/ -> 0 errors"
            return
        else
            echo "${indent}❌ - $target/ -> $errs errors ($ratio du total)"

            for child in "$target"/*; do
                check_norme_recursive "$child" "$indent  "
            done
        fi

    elif [ -f "$target" ] && [[ "$target" == *.c || "$target" == *.h ]]; then
        if [ "$errs" -eq 0 ]; then
            echo "${indent}✅ - $target -> 0 errors"
        else
            echo "${indent}❌ - $target -> $errs errors ($ratio du total)"
        fi
    fi
}

for item in *; do
    check_norme_recursive "$item" ""
done
