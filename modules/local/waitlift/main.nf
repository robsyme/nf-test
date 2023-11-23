process Waitlift {
    debug true
    input: tuple val(num_files), val(size)    
    """
    waitlift make --num $num_files --size $size data
    waitlift move data new_data
    """
}
