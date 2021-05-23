#!/bin/bash

botToken=$(sed -n 1p .secret)
channelId=$(sed -n 2p .secret)
chatId=$(sed -n 3p .secret)
imgurCleintId=$(sed -n 4p .secret)
lastNumber=$(sed -n 5p .secret)

year=$(expr $(date +%Y) - 1911)

function get_imgur_url()
{
    response=`curl -s --location --request POST "https://api.imgur.com/3/image" --header "Authorization: Client-ID $imgurCleintId" -F image="$1"`
    url=`echo $response | jq '.data.link' | sed 's/"//g'`
    echo "$url"
}

sendPhotoUrl="https://api.telegram.org/bot"$botToken"/sendPhoto"
sendMessageUrl="https://api.telegram.org/bot"$botToken"/sendMessage"

earthquakeListUrl="https://www.cwb.gov.tw/V8/C/E/MOD/EQ_ROW.html?T=$(date +%Y%m%d)"
earthquakeInfoBaseUrl="https://www.cwb.gov.tw/V8/C/E/EQ/EQ"

numbers=$(curl -s "$earthquakeListUrl" | grep -o "/V8/C/E/EQ/EQ"$year".*.html" | grep -v ""$year"000.*" | sort -nr | sed 's/.*EQ\/EQ\([^.]*\).html/\1/')
IFS=$'\n'
numbers=($numbers)
unset IFS


for (( i = ${#numbers[@]} - 1; i >= 0; i-- ))
do
    articleNumber=$(echo ${numbers[$i]} | cut -c1-6 | bc)
    if [[ "$articleNumber" -gt "$lastNumber" ]] && [[ "$articleNumber" -lt "$year"999"" ]]; then
        
        earthquakeInfoUrl="$earthquakeInfoBaseUrl""${numbers[$i]}.html"
        caption=$(curl -s $earthquakeInfoUrl | grep og:description | sed 's/.*content="\([^"]*\)" \/>.*/\1/')
        imgUrl=$(curl -s $earthquakeInfoUrl | grep -o 'href="/Data/earthquake/img/EC[^_]*_H.png?v=[0-9]*"' | sed 's/href="\([^"]*\)"/\1/')
        imgUrl=$(get_imgur_url "https://www.cwb.gov.tw"$imgUrl)

        printf "%s, %s, %s\n" "${numbers[$i]}" "$caption" "$imgUrl"

        data="chat_id="$channelId"&photo="$imgUrl"&caption="$caption""
        # data="chat_id="$chatId"&photo="$imgUrl"&caption="$caption""
        echo $data
        
        response=$(curl -s "$sendPhotoUrl" --data "$data")
        echo $response
        
        isSuccess=$(echo $response | jq '.ok')
        if [ "$isSuccess" = "true" ]; then
            head -n -1 .secret > tmp
            cat tmp > .secret
            echo $articleNumber >> .secret
            rm tmp
        fi
    fi
done

