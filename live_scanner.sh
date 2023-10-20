#!/bin/bash


echo ""
echo "           ███████╗██╗  ██╗"
echo "           ██╔════╝╚██╗██╔╝"
echo "           ██████╗  ╚███╔╝ "
echo "           ██╔══╝   ██╔██╗ "
echo "           ███████╗██╔╝ ██╗"
echo "           ╚══════╝╚═╝  ╚═╝"
echo ""
echo "   Ransomware Victim Data Extractor"
echo "-----------------------------------"
echo ""

echo "This script allows you to extract ransomware victim data based on the top-level domain (TLD)."
echo "You can choose to extract data for all victims, victims of a specific year, or victims of a specific month in a year."

echo ""
echo ""


read -p "Enter a top-level domain (com, fr, etc.): " tld

echo ""

if [ -f "posts.json" ]; then
    rm -f "posts.json"
fi


valid_option=false
while [ "$valid_option" != true ]; do
    echo "Select the type of victims:"
    echo ""
    echo " [1]. All victims"
    echo " [2]. Victims of a specific year"
    echo " [3]. Victims of a specific month in a year"
    echo " [4]. exit"
    echo ""
    read -p "Enter the option (1/2/3): " option
    echo ""

  
    base_url="https://api.ransomware.live/victims"
    current_year=$(date +'%Y')

    case $option in
        1)

            wget https://data.ransomware.live/posts.json 2>&1 | awk '/% / {n=2; if($0 ~ /=/)n=1; printf "Data download :  " $(NF-n) "\r"} END{print ""}'
            valid_option=true
            ;;
        2)
         
            read -p "Enter the year ( >= 2020 =< $current_year): " year
            mkdir "$year"

            echo ""
            echo "Work started => "

            for ((month=1; month<=12; month++)); do
                url="${base_url}/${year}/$(printf "%02d" $month)"
                output_file="${year}/$(printf "%02d" $month).json"

                echo -n "."
                
                curl -s -X 'GET' "$url" -H "accept: application/json" > "$output_file"
                
                sleep 1
            done

            jq -s 'add' $year/* > posts.json

            rm -rf $year
            
            valid_option=true
            ;;
        3)
            
            read -p "Enter the year ( >= 2020 =< $current_year ): " year
            read -p "Enter the month (01-12): " month

            url="${base_url}/${year}/$(printf "%02d" $month)"
            curl -s -X 'GET' "$url" -H "accept: application/json" > posts.json
            valid_option=true
            ;;
        4)
            exit
            ;;
        *)
            echo "Invalid option. Please select 1, 2, or 3"
            ;;
    esac
done

jq -r '.[] | "\(.post_title)\t -- attaqué par --\t\(.group_name)"' posts.json | column -t -s $'\t' > all_victims

grep -e "\.${tld}" all_victims > "${tld}_victims.txt"

echo ""
if [ -s "${tld}_victims.txt" ]; then
    echo "-------------------------------------------- Results -------------------------------------------------------------"
    echo ""
    cat "${tld}_victims.txt"
    echo ""
else
    echo "No results found :)"
fi

rm -f all_victims posts.json "${tld}_victims.txt"



