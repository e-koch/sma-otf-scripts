
# Generate the perl scripts for M31 observing

from regions import Regions
import astropy.units as u

from pathlib import Path
import numpy as np
import itertools

# M31 velocity
v_M31 = -296

# Configuration setup
this_config = 'sub'
# this_config = 'com'

maps_per_track = {'com': 19,
                  'sub': 15}

if not this_config in maps_per_track:
    raise ValueError("Unknown config: " + this_config)

nmaps0 = maps_per_track[this_config]

# Load M31 OTF regions

# data_path = Path("/Users/ekoch/storage/M31/SMA/m31_25A_sma_otf_co21_techdev")
data_path = Path(".")

reg_filename = 'm31_sma_otf_mosaics.crtf'

all_regions = Regions.read(data_path / reg_filename)


template_path = data_path / "m31_observing_scripts/m31_otf_sub_basetemplate.pl"
output_scripts_path = data_path / "m31_observing_scripts"


# Two things to set in the perl obs template:
# 1. Targets per brick in @mainTarg
# 2. The order and total number of maps to loop through


def region_to_sma_line(this_region, region_prefix='M31', v_M31=v_M31):
    '''
    Convert a region to a line in the perl script

    e.g., "M82 -r 09:55:59.7  -d +69:40:55 -e 2000 -v 270";

    Parameters
    ----------
    this_region : regions.Region
    '''

    ra = this_region.center.ra.to_string(u.hour, sep=':')
    dec = this_region.center.dec.to_string(u.deg, sep=':')

    return f'"{region_prefix}-{this_region.meta['label']} -r {ra} -d {dec} -e 2000 -v {v_M31}"'


region_prefix = 'M31'

region_dict = {"A": {}, "B": {}, "C": {}, "D": {}}

for this_region in all_regions:

    this_brick = this_region.meta['label'].split("Brick-")[1][0]

    full_name = f"{region_prefix}-{this_region.meta['label']}"

    region_dict[this_brick][full_name] = this_region


# Ensure we have the right number of maps per brick
assert len(region_dict["A"]) == 5
assert len(region_dict["D"]) == 5

assert len(region_dict["B"]) == 6
assert len(region_dict["C"]) == 6

# Generate the lines
# sma_lines = []
# for this_region in all_regions:
#     print(region_to_sma_line(this_region))

# A and D have 5 maps and 7 total tracks
# B and C have 6 maps and 8 total tracks

for this_brick in region_dict:

    print(f"Generating scripts for {this_brick}")

    nmaps = len(region_dict[this_brick])

    if len(region_dict[this_brick]) == 5:
        ntracks = 7
    elif len(region_dict[this_brick]) == 6:
        ntracks = 8
    else:
        raise ValueError(f"Unexpected number of maps: {nmaps} for brick {this_brick}")

    print(f"Brick: {this_brick}")
    print(f"Number of maps: {nmaps}")
    print(f"Number of tracks: {ntracks}")

    map_list = np.array([name for name in region_dict[this_brick]])

    for ii in range(1, ntracks+1):
        print(f"Generating script for track {ii}")

        # Generate map order, cycling between starting points in each track:
        cycled_maps = list(itertools.islice(itertools.cycle(np.roll(map_list, ii-1)), nmaps0))

        # Generate target strings:
        target_string = []
        for this_map in cycled_maps:
            target_string.append(region_to_sma_line(region_dict[this_brick][this_map],
                                                    region_prefix=region_prefix))

        # Sanity check:
        assert len(target_string) == nmaps0

        target_string = ",\n".join(target_string)

        output_name = f"{this_config}_Brick_{this_brick}_track_{ii}.pl"
        output_path = output_scripts_path / output_name
        if output_path.exists():
            output_path.unlink()

        template_path = output_scripts_path / "m31_otf_sub_basetemplate.pl"

        with open(template_path, "r") as f:
            template = f.read()

        # Replace the placeholder with your target string
        new_content = template.replace("{science_targets}", target_string)

        with open(output_path, "w") as f:
            # Defaults to empty line for first character. Slice this out.
            f.write(new_content[1:])




