% Author: Gaurav Verma
% Edited by: Matt Markowitz
% January 2018

function region = rg2(img,x,y,stdmult)
    edg = edge(img,'canny',.05);
    se = strel('diamond',1);
    x = round(x,0); y = round(y,0);

    region = zeros(size(img)); base = region;
    if sum(region(:)) > 1
        base = region;
        rindex = max(region(:))+1;
    else
        rindex = 1;
    end

    region = zeros(size(img));
    region(y,x) = 1;

    hits = 1;
    while hits > 0
        region = imdilate(region,se);
        if sum(sum(region.*edg)) > 0
            hits = hits-1;
            region(edg) = 0;
        end
        thresh = stdmult*std(img(region>0));
        level = mean(img(region>0));
    end

    thresh = stdmult*std(img(region>0));
    level = mean(img(region>0));
    simg = abs(img-level);
    out = simg>thresh;
    holes = imfill((out+edg)~=1,'holes')-((out+edg)~=1);
    boundary = ((out+edg).*(1-holes))<1;

    %Re-using hits
    hits = 0;

    region(bwselect(boundary,x,y,4)>0) = rindex;
    for i = rindex:-1:1
        if sum(sum(and(base == i,region)))
            region = i*or(base == i,region);
            base(region > 0) = i;
            if hits > i
                base(base == hits) = 0;
                base(base > hits) = base(base > hits) - 1;
            end
            base(base > i) = base(base > i) - 1;
            hits = i;
        end
    end

    if hits > 0
        region = base;
    else
        region = region + base;
    end
end