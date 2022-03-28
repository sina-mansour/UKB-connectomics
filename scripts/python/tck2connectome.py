# script made from the notebook codes

import sys
import numpy as np
from scipy import spatial
import nibabel as nib


if __name__ == '__main__':
    # sys.argv
    atlas_file, endpoint_file, output_file, search_radius = sys.argv[1:]

    # This code performs a pythonic immitation of tck2connectome

    # load the atlas file
    atlas = nib.load(atlas_file)

    # load the tractography endpoint information
    endpoints = np.load(endpoint_file)

    # extract the coordinates information from NIFTI atlas
    node_indices = np.arange(np.prod(atlas.shape)).reshape(atlas.shape)

    ind_i, ind_j, ind_k = np.meshgrid(
        np.arange(atlas.shape[0]),
        np.arange(atlas.shape[1]),
        np.arange(atlas.shape[2]), indexing='ij',
    )

    node_ijk = np.array([ind_i.reshape(-1), ind_j.reshape(-1), ind_k.reshape(-1)]).T

    node_xyz = nib.affines.apply_affine(atlas.affine, node_ijk)

    # only select voxels with a label greater than zero
    selection_mask = (atlas.get_fdata() > 0)

    selection_indices = node_ijk[selection_mask.reshape(-1), :]

    selection_xyz = node_xyz[selection_mask.reshape(-1), :]

    selection_labels = atlas.get_fdata()[selection_mask].astype(int)

    # build a kdtree for spatial proximity queries
    kdtree = spatial.cKDTree(selection_xyz)

    # get the list of endpoints
    starts = endpoints[:, 0, :]
    ends = endpoints[:, -1, :]

    # query for closest coordinate from selection
    start_dists, start_indices = kdtree.query(starts)
    end_dists, end_indices = kdtree.query(ends)

    # mask points that are further than the search radius from all selection coordinates
    search_radius = float(search_radius)
    distance_mask = (start_dists < search_radius) & (end_dists < search_radius)

    # only keep valid endpoints according to the search radius
    valid_start_indices = start_indices[distance_mask]
    valid_end_indices = end_indices[distance_mask]

    # number of regions/nodes
    node_count = selection_labels.max()

    # generate connectivity matrix
    adj = np.zeros((node_count, node_count), dtype=np.float32)
    np.add.at(adj, (selection_labels[valid_start_indices] - 1, selection_labels[valid_end_indices] - 1), 1)
    adj = adj + adj.T
    adj[np.diag_indices_from(adj)] /= 2

    # store connectome in a csv file
    np.savetxt(output_file, adj, delimiter=',')
