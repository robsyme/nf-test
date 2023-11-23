process Waitlift {
    debug true
    input: tuple val(num_files), val(size)    
    script: "waitlift make --num $num_files --size $size data"
}
