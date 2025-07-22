**A stack of scripts attempting to iteratively scale overlapping lattice data until it reaches a solution
**

Mode of Usage:

Mostly to scale a dataset with muiltiple lattice and overlapping diffraction spots.
Uses dials program from ccp4 to automatically change spot intensity and picking threshold iteratively till it can find a good symmetry match.

Mode of usage:
1. run dialsSymSearch to pick spots varying spot intensity and thresholds.
2. run post_index_Op to go in each directory and split the indexed file and refine them on by one. Also, if the refinment ends up in P1, the script is supposed to try to scale it in P2.

Under Development.
