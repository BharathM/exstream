#####Bash script
#!/bin/bash

command=`iostat -xdy 1 1` #Command to check the availability
read -d '' output << EOF
${command}
EOF

rows=$(echo "$output" | wc -l)
#echo "Rows:"$rows

if (( $rows < 4 )); then #4 rows required if we have one mount
    echo "***IOSTAT not installed***Exiting..."
    exit
fi

hostname=$(hostname)
#echo $hostname
datetime=$(date +"%d_%m_%Y_%k_%M_%S")
datetime=$(echo "$datetime" | sed -e 's/ //g')
directory=$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )
filename="$hostname-iostat-$datetime.csv"
filename_with_path="$directory/$filename"
header="Date,Time,Device_Name,r/s,w/s,rkB/s,wkB/s,rrqm/s,wrqm/s,%rrqm,%wrqm,r_await ,w_await ,aqu-sz,rareq-sz,wareq-sz,svctm,%util"
echo $header >> $filename_with_path
chmod 777 $filename_with_path

for (( ; ; ))
do
    date=$(date +"%d-%m-%Y")
    time=$(date +"%r")
    
    command=`iostat -xdy 10 1` #Actual command
    read -d '' output << EOF
    ${command}
EOF

    rows=$(echo "$output" | wc -l)
    #echo "Rows:"$rows
    
    if (( $rows >= 4 )); then #4 rows required if we have one mount, check if the iostat successed.
        let total_mounts="($rows-3)" #3=Top 3 rows on the top
        #echo "total_mounts:"$total_mounts
        let offset_rows="(3+1)" #3=Top 3 rows on the top 1=first mount
        #echo "offset_rows:"$offset_rows
        let total_mounts="($total_mounts-1)" #Starts from zero
    else
        total_mounts=-1
    fi    

    device=( )
    reads_per_second=( )
    writes_per_second=( )
    rKB_per_second=( )
    wKB_per_second=( )
    rrqm_per_second=( )
    wrqm_per_second=( )
    percent_rrqm=( )
    percent_wrqm=( )
    r_await=( )
    w_await=( )
    aqu_sz=( )
    raaqu_sz=( )
    waaqu_sz=( )
    svctm=( )
    percent_util=( )

    for (( c=0; c<=$total_mounts; c++ ))
    do  
       let pos="$offset_rows+$c"
       device+=( $(echo "$output" | awk -v row="$pos" -F ' ' 'NR==row{print $1}') )
       #echo "device:"${device[$c]}
       reads_per_second+=( $(echo "$output" | awk -v row="$pos" -F ' ' 'NR==row{print $2}') )
       writes_per_second+=( $(echo "$output" | awk -v row="$pos" -F ' ' 'NR==row{print $3}') )
       rKB_per_second+=( $(echo "$output" | awk -v row="$pos" -F ' ' 'NR==row{print $4}') )
       wKB_per_second+=( $(echo "$output" | awk -v row="$pos" -F ' ' 'NR==row{print $5}') )   
       rrqm_per_second+=( $(echo "$output" | awk -v row="$pos" -F ' ' 'NR==row{print $6}') )
       wrqm_per_second+=( $(echo "$output" | awk -v row="$pos" -F ' ' 'NR==row{print $7}') )
       percent_rrqm+=( $(echo "$output" | awk -v row="$pos" -F ' ' 'NR==row{print $8}') )
       percent_wrqm+=( $(echo "$output" | awk -v row="$pos" -F ' ' 'NR==row{print $9}') )
       r_await+=( $(echo "$output" | awk -v row="$pos" -F ' ' 'NR==row{print $10}') )
       w_await+=( $(echo "$output" | awk -v row="$pos" -F ' ' 'NR==row{print $11}') )
       aqu_sz+=( $(echo "$output" | awk -v row="$pos" -F ' ' 'NR==row{print $12}') )
       raaqu_sz+=( $(echo "$output" | awk -v row="$pos" -F ' ' 'NR==row{print $13}') )
       waaqu_sz+=( $(echo "$output" | awk -v row="$pos" -F ' ' 'NR==row{print $14}') )
       svctm+=( $(echo "$output" | awk -v row="$pos" -F ' ' 'NR==row{print $15}') )
       percent_util+=( $(echo "$output" | awk -v row="$pos" -F ' ' 'NR==row{print $16}') )
    done

    for (( c=0; c<=$total_mounts; c++ ))
    do
      final_output=""
      final_output+="$date,$time,${device[$c]},"
      final_output+="${reads_per_second[$c]},${writes_per_second[$c]},${rKB_per_second[$c]},${wKB_per_second[$c]},${rrqm_per_second[$c]},${wrqm_per_second[$c]},"
      final_output+="${percent_rrqm[$c]},${percent_wrqm[$c]},${r_await[$c]},${w_await[$c]},${aqu_sz[$c]},${raaqu_sz[$c]},${waaqu_sz[$c]},${svctm[$c]},${percent_util[$c]}"
      echo $final_output >> $filename_with_path
    done

done

