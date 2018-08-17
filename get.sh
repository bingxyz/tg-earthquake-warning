#!/bin/bash
botToken=$(sed -n 1p secret)
channelId=$(sed -n 2p secret)
chatId=$(sed -n 3p secret)

sendPhotoUrl="https://api.telegram.org/bot"$botToken"/sendPhoto"
sendMessageUrl="https://api.telegram.org/bot"$botToken"/sendMessage"

getEarthquakeUrl="https://www.cwb.gov.tw/V7/modules/MOD_NEWEC.htm?_=$(date +%s)"
numbers=$(curl -s "$getEarthquakeUrl" | grep -o 'EC[^L.]*.htm' | sort -u | sort -nr | sed 's/\(EC[^.]*\).htm/\1/')
urlBase='https://www.cwb.gov.tw/V7/earthquake/Data/quake/'

IFS=$'\n'
numbers=($numbers)
unset IFS

lastNumber=$(sed -n 4p secret)


for (( i = ${#numbers[@]} - 1; i >= 0; i-- ))
do
    articleNumber=$(echo ${numbers[$i]} | sed 's/EC\(.*\)/\1/' | bc)

    if [[ "$articleNumber" > "$lastNumber" ]]; then
        #echo $articleNumber > "lastNumber"
        head -n -1 secret > tmp
        cat tmp > secret
        echo $articleNumber >> secret
        rm tmp
        imgUrl="$urlBase""${numbers[$i]}.gif"
        infoUrl="$urlBase""${numbers[$i]}.htm"
        caption=$(curl -s $infoUrl | grep description | sed 's/.*content="\([^"]*\)".*/\1/')

        printf "%s : %s\n" "${numbers[$i]}" "$caption"
        data="chat_id="$channelId"&photo="$imgUrl"&caption="$caption""
        echo $data
        curl -s "$sendPhotoUrl" --data "$data"
    fi
done
