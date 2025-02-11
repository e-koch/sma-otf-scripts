
import numpy as np

from pyuvdata.uvdata.mir_meta_data import MirInData
from pyuvdata.uvdata.mir_parser import MirParser

from astropy.coordinates import SkyCoord
from astropy.table import Table, Column



# out = MirInData()

# out.read(".")


mir_data = MirParser('250210_04:21:27/')

mir_data.select([("rinteg","lt", 2), ("flags", "eq", 0)])
offx, offy, rar, decr = mir_data.in_data[["offx","offy","rar","decr"]]

# otf_mask = out._data['rinteg'] < 2.

# source_ids = np.unique(out._data['isource'][otf_mask])
# print(f"Sources: {source_ids}")

# target_mask = out._data['isource'] == source_ids[0]

# offx_target = out._data['offx'][target_mask]
# offy_target = out._data['offy'][target_mask]

coord_target = SkyCoord(np.unique(rar) * u.rad,
                        np.unique(decr) * u.rad)
coords_target_otf = coord_target.spherical_offsets_by(offx * u.arcsec, offy * u.arcsec)

coords_target_otf_tab = Table([Column(coords_target_otf.ra, name='ra'),
                            Column(coords_target_otf.dec, name='dec')])

coords_target_otf_tab.write("target_otf_coords.fits", overwrite=True)
