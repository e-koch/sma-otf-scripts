
import numpy as np
import astropy.units as u

from warnings import warn


def sma_pb_fwhm(freq):

    dish_diameter = 6 * u.m

    lambda_ = freq.to(u.m, u.spectral())

    fwhm = 1.2 * ((lambda_.to(u.m) / dish_diameter.to(u.m)) * u.rad).to(u.arcsec)

    return fwhm


def otf_mapping_params(row_length, row_width,
                       time_per_track,
                       theta_pb=55*u.arcsec,
                       reffreq_pb=230*u.GHz,
                       oversample_row_space=2.,
                       time_per_beam=1*u.min,
                       t_dump=1.7 * u.s,
                       beam_per_dump=0.1,
                       t_loop=15 * u.min,
                       t_gain=3 * u.min,
                       t_delay=3*u.s,
                       t_row_delay=2*u.s,
                       t_ramp=3*u.s,
                       verbose=True,
                      ):
    '''
    Calculate the required OTF time and mapping parameters.

    Parameters
    ----------
    row_length : `~astropy.units.Quantity`
        Length of a row in angular units.
    row_width : `~astropy.units.Quantity`
        Width of a row in angular units.
    time_per_track : `~astropy.units.Quantity`
        Time per track. Total time a source is above the elevation limits (depends on SMA configuration).
    theta_pb : `~astropy.units.Quantity` or None.
        Primary beam size in angular units. Default is 55 arcsec at 230 GHz.
    reffreq_pb : `~astropy.units.Quantity`
        Reference frequency for primary beam size. Used if theta_pb is None. See `sma_pb_fwhm`.
    oversample_row_space : float
        Oversampling factor for row spacing.
    time_per_beam : `~astropy.units.Quantity`
        Time per beam in units of time.
    t_dump : `~astropy.units.Quantity`
        Time per dump.
    beam_per_dump : float
        Number of primary beams per dump. To avoid smearing, this should always be less than 0.125 (1/8 of the primary beam).
    t_loop : `~astropy.units.Quantity`
        Maximum time per gain loop. Maps exceeding this limit should reduce the requested size,
        or use a interleaing scheme splitting the map in half per gain loop.
    t_gain : `~astropy.units.Quantity`
        Total for gain calibration per loop.
    t_delay : `~astropy.units.Quantity`
        Time per delay startup for online OTF command.
    t_row_delay : `~astropy.units.Quantity`
        Time delay per row delay.
    t_ramp : `~astropy.units.Quantity`
        Time per row for scanning ramp up.
    verbose : bool
        Print mapping parameters to screen.

    Returns
    -------
    out_dict : dict
        Dictionary of mapping parameters.

    '''

    # Ensure required args have the correct units
    if not row_length.unit.is_equivalent(u.arcmin):
        raise ValueError('row_length must be in angular units.')

    if not row_width.unit.is_equivalent(u.arcmin):
        raise ValueError('row_width must be in angular units.')

    if not time_per_track.unit.is_equivalent(u.h):
        raise ValueError('time_per_track must be in units of time.')


    # Set recomended lower limits on parameters
    if oversample_row_space < 2:
        warn('oversample_row_space < 2. Recomended minimum value is 2.')

    if t_dump < 0.6 * u.s:
        warn('t_dump < 0.6s. Recomended minimum value is 0.6s for SWARM correlator.')

    if t_loop > 15 * u.min:
        warn('t_loop > 15min. Recomended maximum value is 15 min (includes gain calibration time).')

    if t_delay < 3 * u.s:
        warn('t_delay < 3s. Recomended minimum value is 3s.')

    if t_ramp < 3 * u.s:
        warn('t_ramp < 3s. Recomended minimum value is 3s.')

    if t_row_delay < 2 * u.s:
        warn('t_row_delay < 2s. Recomended minimum value is 2s.')

    if t_gain < 3 * u.min:
        warn('t_gain < 3min. Recomended minimum value is 3min.')

    if beam_per_dump > 0.125:
        warn('beam_per_dump > 0.125. Recomended maximum value is 0.125. Large values will smear the beam.')

    # Calculate theta_pb if not provided
    if theta_pb is None:
        theta_pb = sma_pb_fwhm(reffreq_pb)
        if verbose:
            print(f'Using theta_pb = {theta_pb:.2f} for reffreq_pb = {reffreq_pb}.')


    R_target = theta_pb * beam_per_dump / t_dump

    total_area = row_length * row_width

    beam_area = 0.5665 * theta_pb.to(u.arcmin).value**2 * u.arcmin**2

    N_eff = (total_area / beam_area).to(u.one)

    time_all_beams = (N_eff * time_per_beam)

    theta_row = theta_pb / oversample_row_space

    N_beam_row = (row_length / theta_pb).to(u.one)

    # Add 1 to account for start/end integration per row (if we need it)
    t_row = (row_length / R_target).to(u.min)

    # Account for that total area coverage at ~full sensitivity. Thus, add 1 PB
    # to the overall width.
    Nrow = np.ceil(((row_width + theta_pb) / theta_row).to(u.one))

    # NOTE: this matches the online otf time estimate. The true time may have
    # -t_row_delay - t_ramp if after each row.
    t_otf_map = t_delay + Nrow * (t_row + t_row_delay + t_ramp)

    N_otf_maps = (time_all_beams / t_otf_map).to(u.one)

    # Add mapping overheads
    # Overhead. Assume we need 1 gain cal scan per 15 min.
    N_gain = np.ceil((t_otf_map / (t_loop - t_gain)).to(u.one)) # - 1

    t_otf_map_total = (t_otf_map + N_gain * t_gain).to(u.h)

    t_total_mapping_time = N_otf_maps * t_otf_map_total

    N_tracks = t_total_mapping_time / time_per_track

    maps_per_track = np.ceil(N_otf_maps) / N_tracks

    out_dict = dict(row_length=row_length,
                   row_width=row_width,
                   total_area=row_length*row_width,
                   beam_area=beam_area,
                   N_eff=N_eff,
                   time_all_beams=time_all_beams.to(u.hr),
                   time_per_beam=time_per_beam,
                   theta_row=theta_row,
                   N_beam_row=N_beam_row,
                   R_target=R_target,
                   t_row=t_row,
                   Nrow=Nrow,
                   t_otf_map=t_otf_map.to(u.min),
                   N_otf_maps=N_otf_maps,
                   N_gain=N_gain,
                   t_otf_map_total=t_otf_map_total.to(u.hr),
                   t_total_mapping_time=t_total_mapping_time.to(u.hr),
                   N_tracks=N_tracks,
                   maps_per_track=maps_per_track)

    if verbose:
        for key in out_dict:
            print(key, out_dict[key])

    return out_dict


