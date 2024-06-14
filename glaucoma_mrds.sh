#!/bin/bash

dwis=sub-72521_acq-muse_dwi_de.nii
bvec=sub-72521_acq-muse_dwi_d.bvec
bval=sub-72521_acq-muse_dwi_d.bval
roiMask=mask_muse.nii
roi=roi.nii


# volteamos el signo del componente x de bvec
bvec_x=flip_x.bvec
flip_gradients.sh $bvec $bvec_x -flip_x

# generamos el scheme
scheme=scheme_flip_x.txt
transpose_table.sh $bvec_x > temporal_bvec
transpose_table.sh $bval   > temporal_bval
paste temporal_bvec temporal_bval > $scheme


# Calculamos DTI
tensor_prefix=tensor_flip_x
dti \
  -mask $roiMask \
  -response 0 \
  -correction 0 \
  -fa \
  -md \
  $dwis \
  $scheme \
  $tensor_prefix

# Capturamos response como variable
response=`cat ${tensor_prefix}_DTInolin_ResponseAnisotropic.txt | awk '{OFS = "," ;print $1,$2}'`
echo "Response es $response"


# Calculamos MRDS
mrds_prefix=my_mrds_flipx
mdtmrds \
  $dwis \
  $scheme \
  $mrds_prefix \
  -correction 0 \
  -response "$response" \
  -mask $roi \
  -modsel all \
  -each \
  -intermediate \
  -fa -md -mse \
  -method diff 1

# Podemos separar las direccciones principales de cada tensor para verlos en mrtrix como fixels
mrconvert -coord 3 0:2 ${mrds_prefix}_MRDS_Diff_BIC_PDDs_CARTESIAN.nii tensor_0.nii
mrconvert -coord 3 3:5 ${mrds_prefix}_MRDS_Diff_BIC_PDDs_CARTESIAN.nii tensor_1.nii
mrconvert -coord 3 6:8 ${mrds_prefix}_MRDS_Diff_BIC_PDDs_CARTESIAN.nii tensor_2.nii

mrview fa.nii \
  -fixel.load tensor_0.nii \
  -fixel.load tensor_1.nii \
  -fixel.load tensor_2.nii 