nextflow.enable.dsl=2

process SayHi {
    input:
    val(name)

    output:
    path("greeting.txt")

    "echo 'Hi there, $name' > greeting.txt"
}

process SayBye {
    input:
    val(name)

    output:
    path("farewell.txt")

    "echo 'See you next time, $name' > farewell.txt"
}

process GestureTo {
    input:
    val(name)

    output:
    val(true)

    'sleep $[ ( $RANDOM % 10 ) + 1 ]'
}

process MakeSummary {
    input:
    path('in.txt')

    output:
    path('out.txt')

    '''
    LINE_COUNT=$(awk 'END{print NR}' in.txt)
    PEOPLE_COUNT=$(awk '{a[NF]="X"} END { print length(a) }' in.txt)
    echo "Found $LINE_COUNT utterances to $PEOPLE_COUNT people" > out.txt
    '''
}

workflow {
    Channel.of('Rob', 'Daniel', 'Michael')
    | ( SayHi & SayBye & GestureTo)

    SayHi.out
    | mix(SayBye.out)
    | collectFile(name: 'utterances.txt')
    | MakeSummary

    SayBye.out
    | count
    | set { ch_farewell_count }

    MakeSummary.out
    | combine(GestureTo.out.last())
    | map { summaryFile, flag ->
        sendMail {
            to 'rob.syme@gmail.com'
            attach "${summaryFile}"
            subject "TEST EMAIL"
            "TEST CONTENT"
        }
    }
}