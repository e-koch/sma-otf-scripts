
import numpy as np

from pyuvdata.uvdata.mir_meta_data import MirInData
from pyuvdata.uvdata.mir_parser import MirParser

from astropy.coordinates import SkyCoord
from astropy.table import Table, Column, vstack
import astropy.units as u


import sys
from pathlib import Path

mir_filename = Path(sys.argv[1])

print(f"Reading {mir_filename}")

mir_data = MirParser(mir_filename)

print("Selecting data")
mir_data.select([("rinteg","lt", 2), ("flags", "eq", 0)])
offx, offy, rar, decr = mir_data.in_data[["offx","offy","rar","decr"]]

# otf_mask = out._data['rinteg'] < 2.

# source_ids = np.unique(out._data['isource'][otf_mask])
# print(f"Sources: {source_ids}")

# target_mask = out._data['isource'] == source_ids[0]

# offx_target = out._data['offx'][target_mask]
# offy_target = out._data['offy'][target_mask]

# Group by common rar values, then split and calculate with the offsets.
unique_rar, unique_indices_rar = np.unique(rar, return_index=True)
unique_decr, unique_indices_decr = np.unique(decr, return_index=True)

# Sort indices to maintain order
sorted_indices_rar = np.sort(unique_indices_rar)
sorted_indices_decr = np.sort(unique_indices_decr)

# Use sorted indices to get the unique values in the original order
unique_rar_ordered = rar[sorted_indices_rar]
unique_decr_ordered = decr[sorted_indices_decr]

coord_target = SkyCoord(unique_rar_ordered * u.rad,
                        unique_decr_ordered * u.rad)

coords_target_otf_tabs = []
for this_rar, this_decr, this_coord in zip(unique_rar_ordered, unique_decr_ordered, coord_target):

    print(f"Processing {this_coord.to_string('hmsdms')}")

    # Identify the offsets for this source.
    this_mask = (rar == this_rar) & (decr == this_decr)
    print(f"Found {np.sum(this_mask)} offsets")

    this_offx = offx[this_mask]
    this_offy = offy[this_mask]

    coords_target_otf = this_coord.spherical_offsets_by(this_offx * u.arcsec, this_offy * u.arcsec)


    coords_target_otf_tabs.append(Table([Column(coords_target_otf.ra, name='ra'),
                                        Column(coords_target_otf.dec, name='dec')]))

# Combine into a single table

vstack(coords_target_otf_tabs).write(f"{mir_filename.name}_target_otf_coords.fits", overwrite=True)


# Save the unique rar and decr values. These should be the inputs for the observe cmd
field_centers = Table([Column(coord_target.ra, name='ra'),
                       Column(coord_target.dec, name='dec')])
field_centers.write(f"{mir_filename.name}_field_centers.fits", overwrite=True)
