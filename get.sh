#!/bin/bash
botToken=$(sed -n 1p secret)
channelId=$(sed -n 2p secret)
chatId=$(sed -n 3p secret)
lastNumber=$(sed -n 4p secret)

sendPhotoUrl="https://api.telegram.org/bot"$botToken"/sendPhoto"
sendMessageUrl="https://api.telegram.org/bot"$botToken"/sendMessage"

getEarthquakeUrl="https://www.cwb.gov.tw/V7/modules/MOD_NEWEC.htm?_=$(date +%s)"
numbers=$(curl -s "$getEarthquakeUrl" | grep -o 'EC[^L.]*.htm' | sort -u | sort -nr | sed 's/\(EC[^.]*\).htm/\1/')
urlBase='https://www.cwb.gov.tw/V7/earthquake/Data/quake/'

IFS=$'\n'
numbers=($numbers)
unset IFS



for (( i = ${#numbers[@]} - 1; i >= 0; i-- ))
do
    articleNumber=$(echo ${numbers[$i]} | sed 's/EC\(.*\)/\1/' | bc)

    if [[ "$articleNumber" > "$lastNumber" ]]; then

        imgUrl="$urlBase""${numbers[$i]}.gif"
        infoUrl="$urlBase""${numbers[$i]}.htm"
        caption=$(curl -s $infoUrl | grep description | sed 's/.*content="\([^"]*\)".*/\1/')

        printf "%s : %s\n" "${numbers[$i]}" "$caption"
        data="chat_id="$channelId"&photo="$imgUrl"&caption="$caption""
        echo $data
        response=$(curl -s "$sendPhotoUrl" --data "$data")
        echo $response
        isSuccess=$(echo $response | jq '.ok')
        echo $isSuccess
        if [ "$isSuccess" = "true" ]; then
            head -n -1 secret > tmp
            cat tmp > secret
            echo $articleNumber >> secret
            rm tmp
        fi
    fi
done

