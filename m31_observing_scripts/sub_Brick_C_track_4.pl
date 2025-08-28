#!/usr/bin/perl -w
{ BEGIN {$^W =0}

use POSIX;

#
################## Script Header Info #####################
#
# Experiment Code: 2024B-S057
# Experiment Title:  A complete CO(2-1) Map of M31 with SMA OTF mapping
# PI: Eric Koch
# Contact Person: Eric Koch
# Email  : koch.eric.w@gmail.com
# Office :
# Home   :
# Array  : subcompact
#
#
############## SPECIAL INSTRUCTIONS ################
#
# See the README for details on these custom observing scripts!
# README: https://docs.google.com/document/d/1B1pvD3elZDKuLlVj8Rohqo2O7C9w_2TXmPG6Em1PhGY/edit?usp=sharing
#
# Key points:
# 1. The custom OTF observing commands are all contained in this script.
# 2. The science targets will be observed in the order from @mainTarg.
#    This order is printed to terminal whenever the script is run.
# 3. The OTF map parameters are the same for all M31 OTF maps. Only the center location changes.
# 4. Each map name will be observed "twice", interleaved with gain calibrator scans in the middle.
#   This is because each otf command observes every 2nd row:
#   the first otf call covers even rows; the second otf call covers odd rows.
# 5. Hand-over at 2nd shift should use the -f flag! However, each iteration is the pair
#    of odd and even rows. This may lead to reobserving the first half of the map twice on
#    restart. THAT IS OK!
# 6. A single gain calibrator is observed. The primary is 0136+478. If it's elevation is too
#    low, then 0013+408 will be observed. Otherwise 0036+478 is skipped.
# 7. ipoints are automatically run every 5th iteration (so ~2.5 h intervals). The standard
#    bp and flux cal commands will use the normal automated ipoint routines.
#
################## Priming ################################
#
# observe -s M31-Brick-A-Row-1-Col-7 -r 0:45:16.87632 -d 41:40:09.3108 -e 2000 -v -296
# dopplerTrack -S M31-Brick-A-Row-1-Col-7 -r 230.538 -u -s1 -f 0.0 -h 10 -R h -r 230.538 -u -s1 -f 0.0 -h 10
#
################## Pointing ###############################
#
# Pointing: None requested
# Syntax Example: point -i 60 -r 3 -L -l -t -Q
#
################## Source, Calibrator and Limits ##########
#
$inttime="30";
$inttime_sci="0.6";
$inttime_gain="15";


# Input all science targets here.

# Example:
# my @mainTarg = (
#     "M82_a -r 09:55:59.7  -d +69:40:55 -e 2000 -v 270",
#     "M82_b -r 09:55:59.7  -d +69:40:55 -e 2000 -v 270"
# );

my @mainTarg = (
    "M31-Brick-C-Row-1-Col-4 -r 0:43:08.87904 -d 41:07:22.818 -e 2000 -v -296",
"M31-Brick-C-Row-2-Col-4 -r 0:42:32.15832 -d 41:12:24.0048 -e 2000 -v -296",
"M31-Brick-C-Row-3-Col-4 -r 0:41:55.34352 -d 41:17:24.4572 -e 2000 -v -296",
"M31-Brick-C-Row-1-Col-3 -r 0:42:26.688 -d 40:56:25.368 -e 2000 -v -296",
"M31-Brick-C-Row-2-Col-3 -r 0:41:50.01576 -d 41:01:25.7124 -e 2000 -v -296",
"M31-Brick-C-Row-3-Col-3 -r 0:41:13.2504 -d 41:06:25.326 -e 2000 -v -296",
"M31-Brick-C-Row-1-Col-4 -r 0:43:08.87904 -d 41:07:22.818 -e 2000 -v -296",
"M31-Brick-C-Row-2-Col-4 -r 0:42:32.15832 -d 41:12:24.0048 -e 2000 -v -296",
"M31-Brick-C-Row-3-Col-4 -r 0:41:55.34352 -d 41:17:24.4572 -e 2000 -v -296",
"M31-Brick-C-Row-1-Col-3 -r 0:42:26.688 -d 40:56:25.368 -e 2000 -v -296",
"M31-Brick-C-Row-2-Col-3 -r 0:41:50.01576 -d 41:01:25.7124 -e 2000 -v -296",
"M31-Brick-C-Row-3-Col-3 -r 0:41:13.2504 -d 41:06:25.326 -e 2000 -v -296",
"M31-Brick-C-Row-1-Col-4 -r 0:43:08.87904 -d 41:07:22.818 -e 2000 -v -296",
"M31-Brick-C-Row-2-Col-4 -r 0:42:32.15832 -d 41:12:24.0048 -e 2000 -v -296",
"M31-Brick-C-Row-3-Col-4 -r 0:41:55.34352 -d 41:17:24.4572 -e 2000 -v -296"
);

print "The science loop will follow this order: \n";
foreach my $item (@mainTarg) {
    print "$item\n";
}
print "\n";
print "\n";

# OTF map parameters. Same for all M31 OTF maps (only the target location changes)
$rowLength0 = "840";  # arcsec
$rowOffset0 = "27.5";  # arcsec
$nRows0 = "22";
$posAngle0 = "54";

$scanSpeedOTF0 = "11.45";  # "/s


# Gaincal setup
$cal0="0136+478"; $ncal0="6";
$cal1="0013+408"; $ncal1="6";

# Flux cal setup
$flux0="mwc349a"; $nflux0="10";
$flux1="uranus"; $nflux1="10";

# Bandpass setup
$bpass0="bllac"; $nbpass0="60";
$bpass1="3c84"; $nbpass1="60";

# Use 3c84 since it's at a higher elevation at the end of the science loop
$finalptgcal='3c84';

$MINEL_TARG = 32; $MAXEL_TARG = 83;
$MINEL_GAIN = 32; $MAXEL_GAIN = 83;
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
command("project -r -p 'Koch' -d '2024B-S057'");
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


print "----- M31  science target observe loop -----\n";
# -- loops for up to 8.5 hr
observeTargetLoopOTFInterleaveMulti($cal0,$inttime_gain,
                                    $cal1,$inttime_gain,
                                    \@mainTarg,$inttime_sci,
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
    $nIterPoint = $nIterPoint || 5;
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

        my $gain0_result = observeGainTarget($gainSouString0, $ncal0, $intLengthGain0, 1);
        if ($gain0_result == 1) {
            observeGainTarget($gainSouString1, $ncal1, $intLengthGain1, 1);
        }

        # Interleaved mapping for this target
        my $rowOffsetTwice = $rowOffsetOTF * 2;
        my $startRow1 = 0;
        my $nRows1 = floor($nRowsOTF / 2);
        my $startRow2 = 0.5;
        my $nRows2 = ceil($nRowsOTF / 2);

        # Start row 0.
        observeTargetOTF($scienceSouString,
                         $intLengthTarget,
                         $rowLengthOTF,
                         $rowOffsetTwice,
                         $nRows1,
                         $posAngleOTF ,
                         $startRow1,
                         $scanSpeedOTF);

        # NOTE: b/c 0136+478 is ~2 Jy in Fall 2025, we only use it for gain cal.
        # Early in the night, it has too low elevation so we instead use the secondary
        # gain cal.
        $gain0_result = observeGainTarget($gainSouString0, $ncal0, $intLengthGain0, 1);
        if ($gain0_result == 1) {
            print "Primary gain cal unavailable. Using secondary gain cal\n";
            observeGainTarget($gainSouString1, $ncal1, $intLengthGain1, 1);
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
    ipointRun($finalptgcal);

    return 0;
}
