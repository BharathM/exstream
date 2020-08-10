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

for (( ; ; ))
do

    command=`iostat -xdy 10 1` #Actual command
    read -d '' output << EOF
    ${command}
EOF

    date=$(date +"%d-%m-%Y")
    time=$(date +"%r")
    
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
       rrqm_per_second+=( $(echo "$output" | awk -v row="$pos" -F ' ' 'NR==row{print $2}') )
       wrqm_per_second+=( $(echo "$output" | awk -v row="$pos" -F ' ' 'NR==row{print $3}') )
       reads_per_second+=( $(echo "$output" | awk -v row="$pos" -F ' ' 'NR==row{print $4}') )
       writes_per_second+=( $(echo "$output" | awk -v row="$pos" -F ' ' 'NR==row{print $5}') )
       rKB_per_second+=( $(echo "$output" | awk -v row="$pos" -F ' ' 'NR==row{print $6}') )   
       wKB_per_second+=( $(echo "$output" | awk -v row="$pos" -F ' ' 'NR==row{print $7}') )
       avgrq_sz+=( $(echo "$output" | awk -v row="$pos" -F ' ' 'NR==row{print $8}') )
       avgqu_sz+=( $(echo "$output" | awk -v row="$pos" -F ' ' 'NR==row{print $9}') )
       await+=( $(echo "$output" | awk -v row="$pos" -F ' ' 'NR==row{print $10}') )
       r_await+=( $(echo "$output" | awk -v row="$pos" -F ' ' 'NR==row{print $11}') )
       w_await+=( $(echo "$output" | awk -v row="$pos" -F ' ' 'NR==row{print $12}') )
       svctm+=( $(echo "$output" | awk -v row="$pos" -F ' ' 'NR==row{print $13}') )
       percent_util+=( $(echo "$output" | awk -v row="$pos" -F ' ' 'NR==row{print $14}') )

    done

    newline=$'\n'
    final_output=""
    for (( c=0; c<=$total_mounts; c++ ))
    do
      final_output+="node_text_iostat_rrqm_per_second{device=\"${device[$c]}\"} ${rrqm_per_second[$c]}${newline}"
      final_output+="node_text_iostat_wrqm_per_second{device=\"${device[$c]}\"} ${wrqm_per_second[$c]}${newline}"
      final_output+="node_text_iostat_reads_per_second{device=\"${device[$c]}\"} ${reads_per_second[$c]}${newline}"
      final_output+="node_text_iostat_writes_per_second{device=\"${device[$c]}\"} ${writes_per_second[$c]}${newline}"
      final_output+="node_text_iostat_rKB_per_second{device=\"${device[$c]}\"} ${rKB_per_second[$c]}${newline}"
      final_output+="node_text_iostat_wKB_per_second{device=\"${device[$c]}\"} ${wKB_per_second[$c]}${newline}"
      final_output+="node_text_iostat_avgrq_sz{device=\"${device[$c]}\"} ${avgrq_sz[$c]}${newline}"
      final_output+="node_text_iostat_avgqu_sz{device=\"${device[$c]}\"} ${avgqu_sz[$c]}${newline}"
      final_output+="node_text_iostat_await{device=\"${device[$c]}\"} ${await[$c]}${newline}"
      final_output+="node_text_iostat_r_await{device=\"${device[$c]}\"} ${r_await[$c]}${newline}"
      final_output+="node_text_iostat_w_await{device=\"${device[$c]}\"} ${w_await[$c]}${newline}"
      final_output+="node_text_iostat_svctm{device=\"${device[$c]}\"} ${svctm[$c]}${newline}"
      final_output+="node_text_iostat_percent_util{device=\"${device[$c]}\"} ${percent_util[$c]}${newline}"
    done


    cat << EOF > "/text/iostat.prom.$$"
    $final_output
EOF

    mv "/text/iostat.prom.$$" \
      "/text/iostat.prom" || rm "/text/iostat.prom"

    chmod 777 /text/iostat.prom


done
