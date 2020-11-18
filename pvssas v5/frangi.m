function thresh = frangi(im,wmMask,slicenum,std,trunc)
% Segments pvs' using frangi filter, returns 2d binary matrix

    % Parameters
    p.rows = size(im,1);
    p.columns = size(im,2);
    p.slices = size(im,3);
    p.gsigma = 1;
    p.stdmult = std;
    p.minsize = 4;
    p.maxsize = 100;
    p.wmholesize = 200;
    p.boundthresh = trunc;

    thresh = bwSeg(im,wmMask,slicenum,p);
end

function thresh = bwSeg(im,wmMask,slicenum,p)
% Thresholds white matter using frangi and pre-filtering methods

    wm = zeros(p.rows,p.columns); % White matter (grayscale)
    wmMaskFilled = zeros(p.rows,p.columns); % White matter (binary)
    
    % Fills in small holes
    [wm(:,:),wmMaskFilled(:,:)] = wmPrep(im(:,:,slicenum),wmMask(:,:,slicenum),p);
    
    % Gaussian filtering
    wm(:,:) = imgaussfilt(wm(:,:),p.gsigma);
    
    % Optional filtering to remove bottom 1% of data
    Ip(:,:) = single(wm(:,:));
    thr = prctile(Ip(Ip(:)>0),1) * 0.9;
    Ip(Ip<=thr) = thr;
    Ip = Ip - min(Ip(:));
    Ip = Ip ./ max(Ip(:));
    wm(:,:) = Ip;

    % Segments the white matter
    [thresh,boundMask] = threshold(im(:,:,slicenum),wm(:,:),p); 
    % Makes it binary
    thresh(thresh > 0) = 1; 
    thresh = logical(thresh);
    % Only keeps regions within the desired area range
    thresh = bwareafilt(thresh,[p.minsize p.maxsize]).*thresh; 
end

function [wm,wmMaskFilled] = wmPrep(im,wmMask,p)
% Fills in holes left by white matter segmentation

    filled = imfill(wmMask,8,'holes');
    holes = filled & ~wmMask;
    bigholes = bwareaopen(holes, p.wmholesize);
    smallholes = holes & ~bigholes;
    wmMaskFilled = wmMask | smallholes; 
    wm = im.*wmMaskFilled; 
end

function [thresh,boundMask] = threshold(im,wm,p)
% Frangi filter + threshholding

    % Boundary of white matter mask (with some thickness)
    boundMask = getBound(im, wm, p);
    % Frangi filter
    thresh = imadjust(FrangiFilter2D(wm,struct('FrangiScaleRange', [1.4 3.2],'FrangiScaleRatio', 2,...
             'FrangiBetaOne', 0.95, 'FrangiBetaTwo', 0.35, 'verbose',false,'BlackWhite',false)));
    % Removes this boundary from our thresholded image
    thresh = thresh.*boundMask;
    % Threshholding 
    tMean = mean(thresh(thresh ~= 0));
    tStd = std(thresh(thresh ~= 0));
    thresh(thresh < tMean + p.stdmult*tStd) = 0;
end

function boundMask = getBound(im,wmMaskFilled, p)
% Finds boundary of white matter and makes it thicker
% Note: wmMaskFilled here is grayscale for grayscale wm input

    % Find boundaries
    imBound = zeros(p.rows,p.columns);
    [B,L,N] = bwboundaries(wmMaskFilled);
    for k=1:length(B)
        boundary = B{k};
        for i = 1:size(boundary,1)
            imBound(boundary(i,1), boundary(i,2)) = 1; 
        end
    end
    % Makes boundary thicker by a few pixels
    boundMask = imcomplement(bwdist(imBound) <= p.boundthresh);
end