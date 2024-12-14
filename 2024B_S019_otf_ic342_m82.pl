#!/usr/bin/perl -w
{ BEGIN {$^W =0}

use POSIX;

#
################## Script Header Info #####################
#
# Experiment Code: 2024B-S019
# Experiment Revealing the resolved molecular gas across the M81 group
# PI: Eric Koch, Jakob den Brok
# Contact Person: Eric Koch, Jakob den Brok
# Email  : eric.koch@cfa.harvard.edu
# Office :
# Home   :
# Array  : compact
#
#
############## SPECIAL INSTRUCTIONS ################
#
# none
#
################## Priming ################################
#
# observe -s M82 -r 09:55:52.7  -d +69:40:46 -e 2000 -v 270
# dopplerTrack -S M82 -r 230.538 -u -s1 -f 0.0 -h 10 -R h -r 230.538 -u -s1 -f 0.0 -h 10
#
################## Pointing ###############################
#
# Pointing: None requested
# Syntax Example: point -i 60 -r 3 -L -l -t -Q
#
################## Source, Calibrator and Limits ##########
#
$inttime="30";
$inttime_sci="1.2";  # 4.5"/s mapping speed at 230 GHz
$inttime_gain="15";

# $scanSpeedOTF = "4.5";  # "/s

# M82 map params
# 12 min per half-map + 3 min on gain cals
# 30 min for full map + gain loop
$targ0="M82 -r 09:55:59.7  -d +69:40:55 -e 2000 -v 270";
$nmaps0="8"; # for M81-group
#  -- loops for 4.25 hr
$rowLength0 = "360";  # arcsec
$rowOffset0 = "39";  # arcsec
$nRows0 = "10";
$posAngle0 = "30";

$scanSpeedOTF0 = "3.2";  # "/s


# M81 map
# NGC2976 map
# NGC3077 map
# HI tail map

$cal0="0958+655"; $ncal0="6"; #for M82
$cal1="0841+708"; $ncal1="6"; #for M82


# IC342 params
# 12 min per half-map + 3 min on gain cals
# 30 min for full map + gain loop
$targ1="IC342 -r 03:46:34.8  -d +68:06:04 -e 2000 -v -30";
$nmaps1="10"; # for IC342
#  -- loops for 5 hr
$rowLength1 = "420";  # arcsec
$rowOffset1 = "39";  # arcsec
$nRows1 = "11";
$posAngle1 = "0";

# A bit slower than (0.0825 beams per integration) that maps to 12 min
# for half of the map.
$scanSpeedOTF1 = "3.8";  # "/s

$cal2="0228+673"; $ncal2="6"; #for IC342
$cal3="0359+509"; $ncal3="6"; #for IC342

$flux0="Uranus"; $nflux0="20";
$flux1="0319+415"; $nflux1="20";
$flux2="mwc349a"; $nflux2="20";
$flux3="Ceres"; $nflux3="20";
$timeflux="Ceres";$ntimeflux="10";$timeforflux="14.0";

$bpass0="0319+415"; $nbpass0="60";
$bpass1="3c279"; $nbpass1="60";


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
command("project -r -p 'Koch and den Brok' -d '2024B-S019'");
print "----- initialization done, starting script -----\n";
#
################## Science Script #########################
#
print "----- initial flux and bandpass calibration -----\n";
if(!$restart){
  #&DoPass(bpass0,nbpass0);
  &DoFlux(flux0,nflux0);
  #&DoFlux(flux1,nflux1);
}

print "----- IC342 science target observe loop -----\n";
# -- loops for 5 hr
observeTargetLoopOTFInterleave($cal2,$inttime_gain,
                     $cal3,$inttime_gain,
                     $targ1,$inttime_sci,
                     $nmaps1,$rowLength1,$rowOffset1,$nRows1,$posAngle1,
                     $scanSpeedOTF1);

print "----- M81-group science target observe loop -----\n";
# -- loops for 4 hr
observeTargetLoopOTFInterleave($cal0,$inttime_gain,
                     $cal1,$inttime_gain,
                     $targ0,$inttime_sci,$nmaps0,
                     $rowLength0,$rowOffset0,$nRows0,$posAngle0,
                     $scanSpeedOTF);

print "----- final flux and bandpass calibration -----\n";
  &DoFlux(flux0,nflux0);
  &DoFlux(flux3,nflux3);
  &DoPass(bpass1,nbpass1);
  &DoFlux(flux2,nflux2);

print "----- Congratulations!  This is the end of the script.  -----\n";}
#
################## File End ###############################

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

    command("observe -s $souString");
    command("integrate -t $intLength");
    command("tsys");
    command("antennaWait -e 4");

    command("integrate -t $intLength -w");
    command("otf -v $scanSpeed -l $rowLength -y $rowOffset -n $nRows -p $posAngle -i $startRow -e -w");

    #command("otf -v 3 -l 120 -y 10 -n 13 -e -w"); # for M82 initial test
    #command("otf -v 6.5 -l 420 -y 39 -n 9 -e -w"); # for IC342

    #     ```
    # Initiate raster scanning with the antennas.
    # Usage: otf [OPTION...]
    #   -a, --antenna=ARG          a comma-separated list of antennas
    #   -v, --speed=ARG            (arcsec/s) scan speed.
    #   -l, --length=ARG           (arcsec) scan length.
    #   -n, --rows=ARG             number of scan rows.
    #   -y, --step_y=ARG           (arcsec) step between rows, perpendicular to
    #                               motion.
    #   -x, --step_x=ARG           (arcsec) step between rows, along to motion
    #                               (default 0.0).
    #   -e, --equatorial           directions w.r.t. equatorial system.
    #   -p, --position_angle=ARG   (deg) scan position angle w.r.t. 'horizontal'
    #                               (default 0.0).
    #   -i, --start_row=ARG        index of starting row, fractional (default
    # 0.0).
    #   -D, --init_delay=ARG       (sec) initial delay (default 3.0).
    #   -d, --row_delay=ARG        (sec) delay between rows (default 2.0).
    #   -q, --query                Query current scans remaining only.
    #   -w, --wait                 Wait for the OTF to complete before
    #                               returning prompt.
    #   -T, --time                 Just print the estimated time of
    #                             completion (in seconds) without scanning.
    # ```

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
    $gainSouString0 = $_[0];
    $intLengthGain0 = $_[1];
    $gainSouString1 = $_[2];
    $intLengthGain1 = $_[3];
    $scienceSouString = $_[4];
    $intLengthTarget = $_[5];
    $numLoopsOTF = $_[6];
    $rowLengthOTF = $_[7];
    $rowOffsetOTF = $_[8];
    $nRowsOTF = $_[9];
    $posAngleOTF = $_[10] || "0.0";

    my $loopCount = 0;
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
        $loopCount++;
    }

    print "########################################\n";
    print "########################################\n";
    print "Finished OTF loops $loopCount for$scienceSouString\n";
    print "########################################\n";
    print "########################################\n";

    print "########################################\n";
    print "Finishing observeTargetLoopOTF with final gain scans\n";
    print "########################################\n";
    observeGainTarget($gainSouString0, $ncal0, $intLengthGain0, 1);
    observeGainTarget($gainSouString1, $ncal1, $intLengthGain1, 1);

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
    $gainSouString0 = $_[0];
    $intLengthGain0 = $_[1];
    $gainSouString1 = $_[2];
    $intLengthGain1 = $_[3];
    $scienceSouString = $_[4];
    $intLengthTarget = $_[5];
    $numLoopsOTF = $_[6];
    $rowLengthOTF = $_[7];
    $rowOffsetOTF = $_[8];
    $nRowsOTF = $_[9];
    $posAngleOTF = $_[10] || "0.0";  # default to 0.0
    $scanSpeedOTF = $_[11] || "4.5";  # default to 4.5"/s

    # Splits mapping into 2 interleaved parts.
    # Useful for large maps that do not find within a 15 min gain loop

    # Make rows 2x larger
    $rowOffsetTwice = $rowOffsetOTF * 2;

    # First half
    $startRow1 = 0;
    $nRows1 = floor($nRowsOTF / 2); # round down to nearest integer

    # Second half
    $startRow2 = 1;
    $nRows2 = ceil($nRowsOTF / 2);  # round up to nearest integer

    my $loopCount = 0;
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


        $loopCount++;
    }

    print "########################################\n";
    print "########################################\n";
    print "Finished OTF interleaved loops $loopCount for$scienceSouString\n";
    print "########################################\n";
    print "########################################\n";

    print "########################################\n";
    print "Finishing observeTargetLoopOTFInterleave with final gain scans\n";
    print "########################################\n";
    observeGainTarget($gainSouString0, $ncal0, $intLengthGain0, 1);
    observeGainTarget($gainSouString1, $ncal1, $intLengthGain1, 1);

    return 0;
}

