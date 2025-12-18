#!/usr/bin/perl -w

use POSIX;

# ipointRun($souString, $intLength)
#
# Perform an ipoint observation of the source $souString for $intLength seconds.
#
# $souString should be a string identifying the source to observe, e.g. "M82".
#
# $intLength is the length of the observation in seconds.  If not specified, a
# default value of 5 seconds is used.
sub ipointRun {
    $souString = $_[0];
    $intLength = $_[1] | 10;

	LST();
    $targel=checkEl($souString);
    if($targel < $MINEL_GAIN)
        {
            print "Pointing elevation for $souString is $targel below min elevation limit of $MINEL_GAIN.  Skipping observation.\n";
            return 1;
        }
    if($targel > $MAXEL_GAIN)
        {
            print "Pointing elevation for $souString is $targel below min elevation limit of $MINEL_GAIN.  Skipping observation.\n";
            return 1;
        }

    command("observe -s $souString -R 0 -D 0 -v 0 -e 2000 -t gain");
    command("integrate -s 0 -t 5");
    command("tsys");

    # Same as used for normal automated ipoint cmds
    command("ipoint -i $intLength -r 3 -8 -c 2.5 -w -n -Q -s")

}

# observeGainTarget($souString, $nInt, $intLength, $doTsys)
#
# Perform a gain calibration observation of the source $souString for
# $intLength seconds, with $nInt integrations.  If $doTsys, also
# perform a tsys measurement.
#
# Returns 0 on success.
sub observeGainTarget {
    $souString = $_[0];
    $nInt = $_[1];
    $intLength = $_[2];
    $doTsys = $_[3];

	LST();
    $targel=checkEl($souString);
    if($targel < $MINEL_TARG)
        {
            print "Target elevation for $souString is $targel below min elevation limit of $MINEL_TARG.  Skipping observation.\n";
            return 1;
        }

    if ($simulateMode) {
        # Estimate time for gain scan
        my $tsys_time = $doTsys ? 5.0 : 0.0; # assume tsys takes 5s
        my $init_time = 5.0; # initial integration
        my $wait_time = 4.0; # antennaWait
        my $scan_time = $nInt * $intLength;
        my $total_time = $init_time + $tsys_time + $wait_time + $scan_time;
        printf("[SIMULATION MODE] observeGainTarget: Would observe %s for %d integrations, %d seconds each. Estimated time: %.1f seconds.\n",
            $souString, $nInt, $intLength, $total_time);
        $unixTime = $unixTime + $total_time;
        @lookup_time = localtime($unixTime);

        return 0;
    }

    command("observe -s $souString -R 0 -D 0 -v 0 -e 2000 -t gain");
    command("integrate -s 0 -t $intLength");
    if ($doTsys) {command("tsys");}
    command("antennaWait -e 4");
    command("integrate -s $nInt -t $intLength -w");

    return 0;
}

# observeTargetOTF($souString, $intLength)
#
# Perform an OTF observation of the source $souString for $intLength seconds.
#
# $souString should be a string identifying the source to observe, e.g.
# "M82".
#
# $intLength should be the length of the observation in seconds.
#
# Returns 0 on success.
sub observeTargetOTF{
    $souString = $_[0];
    $intLength = $_[1];
    $rowLength = $_[2];
    $rowOffset = $_[3];
    $nRows = $_[4];
    $posAngle = $_[5] || 0.0;
    $startRow = $_[6] || 0.0;
    $scanSpeed = $_[7] || 4.5;

	LST();
    $targel=checkEl($souString);

    # OTF can take up to ~15 min. To avoid hitting elevation limits during the
    # OTF scan, add a small el buffer to the minumum.
    my $elLimitBuffer = 2;

    if($targel < $MINEL_TARG + $elLimitBuffer)
        {
            print "Target elevation for $souString is $targel below min elevation limit of $MINEL_GAIN (+ $elLimitBuffer buffer for long OTF scans).  Skipping observation.\n";
            return 1;
        }

    print "otf -v $scanSpeed -l $rowLength -y $rowOffset -n $nRows -p $posAngle -i $startRow -e -w\n";

    if ($simulateMode) {
        # Estimate time for OTF scan
        my $row_time = $rowLength / $scanSpeed; # seconds per row
        my $row_delay = 2.0; # default row delay
        my $row_ramp_delay = 3.0; # default row delay
        my $init_delay = 3.0; # default initial delay
        my $total_time = $init_delay + ($nRows * $row_time) + (($nRows) * $row_delay)  + (($nRows) * $row_ramp_delay);
        printf("[SIMULATION MODE] observeTargetOTF: Would observe %s for %.1f seconds, %d rows, scan speed %.2f arcsec/s. Estimated time: %.1f seconds.\n",
            $souString, $intLength, $nRows, $scanSpeed, $total_time);
        $unixTime = $unixTime + $total_time;
        @lookup_time = localtime($unixTime);
        $future_time = " -t \"$lookup_time[3] $month $year $lookup_time[2]:$lookup_time[1]:$lookup_time[0]\"";

        return 0;
    }

    command("observe -s $souString");
    command("integrate -t $intLength");
    command("tsys");
    command("antennaWait -e 4");

    command("integrate -t $intLength -w");
    # First print expected duration
    command("otf -v $scanSpeed -l $rowLength -y $rowOffset -n $nRows -p $posAngle -i $startRow -e -T");
    # Then run the OTF cmd.
    command("otf -v $scanSpeed -l $rowLength -y $rowOffset -n $nRows -p $posAngle -i $startRow -e -w");

    # Usage: otf [OPTIONS]

    # Starts a synchronized on-the-fly (OTF) scan on the antennas.

    # -a, --antenna=<list>         a comma-separated list of antenna numbers and
    #                             ranges (..). E.g. '2,4..7'.
    # -v, --speed=<arcsec/s>       scan speed.
    # -l, --length=<arcsec>        scan length.
    # -r, --ramp=<seconds>         ramp up time, for each row (default: 3.0).
    # -n, --rows=<int>             number of scan rows.
    # -y, --step_y=<arcsec>        step between rows, perpendicular to motion.
    # -x, --step_x=<arcsec>        step between rows, along row direction
    #                             (default: 0.0).
    # -e, --equatorial             scan in equatorial system.
    # -p, --position_angle=<deg>   scan position angle w.r.t. 'horizontal'
    #                             (default: 0.0).
    # -i, --start_row=<float>      index of starting row (default: 0.0).
    # -D, --init_delay=<seconds>   initial delay (default: 3.0).
    # -d, --row_delay=<seconds>    delay between rows (default: 2.0).
    # -q, --query                  Query current scans remaining only.
    # -w, --wait                   Wait for the OTF to complete before returning
    #                             prompt.You may use it to wait on an ongoing
    #                             scan as well.
    # -b, --bell                   Ring bell when complete (use together with -w).
    # -T, --time                   Just print the estimated time of completion (in
    #                             seconds).

    # Help options
    # -?, --help                   Show this help message
    # --usage                      Display brief usage message

    return 0;
}

# observeTargetLoopOTF($gainSouString0, $intLengthGain0,
#                      $gainSouString1, $intLengthGain1,
#                      $scienceSouString, $intLengthTarget,
#                      $numLoopsOTF, $rowLengthOTF,
#                      $rowOffsetOTF, $nRowsOTF,
#                      $posAngleOTF,
#                      $scanSpeedOTF,
#                      $numOTFperLoop,
#                      $nIterPoint,
#                      $figureFlag)
#
# Perform a gain calibration observation of the sources $gainSouString0 and
# $gainSouString1 for $intLengthGain0 and $intLengthGain1 seconds,
# respectively, with $ncal0 and $ncal1 integrations, respectively.  Then
# perform an OTF observation of the source $scienceSouString for
# $intLengthTarget seconds, with row length $rowLengthOTF, row offset
# $rowOffsetOTF, and number of rows $nRowsOTF, and position angle
# $posAngleOTF.  Repeat this loop $numLoopsOTF times.
#
# Returns 0 on success.
sub observeTargetLoopOTF {
    my (
        $gainSouString0, $intLengthGain0,
        $gainSouString1, $intLengthGain1,
        $scienceSouString, $intLengthTarget,
        $numLoopsOTF, $rowLengthOTF,
        $rowOffsetOTF, $nRowsOTF,
        $posAngleOTF,
        $scanSpeedOTF,
        $numOTFperLoop,
        $nIterPoint, $figureFlag
    ) = @_;
    $posAngleOTF = $posAngleOTF || "0.0";
    $numLoopsOTF = $numLoopsOTF || 1;
    $nIterPoint = $nIterPoint || 6;
    $figureFlag = $figureFlag || 0;
    # Only support -f (figure) flag for resuming from last completed loop
    my $resume_loop = 0;
    if ($figureFlag) {
        print "Figure flag detected: attempting to resume from last completed loop.\n";
        if (open(my $fh, '<', 'restartfile.txt')) {
            while (my $line = <$fh>) {
                if ($line =~ /last_loop=(\d+)/) {
                    $resume_loop = $1;
                    print "Resuming from loop $resume_loop.\n";
                }
            }
            close($fh);
        }
    }

    # Print the total number of maps that will be run:
    my $totalMaps = $numLoopsOTF * $numOTFperLoop;
    print "Total number of maps to run: $totalMaps\n";
    print "Number of maps per loop: $numOTFperLoop\n";
    print "Number of loops: $numLoopsOTF\n";

    my $loopCount = $resume_loop;
    while ($loopCount < $numLoopsOTF) {
        print "########################################\n";
        print "########################################\n";
        print "Starting OTF loop $loopCount\n";
        print "Loop $loopCount of $numLoopsOTF for $scienceSouString\n";
        print "Gain cals are $gainSouString0 and $gainSouString1\n";
        print "########################################\n";
        print "########################################\n";

        observeGainTarget($gainSouString0, $ncal0, $intLengthGain0, 1);
        observeGainTarget($gainSouString1, $ncal1, $intLengthGain1, 1);

        my $mapsPerLoopCounter = 0;
        while ($mapsPerLoopCounter < $numOTFperLoop) {
            # Only print when $numOTFperLoop > 1
            if ($numOTFperLoop > 1) {
                print "Starting OTF map $mapsPerLoopCounter of $numOTFperLoop\n";
            }

            # Start row 1
            my $resultOTF1 = observeTargetOTF($scienceSouString,
                            $intLengthTarget,
                            $rowLengthOTF,
                            $rowOffsetTwice,
                            $nRows2,
                            $posAngleOTF ,
                            $startRow2,
                            $scanSpeedOTF);

            # if 1 is returned, skip to end of loop
            if ($resultOTF1 == 1) {
                print "Source not observable. Skipping to end of loop.\n";
                last;
            }

            $mapsPerLoopCounter++;
        }

        # if 1 is returned, skip to end of loop
        if ($resultOTF1 == 1) {
            print "Source not observable. Skipping to end of loop.\n";
            last;
        }

        # Write to restartfile.txt.
        writefile($loopCount, $i, 0, $numLoopsOTF);

        if ($loopCount % $nIterPoint == 0) {
            print "Running ipoint\n";
            ipointRun($cal0);
        } else {
            print "Skipping ipoint\n";
        }

        $loopCount++;
    }

    print "########################################\n";
    print "########################################\n";
    print "Finished OTF loops $loopCount for $scienceSouString\n";
    print "########################################\n";
    print "########################################\n";

    print "########################################\n";
    print "Finishing observeTargetLoopOTF with final gain scans\n";
    print "########################################\n";
    observeGainTarget($gainSouString0, $ncal0, $intLengthGain0, 1);
    observeGainTarget($gainSouString1, $ncal1, $intLengthGain1, 1);

    print "########################################\n";
    print "Finishing observeTargetLoopOTF with final ipoint\n";
    print "########################################\n";
    ipointRun($ptgcal_final);

    return 0;
}



# observeTargetLoopOTFInterleave($gainSouString0, $intLengthGain0,
#                                $gainSouString1, $intLengthGain1,
#                                $scienceSouString, $intLengthTarget,
#                                $numLoopsOTF, $rowLengthOTF,
#                                $rowOffsetOTF, $nRowsOTF, $posAngleOTF,
#                                $scanSpeedOTF)
#
# Splits mapping into 2 interleaved parts.
# Useful for large maps that do not find within a 15 min gain loop
sub observeTargetLoopOTFInterleave {
    my (
        $gainSouString0, $intLengthGain0,
        $gainSouString1, $intLengthGain1,
        $scienceSouString, $intLengthTarget,
        $numLoopsOTF, $rowLengthOTF,
        $rowOffsetOTF, $nRowsOTF, $posAngleOTF,
        $scanSpeedOTF, $nIterPoint, $figureFlag
    ) = @_;
    $posAngleOTF = $posAngleOTF || "0.0";
    $scanSpeedOTF = $scanSpeedOTF || "4.5";
    $nIterPoint = $nIterPoint || 3;
    $figureFlag = $figureFlag || 0;

    # Only support -f (figure) flag for resuming from last completed loop
    my $resume_loop = 0;
    if ($figureFlag) {
        print "Figure flag detected: attempting to resume from last completed loop.\n";
        if (open(my $fh, '<', 'restartfile.txt')) {
            while (my $line = <$fh>) {
                if ($line =~ /last_loop=(\d+)/) {
                    $resume_loop = $1;
                    print "Resuming from loop $resume_loop.\n";
                }
            }
            close($fh);
        }
    }

    # Splits mapping into 2 interleaved parts.
    my $rowOffsetTwice = $rowOffsetOTF * 2;
    my $startRow1 = 0;
    my $nRows1 = floor($nRowsOTF / 2);
    my $startRow2 = 0.5;
    my $nRows2 = ceil($nRowsOTF / 2);

    my $loopCount = $resume_loop;
    while ($loopCount < $numLoopsOTF) {
        print "########################################\n";
        print "########################################\n";
        print "Starting OTF interleaved loop $loopCount\n";
        print "Loop $loopCount of $numLoopsOTF for $scienceSouString\n";
        print "Gain cals are $gainSouString0 and $gainSouString1\n";
        print "########################################\n";
        print "########################################\n";

        observeGainTarget($gainSouString0, $ncal0, $intLengthGain0, 1);
        observeGainTarget($gainSouString1, $ncal1, $intLengthGain1, 1);

        # Start row 0.
        my $resultOTF0 = observeTargetOTF($scienceSouString,
                         $intLengthTarget,
                         $rowLengthOTF,
                         $rowOffsetTwice,
                         $nRows1,
                         $posAngleOTF ,
                         $startRow1,
                         $scanSpeedOTF);


        # if 1 is returned, skip to end of loop
        if ($resultOTF0 == 1) {
            print "Source not observable. Skipping to end of loop.\n";
            last;
        }

        observeGainTarget($gainSouString0, $ncal0, $intLengthGain0, 1);
        observeGainTarget($gainSouString1, $ncal1, $intLengthGain1, 1);

        # Start row 1
        my $resultOTF1 = observeTargetOTF($scienceSouString,
                         $intLengthTarget,
                         $rowLengthOTF,
                         $rowOffsetTwice,
                         $nRows2,
                         $posAngleOTF ,
                         $startRow2,
                         $scanSpeedOTF);

        # if 1 is returned, skip to end of loop
        if ($resultOTF1 == 1) {
            print "Source not observable. Skipping to end of loop.\n";
            last;
        }

        # Write to restartfile.txt.
        # Here we consider a single loop is both interleaved parts.
        writefile($loopCount, $i, 0, $numLoopsOTF);

        if ($loopCount % $nIterPoint == 0) {
            print "Running ipoint\n";
            ipointRun($cal0);
        } else {
            print "Skipping ipoint\n";
        }

        $loopCount++;
    }

    print "########################################\n";
    print "########################################\n";
    print "Finished OTF interleaved loops $loopCount for $scienceSouString\n";
    print "########################################\n";
    print "########################################\n";

    print "########################################\n";
    print "Finishing observeTargetLoopOTFInterleave with final gain scans\n";
    print "########################################\n";
    observeGainTarget($gainSouString0, $ncal0, $intLengthGain0, 1);
    observeGainTarget($gainSouString1, $ncal1, $intLengthGain1, 1);

    print "########################################\n";
    print "Finishing observeTargetLoopOTFInterleave with final ipoint\n";
    print "########################################\n";
    ipointRun($ptgcal_final);

    return 0;
}


# observeTargetLoopOTFInterleaveMulti(
#   $gainSouString0, $intLengthGain0,
#   $gainSouString1, $intLengthGain1,
#   \@scienceSouStringList, $intLengthTarget,
#   $rowLengthOTF, $rowOffsetOTF, $nRowsOTF, $posAngleOTF,
#   $scanSpeedOTF, $nIterPoint, $figureFlag)
#
# Iterates through a list of science targets, performing interleaved OTF mapping for each.
sub observeTargetLoopOTFInterleaveMulti {
    my (
        $gainSouString0, $intLengthGain0,
        $gainSouString1, $intLengthGain1,
        $scienceSouStringListRef, $intLengthTarget,
        $rowLengthOTF, $rowOffsetOTF, $nRowsOTF, $posAngleOTF,
        $scanSpeedOTF, $nIterPoint, $figureFlag
    ) = @_;
    $posAngleOTF = $posAngleOTF || "0.0";
    $scanSpeedOTF = $scanSpeedOTF || "4.5";
    $nIterPoint = $nIterPoint || 3;
    $figureFlag = $figureFlag || 0;

    my @scienceSouStringList = @{$scienceSouStringListRef};

    # Only support -f (figure) flag for resuming from last completed target
    my $resume_target = 0;
    if ($figureFlag) {
        print "Figure flag detected: attempting to resume from last completed target.\n";
        if (open(my $fh, '<', 'restartfile.txt')) {
            while (my $line = <$fh>) {
                if ($line =~ /last_target=(\d+)/) {
                    $resume_target = $1;
                    print "Resuming from target $resume_target.\n";
                }
            }
            close($fh);
        }
    }

    for (my $targetIdx = $resume_target; $targetIdx < scalar(@scienceSouStringList); $targetIdx++) {
        my $scienceSouString = $scienceSouStringList[$targetIdx];
        print "########################################\n";
        print "########################################\n";
        print "Starting OTF interleaved mapping for target $targetIdx: $scienceSouString\n";
        print "Gain cals are $gainSouString0 and $gainSouString1\n";
        print "########################################\n";
        print "########################################\n";

        observeGainTarget($gainSouString0, $ncal0, $intLengthGain0, 1);
        observeGainTarget($gainSouString1, $ncal1, $intLengthGain1, 1);

        # Interleaved mapping for this target
        my $rowOffsetTwice = $rowOffsetOTF * 2;
        my $startRow1 = 0;
        my $nRows1 = floor($nRowsOTF / 2);
        my $startRow2 = 0.5;
        my $nRows2 = ceil($nRowsOTF / 2);

        # Start row 0.
        my $resultOTF0 = observeTargetOTF($scienceSouString,
                         $intLengthTarget,
                         $rowLengthOTF,
                         $rowOffsetTwice,
                         $nRows1,
                         $posAngleOTF ,
                         $startRow1,
                         $scanSpeedOTF);


        # if 1 is returned, skip to end of loop
        if ($resultOTF0 == 1) {
            print "Source not observable. Skipping to end of loop.\n";
            last;
        }

        observeGainTarget($gainSouString0, $ncal0, $intLengthGain0, 1);
        observeGainTarget($gainSouString1, $ncal1, $intLengthGain1, 1);

        # Start row 1
        my $resultOTF1 = observeTargetOTF($scienceSouString,
                         $intLengthTarget,
                         $rowLengthOTF,
                         $rowOffsetTwice,
                         $nRows2,
                         $posAngleOTF ,
                         $startRow2,
                         $scanSpeedOTF);

        # if 1 is returned, skip to end of loop
        if ($resultOTF1 == 1) {
            print "Source not observable. Skipping to end of loop.\n";
            last;
        }
        # Write to restartfile.txt.
        # Here we consider a single target is both interleaved parts.
        open(my $rfh, '>', 'restartfile.txt');
        print $rfh "last_target=$targetIdx\n";
        close($rfh);

        if ($targetIdx % $nIterPoint == 0) {
            print "Running ipoint\n";
            ipointRun($cal0);
        } else {
            print "Skipping ipoint\n";
        }
    }

    print "########################################\n";
    print "########################################\n";
    print "Finished OTF interleaved mapping for all targets\n";
    print "########################################\n";
    print "########################################\n";

    print "########################################\n";
    print "Finishing observeTargetLoopOTFInterleaveMulti with final gain scans\n";
    print "########################################\n";
    observeGainTarget($gainSouString0, $ncal0, $intLengthGain0, 1);
    observeGainTarget($gainSouString1, $ncal1, $intLengthGain1, 1);

    print "########################################\n";
    print "Finishing observeTargetLoopOTFInterleaveMulti with final ipoint\n";
    print "########################################\n";
    ipointRun($cal0);

    return 0;
}
