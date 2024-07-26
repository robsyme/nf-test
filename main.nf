nextflow.enable.dsl=2

process WithSharedMemory {
    containerOptions '--shm-size=256m'
    debug true
    """
    echo "shm-size: "
    df -h /dev/shm
    """
}

process WithOutSharedMemory {
    debug true
    """
    echo "shm-size: "
    df -h /dev/shm
    """
}

workflow {
    WithSharedMemory()
    WithOutSharedMemory()
}
