# Watch function for ghostscript
# - Rohan Gunjal (github.com/theZeenX1)

#!/bin/bash

command -v gs >/dev/null 2>&1 || { 
    echo >&2 "Ghostscript not found. Try installing it using:\napt-get install ghostscript\nor\nyum install ghostscript"; 
    exit 1; 
}

cleanup() {
    if [ -n "$GSPID" ]; then
        kill $GSPID
    fi
}
trap cleanup EXIT

while getopts "f:" flag; do
    case ${flag} in
        o) OUTPUT_FILE=$OPTARG;;
        f) FILENAME=$OPTARG;;
        \?) echo "Invalid flag" >&2; exit 1;;
    esac
done

if [[ -z $FILENAME ]]; then
    echo "Usage: $0 -f <filename.ps> [-o <outputfile.pdf>]" >&2
    exit 1
fi

if [[ -z $OUTPUT_FILE ]]; then
    OUTPUT_FILE="out_${FILENAME%.ps}.pdf"
fi

if [[ $OUTPUT_FILE != *.pdf ]]; then
    OUTPUT_FILE="${OUTPUT_FILE}.pdf"
fi

if [[ $FILENAME = *.ps ]]; then
    echo "Starting ghostscript\n\n"
    gs -dNOPAUSE -dBATCH -sDEVICE=pdfwrite -sOutputFile="${OUTPUT_FILE}" "${FILENAME}" &
    GSPID=$(ps aux | grep "gs ${FILENAME}" | awk '{print $2}' | head -n 1)
    sleep 1
    md5_original=$(md5sum ${FILENAME} | awk '{ print $1 }')
    while :; do
	sleep .5s
	md5_new=$(md5sum ${FILENAME} | awk '{ print $1 }')
        if [[ $md5_original != $md5_new ]]; then
            md5_original=$md5_new
            kill $GSPID
            echo "Changes detected, restarting ghostscript"
            gs -dNOPAUSE -dBATCH -sDEVICE=pdfwrite -sOutputFile="${OUTPUT_FILE}" "${FILENAME}" &
            GSPID=$(ps aux | grep "gs ${FILENAME}" | awk '{print $2}' | head -n 1)
            sleep 1
        fi
    done
else
    echo "File name must end with .ps" >&2
    exit 1
fi
