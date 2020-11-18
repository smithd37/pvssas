Author: Matthew Markowitz
Group: TMII, Mount Sinai
September 2018

(Tested on Matlab R2018a)

Required Toolboxes:
* Image Processing Toolbox
* Statistics and Machine Learning Toolbox

Required Software:
* Hessian based Frangi Vesselness filter
https://www.mathworks.com/matlabcentral/fileexchange/24409-hessian-based-frangi-vesselness-filter

Recommended Software:
https://www.nitrc.org/projects/pvs_enhance/

Startup: 
Use pvssas.m to start the program.
Brain slices need to be segmented, using spm12 or similar software, in .nii format.

Custom Segmentation:
Use format seg(im,wmMask,slicenum,std,trunc) for 2D or seg(im,wmMask,std,trunc) for 3D.
std and trunc can be used for any parameters, or can be nonused

Keyboard shortcuts (can be easily edited):
Zoom in (ctrl-i)
Zoom out (ctrl-o)
Pan (ctrl-p)
Add (ctrl-a)
Delete (ctrl-d)
Delete Box (ctrl-b)
Undo (ctrl-u)
Grow std increase (ctrl-+)
Grow std decreade (ctrl--)