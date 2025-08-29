#!/usr/bin/perl -w
{ BEGIN {$^W =0}

use POSIX;

#
################## Script Header Info #####################
#
# Experiment Code: 2025A-S014
# Mapping CO across the Helix Planetary Nebula (NGC 7293) with the SMA's New OTF Mode
# PI: Joel Kastner
# Contact Person: Joel Kastner
# Email  : jhk@cis.rit.edu
# Office :
# Home   :
# Array  : subcompact
#
#
############## SPECIAL INSTRUCTIONS ################
#
# none
#
################## Priming ################################
#
# observe -s NGC7293 -r 22:29:38.545  -d -20:50:13.75 -e 2000 -v -23
# dopplerTrack -S NGC7293 -r 230.538 -u -s1 -f 0.0 -h 10 -R h -r 230.538 -u -s1 -f 0.0 -h 10
#
################## Pointing ###############################
#
# Pointing: None requested
# Syntax Example: point -i 60 -r 3 -L -l -t -Q
#
################## Source, Calibrator and Limits ##########
#
$inttime="30";
$inttime_sci="0.65";
$inttime_gain="10";


# Helix is up for ~3.62 h.
# Interleaved maps are tuned to take 42-44 min per map, incl. gains.

# Helix map params
# 17.8 min per interleaved half-map + 3 min on gain cals
# 42 min for half map + gain loop

# Lower half map (1150 x 440, with 27.5" spacing)
$targ0="NGC7293 -r 22:29:38.545 -d -20:50:13.75 -D '-220.0' -e 2000 -v '-23'";

$rowLength0 = "1150";  # arcsec
$rowOffset0 = "27.5";  # arcsec
$nRows0 = "16";
$posAngle0 = "0"; # 30 deg from decreasing RA orientation.
$scanSpeedOTF0 = "9.0";  # "/s

$nmaps0="5"; # numper of passes over track -- loops for up to 3.62h

$cal0="2158-150"; $ncal0="9"; #for NGC7293
$cal1="2258-279"; $ncal1="9"; #for NGC7293

$flux0="Uranus"; $nflux0="10";
$flux1="Callisto"; $nflux1="10";
#$flux2="mwc349a"; $nflux2="10";
#$flux3="Vesta"; $nflux3="10";

$bpass0="3c454.3"; $nbpass0="60";
$bpass1="3c84"; $nbpass1="60";

# Do final pointing on 3c273 as 0958+655 will be below the el limit
$ptgcal_final='3c273';

$MINEL_TARG = 33; $MAXEL_TARG = 83;
$MINEL_GAIN = 33; $MAXEL_GAIN = 83;
$MINEL_FLUX = 33; $MAXEL_FLUX = 81;
$MINEL_BPASS= 33; $MAXEL_BPASS= 87;
$MINEL_CHECK= 35;
#
################## Script Initialization ##################
#
do 'sma.pl';
do 'sma_add.pl';
checkANT();
command("radio");
command("integrate -t $inttime");
$myPID=$$;
command("project -r -p 'Joel Kastner' -d '2025A-S014'");
print "----- initialization done, starting script -----\n";
#
################## Science Script #########################
#
print "----- initial flux and bandpass calibration -----\n";
if(!$restart){
  &DoPass(bpass0,nbpass0);
  &DoFlux(flux0,nflux0);
  #&DoFlux(flux1,nflux1);
}


print "----- NGC7293 science target observe loop -----\n";
# -- loops for up to 11 hr
observeTargetLoopOTFInterleave($cal0,$inttime_gain,
                     $cal1,$inttime_gain,
                     $targ0,$inttime_sci,$nmaps0,
                     $rowLength0,$rowOffset0,$nRows0,$posAngle0,
                     $scanSpeedOTF0);

print "----- final flux and bandpass calibration -----\n";
  &DoFlux(flux0,nflux0);
  &DoFlux(flux1,nflux1);
  &DoPass(bpass1,nbpass1);

print "----- Congratulations!  This is the end of the script.  -----\n";}
#
################## File End ###############################



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
    if($targel < $MINEL_TARG)
        {
            print "Target elevation for $souString is $targel below min elevation limit of $MINEL_GAIN.  Skipping observation.\n";
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
        printf("[SIMULATION MODE] observeTargetOTF: Would observe %s for %d seconds, %d rows, scan speed %.2f arcsec/s. Estimated time: %.1f seconds.\n",
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
#                      $posAngleOTF)
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
        $posAngleOTF, $nIterPoint, $figureFlag
    ) = @_;
    $posAngleOTF = $posAngleOTF || "0.0";
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
        observeTargetOTF($scienceSouString, $intLengthTarget,
                         $rowLengthOTF, $rowOffsetOTF,
                         $nRowsOTF, $posAngleOTF );

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
        observeTargetOTF($scienceSouString,
                         $intLengthTarget,
                         $rowLengthOTF,
                         $rowOffsetTwice,
                         $nRows1,
                         $posAngleOTF ,
                         $startRow1,
                         $scanSpeedOTF);

        observeGainTarget($gainSouString0, $ncal0, $intLengthGain0, 1);
        observeGainTarget($gainSouString1, $ncal1, $intLengthGain1, 1);

        # Start row 1
        observeTargetOTF($scienceSouString,
                         $intLengthTarget,
                         $rowLengthOTF,
                         $rowOffsetTwice,
                         $nRows2,
                         $posAngleOTF ,
                         $startRow2,
                         $scanSpeedOTF);

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
