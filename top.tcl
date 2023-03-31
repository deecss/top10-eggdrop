# gra_w_slowa.tcl
set game_active 0
set word_count_file "word_count.txt"

proc read_word_counts {} {
    global word_count_file
    set word_counts [list]

    if {![file exists $word_count_file]} {
        return $word_counts
    }

    set f [open $word_count_file r]
    while {![eof $f]} {
        lappend word_counts [split [gets $f] " "]
    }
    close $f

    return $word_counts
}

proc write_word_counts {word_counts} {
    global word_count_file

    set f [open $word_count_file w]
    foreach count $word_counts {
        puts $f [join $count " "]
    }
    close $f
}

proc count_word {nick} {
    global game_active

    if {!$game_active} {
        return
    }

    set word_counts [read_word_counts]

    set idx [lsearch -exact -index 0 $word_counts $nick]
    if {$idx >= 0} {
        set count [lindex $word_counts $idx]
        set new_count [expr {[lindex $count 1] + 1}]
        lset word_counts $idx [list $nick $new_count]
    } else {
        lappend word_counts [list $nick 1]
    }

    write_word_counts $word_counts
}

proc get_top10 {nick uhost hand chan} {
    set word_counts [read_word_counts]
    set sorted [lsort -integer -decreasing -index 1 $word_counts]

    set result ""
    for {set i 0} {$i < [llength $sorted] && $i < 10} {incr i} {
        set count [lindex $sorted $i]
        append result [expr {$i + 1}].[lindex $count 0] - [lindex $count 1], " "
    }

    putquick "PRIVMSG $chan :Top 10 graczy: $result"
}

proc game_start {nick uhost hand chan} {
    global game_active
    if {$game_active} {
        return
    }

    set game_active 1
    putquick "PRIVMSG $chan :Gra w słowa rozpoczęta!"
}

proc game_stop {nick uhost hand chan} {
    global game_active
    if {!$game_active} {
        return
    }

    set game_active 0
    putquick "PRIVMSG $chan :Gra w słowa zakończona!"
    write_word_counts [list]
}

bind pub - "!statstart" game_start
bind pub - "!statstop" game_stop
bind pub - "!top10" get_top10

bind pub - "*!*" count_word