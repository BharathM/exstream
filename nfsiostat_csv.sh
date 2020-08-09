#####Bash script
#!/bin/bash

each_mount_data_rows=10

command=`nfsiostat 1 2` #Generate two sets of output    
read -d '' output << EOF
${command}
EOF

rows=$(echo "$output" | wc -l)
#echo "Rows:"$rows


if (( $rows < 19 )); then #19 rows required if we have one NFS mount
    echo "***NFSIOSTAT not installed***Exiting..."
    exit
fi


hostname=$(hostname)
#echo $hostname
datetime=$(date +"%d_%m_%Y_%k_%M_%S")
datetime=$(echo "$datetime" | sed -e 's/ //g')
directory=$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )
filename="$hostname-nfsiostat-$datetime.csv"
filename_with_path="$directory/$filename"
header="Date,Time,Mount_Name,read_ops_per_second,read_KB_per_second,read_KB_per_ops,read_retrans,read_avg_rtt_ms,read_avg_exe_ms,write_ops_per_second,write_KB_per_second,write_KB_per_ops,write_retrans,write_avg_rtt_ms,write_avg_exe_ms"
echo $header >> $filename_with_path
chmod 777 $filename_with_path

for (( ; ; ))
    do
    command=`nfsiostat 10 2`
    read -d '' output << EOF
    ${command}
EOF
    date=$(date +"%d-%m-%Y")
    time=$(date +"%r")

    rows=$(echo "$output" | wc -l)
    #echo "Rows:"$rows
    
    if (( $rows >= 19 )); then #7 rows required if we have one mount, check if the iostat successed.
        let total_mounts="((($rows+1)/2)/each_mount_data_rows)" #1=Missing row,/2=Two sets of output
        #echo "total_mounts:"$total_mounts
        let offset_rows="($rows+1)/2" #1=One row missing in the total output,/2=There are two sets in the outputs
        #echo "offset_rows:"$offset_rows
        let total_mounts="($total_mounts-1)" #Starts from zero
    else
        total_mounts=-1
    fi     

    mount=( )

    mount_read_ops_s=( )
    mount_read_KB_s=( )
    mount_read_KB_ops=( )
    mount_read_retrans=( )
    mount_read_avg_rtt_ms=( )
    mount_read_avg_exe_ms=( )

    mount_write_ops_s=( )
    mount_write_KB_s=( )
    mount_write_KB_ops=( )
    mount_write_retrans=( )
    mount_write_avg_rtt_ms=( )
    mount_write_avg_exe_ms=( )


    for (( c=0; c<=$total_mounts; c++ ))
    do  
       let pos="$offset_rows+1+($c*$each_mount_data_rows)"
       #echo "pos:"$pos
       temp=$(echo "$output" | awk -v row="$pos" 'NR==row {print}')
       temp1=$(echo "$temp" | sed -e 's/ //g')
       mount+=( $(echo "$temp1" ) )
       #echo "mount["$c"]:"${mount[$c]}
       let pos="$offset_rows+7+($c*$each_mount_data_rows)"
       mount_read_ops_s+=( $(echo "$output" | awk -v row="$pos" -F ' ' 'NR==row{print $1}') )
       mount_read_KB_s+=( $(echo "$output" | awk -v row="$pos" -F ' ' 'NR==row{print $2}') )
       mount_read_KB_ops+=( $(echo "$output" | awk -v row="$pos" -F ' ' 'NR==row{print $3}') )
       mount_read_retrans+=( $(echo "$output" | awk -v row="$pos" -F ' ' 'NR==row{print $4}') )
       mount_read_avg_rtt_ms+=( $(echo "$output" | awk -v row="$pos" -F ' ' 'NR==row{print $6}') )
       mount_read_avg_exe_ms+=( $(echo "$output" | awk -v row="$pos" -F ' ' 'NR==row{print $7}') )
       let pos="$offset_rows+9+($c*$each_mount_data_rows)"
       mount_write_ops_s+=( $(echo "$output" | awk -v row="$pos" -F ' ' 'NR==row{print $1}') )
       mount_write_KB_s+=( $(echo "$output" | awk -v row="$pos" -F ' ' 'NR==row{print $2}') )
       mount_write_KB_ops+=( $(echo "$output" | awk -v row="$pos" -F ' ' 'NR==row{print $3}') )
       mount_write_retrans+=( $(echo "$output" | awk -v row="$pos" -F ' ' 'NR==row{print $4}') )
       mount_write_avg_rtt_ms+=( $(echo "$output" | awk -v row="$pos" -F ' ' 'NR==row{print $6}') )
       mount_write_avg_exe_ms+=( $(echo "$output" | awk -v row="$pos" -F ' ' 'NR==row{print $7}') ) 
       
    done
    #echo echo ${#mount[*]}

    for (( c=0; c<=$total_mounts; c++ ))
    do
      final_output=""
      final_output+="$date,$time,${mount[$c]},"
      final_output+="${mount_read_ops_s[$c]},${mount_read_KB_s[$c]},${mount_read_KB_ops[$c]},${mount_read_retrans[$c]},${mount_read_avg_rtt_ms[$c]},${mount_read_avg_exe_ms[$c]},"
      final_output+="${mount_write_ops_s[$c]},${mount_write_KB_s[$c]},${mount_write_KB_ops[$c]},${mount_write_retrans[$c]},${mount_write_avg_rtt_ms[$c]},${mount_write_avg_exe_ms[$c]}"
      echo $final_output >> $filename_with_path
    done

done

