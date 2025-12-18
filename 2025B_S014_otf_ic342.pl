#!/usr/bin/perl -w
{ BEGIN {$^W =0}

use POSIX;

#
################## Script Header Info #####################
#
# Experiment Code: 2025B-S013
# Experiment Resolved CO excitation across the Milky-Way Analog Galaxy IC342
# PI: Jakob den Brok
# Contact Person: Jakob den Brok
# Email  : jakob.denbrok@cfa.harvard.edu; eric.koch@cfa.harvard.edu
# Office :
# Home   :
# Array  : compact
#
#
############## SPECIAL INSTRUCTIONS ################
#
# See the README for details on these custom observing scripts!
# README: https://docs.google.com/document/d/1B1pvD3elZDKuLlVj8Rohqo2O7C9w_2TXmPG6Em1PhGY/edit?usp=sharing
#
# This script is similar to the M31 OTF tracks from 2024B.
# It's simpler though: only a single map is repeated.
#
# Key points:
# 1. The custom OTF observing commands are all contained in this script.
# 2. Each map will be observed "twice", interleaved with gain calibrator scans in the middle.
#   This is because each otf command observes every 2nd row:
#   the first otf call covers even rows; the second otf call covers odd rows.
# 5. Hand-over at 2nd shift can use the -r flag. The loop should just continue, there is no need
#.   to alter the target order like with the M31 tracks.
# 6. A single gain calibrator is observed. The primary is 0136+478. If it's elevation is too
#    low, then 0013+408 will be observed. Otherwise 0036+478 is skipped.
# 7. ipoints are automatically run every 5th iteration (so ~2.5 h intervals). The standard
#    bp and flux cal commands will use the normal automated ipoint routines.
#
################## Priming ################################
#
# observe -s IC342 -r 03:46:48.721  -d +68:05:51.224 -e 2000 -v -30
# dopplerTrack -S IC342 -r 230.538 -u -s1 -f 0.0 -h 10 -R h -r 230.538 -u -s1 -f 0.0 -h 10
#
################## Pointing ###############################
#
# Pointing: None requested
# Syntax Example: point -i 60 -r 3 -L -l -t -Q
#
################## Source, Calibrator and Limits ##########
#
$inttime="30";

# These maps are a bit smaller. We don't need the 0.6 integration times.
$inttime_sci="0.6";
$inttime_gain="15";


# OTF map parameters.
# 12 min per half-map + 3 min on gain cals
# 30 min for full map + gain loop
$targ0="IC342 -r 03:46:48.418  -d +68:05:53.35 -e 2000 -v -30";

$rowLength0 = "600";  # arcsec
$rowOffset0 = "27.5";  # arcsec
$nRows0 = "24";
$posAngle0 = "0";

# This should be enough to always reach when IC342 sets.
$nmaps0 = "15";

$scanSpeedOTF0 = "7.64";  # "/s

# Gaincal setup
$cal0="0359+509"; $ncal0="6"; # for IC342 (currently, Dec 2025, flux of ~2.8Jy)
$cal1="0228+673"; $ncal1="8"; #for IC342 (currently, Dec 2025, flux of ~0.7Jy)
$cal2="0721+713"; $ncal2="8"; #for IC342 (currently, Dec 2025, flux of ~0.9Jy)

# Flux cal setup
$flux0="mwc349a"; $nflux0="10";
$flux1="uranus"; $nflux1="10";

# Bandpass setup
$bpass0="3c84"; $nbpass0="60";
$bpass1="3c279"; $nbpass1="60";

# Use 3c279 since it's at a higher elevation at the end of the science loop
$finalptgcal='3c279';

$MINEL_TARG = 17; $MAXEL_TARG = 83;
$MINEL_GAIN = 17; $MAXEL_GAIN = 83;
$MINEL_FLUX = 17; $MAXEL_FLUX = 81;
$MINEL_BPASS= 17; $MAXEL_BPASS= 87;
$MINEL_CHECK= 19;


#
################## Script Initialization ##################
#
do 'sma.pl';
do 'sma_add.pl';
checkANT();
command("radio");
command("integrate -t $inttime");
$myPID=$$;
command("project -r -p 'den Brok' -d '2025B-S013'");
print "----- initialization done, starting script -----\n";


#
################## Science Script #########################
#



print "Script resumed with -f flag? $opt_figure \n";


print "----- initial flux and bandpass calibration -----\n";
if(!$restart){
  &DoPass(bpass0,nbpass0);
  &DoFlux(flux0,nflux0);
  &DoFlux(flux1,nflux1);
}


print "----- IC342  science target observe loop -----\n";
# -- loops for until source has set.
observeTargetLoopOTFInterleave($cal0,$inttime_gain,
                               $cal1,$inttime_gain,
                               $cal2,$inttime_gain,
                               $targ0,$inttime_sci,
                               $nmaps0,
                               $rowLength0,$rowOffset0,$nRows0,$posAngle0,
                               $scanSpeedOTF0,
                               $opt_figure);

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

    # OTF can take up to ~15 min. To avoid hitting elevation limits during the
    # OTF scan, add a small el buffer to the minumum.
    my $elLimitBuffer = 1.5;

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
        $gainSouString2, $intLengthGain2,
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

        my $gain0_result = observeGainTarget($gainSouString0, $ncal0, $intLengthGain0, 1);
        my $gain1_result = observeGainTarget($gainSouString1, $ncal1, $intLengthGain1, 1);
        if ($gain0_result == 1 and $gain1_result == 1) {
            observeGainTarget($gainSouString2, $ncal2, $intLengthGain2, 1);
        }

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

        my $gain0_result = observeGainTarget($gainSouString0, $ncal0, $intLengthGain0, 1);
        my $gain1_result = observeGainTarget($gainSouString1, $ncal1, $intLengthGain1, 1);
        if ($gain0_result == 1 and $gain1_result == 1) {
            observeGainTarget($gainSouString2, $ncal2, $intLengthGain2, 1);
        }

        # Start row 1
        observeTargetOTF($scienceSouString,
                         $intLengthTarget,
                         $rowLengthOTF,
                         $rowOffsetTwice,
                         $nRows2,
                         $posAngleOTF ,
                         $startRow2,
                         $scanSpeedOTF);

        # if 1 is returned, skip to end of loop
        if ($resultOTF0 == 1) {
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
    my $gain0_result = observeGainTarget($gainSouString0, $ncal0, $intLengthGain0, 1);
    my $gain1_result = observeGainTarget($gainSouString1, $ncal1, $intLengthGain1, 1);
    if ($gain0_result == 1 and $gain1_result == 1) {
        observeGainTarget($gainSouString2, $ncal2, $intLengthGain2, 1);
    }

    return 0;
}
