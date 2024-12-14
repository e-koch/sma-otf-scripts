
import numpy as np

import astropy.units as u
import astropy.constants as con
from astropy.modeling.models import BlackBody

from radio_beam import Beam


def sma_pb_fwhm(freq):

    dish_diameter = 6 * u.m

    lambda_ = freq.to(u.m, u.spectral())

    fwhm = 1.2 * ((lambda_.to(u.m) / dish_diameter.to(u.m)) * u.rad).to(u.arcsec)

    return fwhm


# wSMA optimistic 1 hr rms sensitivities:
# wsma_continuum_rms = {90: 0.083 * u.mJy,
#                       150: 0.092 * u.mJy,
#                       230: 0.143 * u.mJy,
#                       345: 0.565 * u.mJy,
#                       420: 1.245 * u.mJy,
#                       490: 6.616 * u.mJy,
#                       690: 11.028 * u.mJy,
#                      }

# UPDATE Oct. 31
wsma_continuum_rms = {90: 0.086 * u.mJy,
                      230: 0.169 * u.mJy,
                      345: 0.539 * u.mJy,
                      "230_curr": 0.84 * u.mJy,
                     }

# wsma_1kms_rms = {90: 0.0720 * u.Jy * u.km / u.s,
#                  150: 0.0603 * u.Jy * u.km / u.s,
#                  230: 0.0529 * u.Jy * u.km / u.s,
#                  345: 0.0856 * u.Jy * u.km / u.s,
#                  420: 0.3177 * u.Jy * u.km / u.s,
#                  490: 1.2670 * u.Jy * u.km / u.s,
#                  690: 0.8408 * u.Jy * u.km / u.s,
#                  }

# UPDATE Oct. 31
wsma_1kms_rms = {90: 0.0231 * u.Jy * u.km / u.s,
                 230: 0.0379 * u.Jy * u.km / u.s,
                 345: 0.0852 * u.Jy * u.km / u.s,
                 }

def make_wsma_intint_rms(sigma=5*u.km / u.s,
                         chan_width=2.5*u.km/u.s,):

    fwhm = 2.35 * sigma
    nchan_per_fwhm = np.floor(fwhm / chan_width)

    wsma_intint_rms = {}


    for band in wsma_1kms_rms:
        # This is rms(1 km/s) * sqrt(N chans over line profile) / sqrt(Target chan width / 1 km/s)
        rms_intint = wsma_1kms_rms[band] * np.sqrt(nchan_per_fwhm) / np.sqrt(chan_width.value)
        wsma_intint_rms[band] = rms_intint

    return wsma_intint_rms


def make_the_time(rms, rms_per_unit, unit_time=1 * u.hr):
    '''
    A single function for scaling time estimates.
    Because Eric mixes up 1/2 and 2 exponents too often.
    '''

    return unit_time * (rms_per_unit / rms).to(u.dimensionless_unscaled)**2


def make_the_time_continuum(rms, band, unit_time=1 * u.hr):
    '''
    '''

    rms_per_unit = wsma_continuum_rms[band]

    return make_the_time(rms, rms_per_unit, unit_time)


def make_the_time_line(rms, band,
                       unit_time=1 * u.hr,
                       rms_band_dict=wsma_1kms_rms):
    '''
    '''

    rms_per_unit = rms_band_dict[band]

    return make_the_time(rms, rms_per_unit, unit_time)


def time_to_rms(time, band,
                unit_time=1 * u.hr,
                rms_band_dict=wsma_1kms_rms):
    
    rms_per_unit = rms_band_dict[band]
    
    rms_per_time = rms_per_unit * np.sqrt((time / unit_time).to(u.one))
    
    return rms_per_time



# Dust opacity relations

def kappa_nu_chiang18(nu):

    lambda_0 = 160 * u.um
    nu_0 = lambda_0.to(u.GHz, u.spectral())

    # Fixed beta case:
    kappa_0 = 25.83 * u.cm**2 / u.g

    beta = 2.

    return kappa_0 * (nu / nu_0)**beta


def kappa_nu_MW(nu):

    lambda_0 = 160 * u.um
    nu_0 = lambda_0.to(u.GHz, u.spectral())

    # Fixed beta case:
    kappa_0 = 9.6 * u.cm**2 / u.g

    beta = 2.

    return kappa_0 * (nu / nu_0)**beta


# Metallicity scalings:

def mwdust_gdr(Z):
    return 136.



# CO line ratios from Leroy+22

R21_dB21 = 0.64
R21_dB21_range = [0.64 - 0.09, 0.64 + 0.09]

R21_l22 = 0.65
R21_range_l22 = [0.5, 0.83]

R31_l22 = 0.31
R31_range_l22 = [0.2, 0.42]

R32_l22 = 0.50
R32_range_l22 = [0.23, 0.59]



FWHM_TO_AREA = 2*np.pi/(8*np.log(2))

def alpha_to_X(alpha_CO, mu=2.7):
    return (alpha_CO / (mu * con.m_p)).to((u.cm**-2) / (u.K * u.km / u.s))



def h2mass_to_co_brightness(mh2,
                            alpha_CO=4.35*(u.solMass / u.pc**2) / (u.K * u.km / u.s),
                            R21=R21_l22,
                            R32=R32_l22,
                            distance=0.78 * u.Mpc,
                            beam_size=5*u.arcsec,
                            to_jy=True,
                            ):

    beam = Beam(beam_size.to(u.arcsec))

    # phys_scale = (beam_size.to(u.rad).value * distance).to(u.pc)

    # Sigma_gas = mh2 / (FWHM_TO_AREA * phys_scale**2)
    # I_10 = Sigma_gas / alpha_CO

    # Normalized by X_CO = 2e20
    X_CO_norm = alpha_to_X(alpha_CO) / (2e20 * u.cm**-2 / (u.K * u.km / u.s))
    X_CO_norm = X_CO_norm.to(u.one)

    # From Eq. 2 Bolatto+13
    I_10 = mh2.to(u.solMass).value / (1.05e4 * X_CO_norm * distance.to(u.Mpc).value**2)
    I_10 = I_10 * u.Jy * u.km / u.s

    I_10 = I_10  * (beam.jtok(115.271 * u.GHz) / u.Jy)

    I_21 = R21 * I_10

    I_32 = R32 * I_21

    # if not to_jy:
    if to_jy:

        # I_10 = I_10  * (beam.jtok(115.271 * u.GHz) / u.Jy)
        # I_21 = I_21  * (beam.jtok(230.538 * u.GHz) / u.Jy)
        # I_32 = I_32  * (beam.jtok(345.796 * u.GHz) / u.Jy)

        I_10 = I_10  / (beam.jtok(115.271 * u.GHz) / u.Jy)
        I_21 = I_21  / (beam.jtok(230.538 * u.GHz) / u.Jy)
        I_32 = I_32  / (beam.jtok(345.796 * u.GHz) / u.Jy)

    return {"CO10": I_10, "CO21": I_21, "CO32": I_32}


def get_Tpeak_gaussian(I, sigma=4.5*u.km/u.s):

    return I / (np.sqrt(2 * np.pi) * sigma)


def h2mass_to_dust_brightness(mh2, nu=230*u.GHz, gdr=100, Tdust=20 * u.K,
                              kappa_nu=kappa_nu_chiang18,
                              distance=0.78 * u.Mpc,
                              beam_size=5*u.arcsec,
                              add_beam_unit=False,
                              verbose=False):
    '''
    Here kappa_nu from Forbrich+20 for M31 consistent with Viaene+17 M31 dust modeling with THEMIS
    at 230 GHz.

    Also track what the Chiang+18,20 values would be for comparison.

    And a frequency dependent kappa relation + metallicity dependent gdr.
    '''

    #   kappa_nu=0.0425 * u.m**2 / u.kg,  # Forbrich+20

    beam = Beam(beam_size.to(u.arcsec))

    phys_scale = (beam_size.to(u.rad).value * distance).to(u.pc)

    m_dust = mh2 / gdr

    if verbose:
        print(m_dust, kappa_nu(nu), Tdust, BlackBody(temperature=Tdust)(nu), phys_scale)

    S_nu = (m_dust * kappa_nu(nu) * BlackBody(temperature=Tdust)(nu)) / (FWHM_TO_AREA * phys_scale**2)
    S_nu = S_nu.to(u.MJy / u.sr)

    if add_beam_unit:
        S_nu = (S_nu * beam.sr / u.beam).to(u.Jy / u.beam)
    else:
        S_nu = (S_nu * beam.sr).to(u.Jy)

    return S_nu


def dust_to_h2mass(S_nu, nu=230*u.GHz, gdr=100, Tdust=20 * u.K,
                              kappa_nu=kappa_nu_chiang18,
                              distance=0.78 * u.Mpc,
                              beam_size=5*u.arcsec,
                              add_beam_unit=False,
                              verbose=False):
    '''
    Here kappa_nu from Forbrich+20 for M31 consistent with Viaene+17 M31 dust modeling with THEMIS
    at 230 GHz.

    Also track what the Chiang+18,20 values would be for comparison.

    And a frequency dependent kappa relation + metallicity dependent gdr.
    '''

    #   kappa_nu=0.0425 * u.m**2 / u.kg,  # Forbrich+20

    beam = Beam(beam_size.to(u.arcsec))

    phys_scale = (beam_size.to(u.rad).value * distance).to(u.pc)

    m_dust = S_nu * phys_scale**2 / (kappa_nu(nu) *  BlackBody(temperature=Tdust)(nu)) / (beam.sr)
    
    m_gas = m_dust * gdr

    return m_gas

