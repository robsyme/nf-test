process Waitlift {
    debug true
    memory '8G'
    cpus 4

    input: tuple val(num_files), val(size)    

    """
    waitlift make --num $num_files --size $size data
    waitlift move data new_data
    """
}
