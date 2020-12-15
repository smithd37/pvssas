function varargout = View(varargin)
% Viewer for pvssas

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @View_OpeningFcn, ...
                   'gui_OutputFcn',  @View_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT

% --- Executes just before View is made visible.
function View_OpeningFcn(hObject, eventdata, handles, varargin)
im = getappdata(0,'im');
pm = getappdata(0,'pm');
bwthresh = pm; %zeros(size(im,1),size(im,2),size(im,3)) is default

% Displays slice 1 on right and left screen
br = 1/max(max(im(:,:,1)));
imshow(br*im(:,:,1),'Parent',handles.axesright);
h = handles.axesleft; caxis(h, [0 1/(1+get(handles.contrastslider,'Value')*4)]);
h = handles.axesright; caxis(h, [0 1/(1+get(handles.contrastslider,'Value')*4)]);
disp_bound(handles,im,1,bwthresh(:,:,1));

% Links axes so that zooming in and moving one affects the other
linkaxes([handles.axesleft handles.axesright]);
% Creates slice select dropdown
set(handles.sliceselect,'String',num2str((1:size(im,3))'),'Value',1);

% Parameters
p.toolbaron = false;
p.slicenum = 1;
p.stdmult = 2;
p.growmult = 0.25;
p.boundtrunc = 8;
p.bwthresh = bwthresh;
p.bwthreshprev = repmat(bwthresh(:,:,p.slicenum),1,1,10);
setappdata(0,'p',p);

% Choose default command line output for View
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% --- Outputs from this function are returned to the command line.
function varargout = View_OutputFcn(hObject, eventdata, handles) 
% Get default command line output from handles structure
varargout{1} = handles.output;

% --- Executes during object creation, after setting all properties.
function View_CreateFcn(hObject, eventdata, handles)
set(hObject, 'toolbar', 'none'); % We have a custom toolbar instead

% Canceling for waitbar in segmentall
function myCancelCB(hObject, EventData)
    w = ancestor(hObject, 'figure');
    setappdata(w, 'cancel_callback', 1);

% --- Executes on button press in segmentall.
function segmentall_Callback(hObject, eventdata, handles)
enable_buttons(handles,'off');
p = getappdata(0,'p');
im = getappdata(0,'im');
wmMask = getappdata(0,'wmMask');
is3d = getappdata(0,'is3d');
segFile = getappdata(0,'segFile');

fh = str2func(segFile);
if (~is3d) % if segmentation is not 3D
    w =  waitbar(0,'Segmenting...','createcancelbtn', @myCancelCB);
    setappdata(w, 'cancel_callback', 0);
    % Iterates across all slices and segments pvs'
    for s = 1:size(im,3)
        if getappdata(w, 'cancel_callback') == 1 % canceled
            break;
        end
        bwt = fh(im,wmMask,s,p.stdmult,p.boundtrunc);
        p.bwthresh(:,:,s) = imdilate(bwt,strel('disk',1));
        waitbar(s/size(im,3));
    end 
    delete(w);
else % if segmentation is 3D
    bwt = fh(im,wmMask,p.stdmult,p.boundtrunc);
    p.bwthresh = imdilate(bwt,strel('disk',1));
end

disp_bound(handles,im,p.slicenum,p.bwthresh(:,:,p.slicenum));
setappdata(0,'p',p);
enable_buttons(handles,'on');

% --- Executes on button press in segment.
function segment_Callback(hObject, eventdata, handles)
enable_buttons(handles,'off');
p = getappdata(0,'p');
im = getappdata(0,'im');
wmMask = getappdata(0,'wmMask');
is3d = getappdata(0,'is3d');
segFile = getappdata(0,'segFile');

if (is3d) % If 3D return, since there's no option to segment a single slice
    return;
end

% Segments pvs' using frangi method and returns a black and white mask
fh = str2func(segFile);
bwt = fh(im,wmMask,p.slicenum,p.stdmult,p.boundtrunc);
% Makes individual pvs' thicker by 1 pixel
bwt = imdilate(bwt,strel('disk',1));
% Display boundaries of pvs' on left screen
disp_bound(handles,im,p.slicenum,bwt);
% delete oldest saved state and add previous state
p.bwthreshprev(:,:,1) = []; p.bwthreshprev(:,:,10) = p.bwthresh(:,:,p.slicenum);
p.bwthresh(:,:,p.slicenum) = bwt;
setappdata(0,'p',p);
enable_buttons(handles,'on');

% --- Executes on button press in save.
function save_Callback(hObject, eventdata, handles)
% Saves bwthresh to current folder and workspace
p = getappdata(0,'p');
thresh = p.bwthresh;
uisave({'thresh'},'thresh');
assignin('base','thresh',thresh);

% --- Executes on button press in back.
function back_Callback(hObject, eventdata, handles)
% Returns to original left_menu
pvssas;
close('View');

% --- Executes on selection change in sliceselect.
function sliceselect_Callback(hObject, eventdata, handles)
p = getappdata(0,'p');
im = getappdata(0,'im');
wmMask = getappdata(0,'wmMask');
contents = cellstr(get(hObject,'String'));
p.slicenum = str2double(contents{get(hObject,'Value')});
p.bwthreshprev = repmat(p.bwthresh(:,:,p.slicenum),1,1,10); % reinit

% Displays the selected slice on the left and right screen
br = 1/max(max(im(:,:,p.slicenum)));
if get(handles.imagetypeselect,'Value') == 1
    imshow(br*im(:,:,p.slicenum),'Parent',handles.axesright);
else % '2' or'Mask'
    imshow(br*wmMask(:,:,p.slicenum),'Parent',handles.axesright);
end
h = handles.axesleft; caxis(h, [0 1/(1+get(handles.contrastslider,'Value')*4)]);
h = handles.axesright; caxis(h, [0 1/(1+get(handles.contrastslider,'Value')*4)]);
disp_bound(handles,im,p.slicenum,p.bwthresh(:,:,p.slicenum));
setappdata(0,'p',p);

% --- Executes on selection change in imagetypeselect.
function imagetypeselect_Callback(hObject, eventdata, handles)
% Displays full image or masked image on the right side
p = getappdata(0,'p');
im = getappdata(0,'im');
wmMask = getappdata(0,'wmMask');
contents = cellstr(get(hObject,'String'));

br = 1/max(max(im(:,:,p.slicenum)));
cla(handles.axesright);
if strcmp(contents{get(hObject,'Value')},'Full')
    imshow(br*im(:,:,p.slicenum),'Parent',handles.axesright);
else % 'Mask'
    imshow(br*wmMask(:,:,p.slicenum),'Parent',handles.axesright);
end
h = handles.axesright; caxis(h, [0 1/(1+get(handles.contrastslider,'Value')*4)]);

% --- Executes on selection change in roicolorselect.
function roicolorselect_Callback(hObject, eventdata, handles)
% Updates left image with newly colored roi's
disp_bound_update(handles)

% --- Executes on button press in islabeled.
function islabeled_Callback(hObject, eventdata, handles)
% Labels roi's
disp_bound_update(handles)

function disp_bound_update(handles)
enable_buttons(handles,'off');
p = getappdata(0,'p');
im = getappdata(0,'im');
bwt = p.bwthresh(:,:,p.slicenum);
slicenum = p.slicenum;

disp_bound(handles,im,slicenum,bwt);
enable_buttons(handles,'on');

% --- Executes during object creation, after setting all properties.
function sliceselect_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on string change in stdmult.
function stdmult_Callback(hObject, eventdata, handles)
% Updates threshold std
p = getappdata(0,'p');
p.stdmult = str2double(get(hObject,'String'));
setappdata(0,'p',p);

% --- Executes on string change in boundtrunc
function boundtrunc_Callback(hObject, eventdata, handles)
p = getappdata(0,'p');
p.boundtrunc = str2double(get(hObject,'String'));
setappdata(0,'p',p);

% --- Executes on button press in addroi.
function addroi_Callback(hObject, eventdata, handles)
enable_buttons(handles,'off');
p = getappdata(0,'p');
im = getappdata(0,'im');
bwt = p.bwthresh(:,:,p.slicenum);
newroi = zeros(size(im,1),size(im,2));

% Create a region of interest on the left screen
h = impoly(handles.axesleft);
if isvalid(h) % ie if not deleted
    newroi(:,:) = createMask(h);
end
delete(h);

% Add region to existing threshold mask
bwt = bwt | newroi;
% Display updated boundaries on left screen
disp_bound(handles,im,p.slicenum,bwt);
% delete oldest saved state and add previous state
p.bwthreshprev(:,:,1) = []; p.bwthreshprev(:,:,10) = p.bwthresh(:,:,p.slicenum);
p.bwthresh(:,:,p.slicenum) = bwt;
setappdata(0,'p',p);
enable_buttons(handles,'on');

% --- Executes on button press in deleteroi.
function deleteroi_Callback(hObject, eventdata, handles)
enable_buttons(handles,'off');
p = getappdata(0,'p');
im = getappdata(0,'im');
bwt = p.bwthresh(:,:,p.slicenum);

% Create a region of interest on the left screen
newroi = ones(size(im,1),size(im,2));
h = impoly(handles.axesleft);
if isvalid(h) % ie if not deleted
    % Invert createMask so that roi is black instead of white
    newroi(:,:) = ~createMask(h);
end
delete(h); 

% Remove region from existing threshold mask
bwt = bwt & newroi;
% Display updated boundaries on left screen
disp_bound(handles,im,p.slicenum,bwt);
% delete oldest saved state and add previous state
p.bwthreshprev(:,:,1) = []; p.bwthreshprev(:,:,10) = p.bwthresh(:,:,p.slicenum);
p.bwthresh(:,:,p.slicenum) = bwt;
setappdata(0,'p',p);
enable_buttons(handles,'on');

% --- Executes on button press in deleteboxroi.
function deleteboxroi_Callback(hObject, eventdata, handles)
enable_buttons(handles,'off');
p = getappdata(0,'p');
im = getappdata(0,'im');
bwt = p.bwthresh(:,:,p.slicenum);

% Create rectangular region of interest on the left screen
rec = imrect(handles.axesleft);
% Gets rectangle coordinates (in terms of x/y rather than row/column)
recpos = getPosition(rec);
xmin = round(recpos(1)); xmax = round(recpos(1) + recpos(3));
ymin = round(recpos(2)); ymax = round(recpos(2) + recpos(4));

% Creates a mask that is black inside the rectangle and white outside
newroi = ones(size(im,1),size(im,2));
if isvalid(rec) % ie if not deleted
    newroi(ymin:ymax,xmin:xmax) = 0;
end
delete(rec); 

% Remove region from existing threshold mask
bwt = bwt & newroi;
% Display updated boundaries on left screen
disp_bound(handles,im,p.slicenum,bwt);
% delete oldest saved state and add previous state
p.bwthreshprev(:,:,1) = []; p.bwthreshprev(:,:,10) = p.bwthresh(:,:,p.slicenum);
p.bwthresh(:,:,p.slicenum) = bwt;
setappdata(0,'p',p);
enable_buttons(handles,'on');

% --- Executes on button press in undo.
function undo_Callback(hObject, eventdata, handles)
enable_buttons(handles,'off');
p = getappdata(0,'p');
im = getappdata(0,'im');

% Reverts bwthresh to its previous state if its previous state is different
if (~isequal(p.bwthresh(:,:,p.slicenum),p.bwthreshprev(:,:,10)))
    p.bwthresh(:,:,p.slicenum) = p.bwthreshprev(:,:,10); % most recent saved state
    p.bwthreshprev = circshift(p.bwthreshprev,1,3); % shifts array by one index in third dimension
    p.bwthreshprev(:,:,1) = p.bwthreshprev(:,:,2); % replaces the restored state with the oldest state
    disp_bound(handles,im,p.slicenum,p.bwthresh(:,:,p.slicenum));
    setappdata(0,'p',p);
end
enable_buttons(handles,'on');

% Callback for left screen context menu
function left_menu_Callback(hObject, eventdata, handles)
% Gets position of right click in image
cpoint = get(handles.axesleft,'CurrentPoint'); 
setappdata(0,'cpoint',cpoint(1,1:2));

% --- Executes on button press in growroi.
function grow_single_roi_Callback(hObject, eventdata, handles)
p = getappdata(0,'p');
p.growmult = 0.25; % reset to default if changed before
set(handles.growtext, 'String', ['Grow Mult: ', num2str(0.25)]);
setappdata(0,'p',p);
grow_single_roi_Function(hObject, eventdata, handles);

% --- Executes from above function and on hotkey press
function grow_single_roi_Function(hObject, eventdata, handles)
enable_buttons(handles,'off');
p = getappdata(0,'p');
im = getappdata(0,'im');
bwt = p.bwthresh(:,:,p.slicenum);
cpoint = getappdata(0,'cpoint');

% Performs region growing on selected pixel and returns bw mask
newroi = rg2(im(:,:,p.slicenum),cpoint(1),cpoint(2),p.growmult);
% optional: increase boundary size by 1 pixel
newroi = imdilate(newroi,strel('disk',1));

% Add region to existing threshold mask
bwt = bwt | newroi;
% Display updated boundaries on left screen
disp_bound(handles,im,p.slicenum,bwt);
% delete oldest saved state and add previous state
p.bwthreshprev(:,:,1) = []; p.bwthreshprev(:,:,10) = p.bwthresh(:,:,p.slicenum);
p.bwthresh(:,:,p.slicenum) = bwt;
setappdata(0,'p',p);
enable_buttons(handles,'on');
setappdata(0,'growon',1); % boolean

% Callback for delete option in left_menu
function delete_single_roi_Callback(hObject, eventdata, handles)
enable_buttons(handles,'off');
p = getappdata(0,'p');
im = getappdata(0,'im');
bwt = p.bwthresh(:,:,p.slicenum);
cpoint = getappdata(0,'cpoint');

% labels the regions in the current slice
L = bwlabel(bwt);
% label of the clicked region
label = L(round(cpoint(2)),round(cpoint(1)));
% remove all connected components
L(L == label) = 0;
% Turn into bw mask
L(L > 0) = 1;
% Display new image
disp_bound(handles,im,p.slicenum,L);

% delete oldest saved state and add previous state
p.bwthreshprev(:,:,1) = []; p.bwthreshprev(:,:,10) = p.bwthresh(:,:,p.slicenum);
p.bwthresh(:,:,p.slicenum) = L;
setappdata(0,'p',p);
enable_buttons(handles,'on');

% Callback for reset zoom option in left_menu
function reset_zoom_Callback(hObject, eventdata, handles)
zoom(handles.View,'out');

% --- Executes on key press with focus on View and none of its controls.
function View_KeyPressFcn(hObject, eventdata, handles)
% Manages shortcut keys
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
if (~isempty(eventdata.Modifier))
    mod = eventdata.Modifier{1};
    key = eventdata.Key;
    p = getappdata(0,'p');
    
    % Manages zoom in and zoom out
    if (strcmp(mod,'control') && (strcmp(key,'i') || strcmp(key,'o')))
        zm = zoom();
        if (strcmp(key,'i'))
            zm.direction = 'in';
        else % key 'o'
            zm.direction = 'out';
        end
        if (strcmp(zm.Enable,'off'))
            zoom on;
            enable_hotkeys(handles);
        else
            zoom off;
            p.toolbaron = false; 
            setappdata(0,'p',p);
        end
        
    % Manages pan
    elseif (strcmp(mod,'control') && strcmp(key,'p'))
        pn = pan();
        if (strcmp(pn.Enable,'off'))
            pan on;
            enable_hotkeys(handles);
        else
            pan off;
            p.toolbaron = false;
            setappdata(0,'p',p);
        end
        
    % Manages other shortcut keys
    elseif (~p.toolbaron)
        growon = getappdata(0,'growon');
        if (strcmp(mod,'control') && strcmp(key,'a'))
            addroi_Callback(hObject, eventdata, handles);
        elseif (strcmp(mod,'control') && strcmp(key,'d'))
            deleteroi_Callback(hObject, eventdata, handles);
        elseif (strcmp(mod,'control') && strcmp(key,'b'))
            deleteboxroi_Callback(hObject, eventdata, handles);
        elseif (strcmp(mod,'control') && strcmp(key,'u'))
            undo_Callback(hObject, eventdata, handles);
        elseif (strcmp(mod,'control') && strcmp(key,'equal') && growon) % + 
            if (p.growmult < 4)
                p.growmult = p.growmult + 0.25;
                set(handles.growtext, 'String', ['Grow Mult: ', num2str(p.growmult)]);
                setappdata(0,'p',p);
            end
            undo_Callback(hObject, eventdata, handles);
            grow_single_roi_Function(hObject, eventdata, handles);
        elseif (strcmp(mod,'control') && strcmp(key,'hyphen') && growon) % -
            if (p.growmult >= 0.5)
                p.growmult = p.growmult - 0.25;
                set(handles.growtext, 'String', ['Grow Mult: ', num2str(p.growmult)]);
                setappdata(0,'p',p);
            end
            undo_Callback(hObject, eventdata, handles);
            grow_single_roi_Function(hObject, eventdata, handles);
        end
    end
end

% Enable hotkeys when disabled by toolbar
function enable_hotkeys(handles)
p = getappdata(0,'p');
p.toolbaron = true;

% http://undocumentedmatlab.com/blog/enabling-user-callbacks-during-zoom-pan
hManager = uigetmodemanager(handles.View);
try
    set(hManager.WindowListenerHandles, 'Enable', 'off');
catch
    [hManager.WindowListenerHandles.Enabled] = deal(false);
end
set(handles.View, 'WindowKeyPressFcn', []);
set(handles.View, 'KeyPressFcn', @View_KeyPressFcn);

setappdata(0,'p',p);

function disp_bound(handles,im,slicenum,thresh)
cla(handles.axesleft);
% Gets threshold information
[B,L,n,A] = bwboundaries(thresh);

% Displays image in left screen
br = 1/max(max(im(:,:,slicenum)));
colormap(gray);
ims = imagesc(br*im(:,:,slicenum),'Parent',handles.axesleft);
set(ims, 'HitTest', 'off' );
set(handles.axesleft, 'Visible', 'on' );
set(handles.axesleft,'dataAspectRatio',[1 1 1])
set(handles.axesleft,'xtick',[])
set(handles.axesleft,'ytick',[])

% Plots the boundaries
colorid = get(handles.roicolorselect,'String');
colorstr = colorid{get(handles.roicolorselect,'Value')};
hold(handles.axesleft,'on')
for k = 1:length(B)
   boundary = B{k};
   plot(handles.axesleft,boundary(:,2), boundary(:,1), colorstr, 'LineWidth', 2)
   if get(handles.islabeled,'Value')
       [mn idx] = min(boundary(:,1));
       text(handles.axesleft,boundary(idx,2),boundary(idx,1),num2str(k),'clipping','on','Color','w');
   end
end

% Changes the number of roi's
set(handles.roicount, 'String', ['Count: ', num2str(n)]);

function enable_buttons(handles,str)
% Enables or disables buttons
set(handles.addroi,'Enable',str);
set(handles.deleteroi,'Enable',str);
set(handles.deleteboxroi,'Enable',str);
set(handles.undo,'Enable',str);
set(handles.segment,'Enable',str);
set(handles.segmentall,'Enable',str);
set(handles.save,'Enable',str);
set(handles.back,'Enable',str);
set(handles.sliceselect,'Enable',str);
set(handles.roicolorselect,'Enable',str);
set(handles.imagetypeselect,'Enable',str);
set(handles.islabeled,'Enable',str);
% Sets std varying for regino growing off
setappdata(0,'growon',0);

% --- Executes on slider movement.
function contrastslider_Callback(hObject, eventdata, handles)
% Changes contrast of both images

assignin('base','handles',handles);
p = getappdata(0,'p');
im = getappdata(0,'im');
p.slicenum = get(handles.sliceselect,'Value');

% Displays the selected slice on the left and right screen
br = 1/max(max(im(:,:,p.slicenum)));
h = handles.axesleft; caxis(h, [0 1/(1+get(handles.contrastslider,'Value')*4)]);
h = handles.axesright; caxis(h, [0 1/(1+get(handles.contrastslider,'Value')*4)]);
disp_bound(handles,im,p.slicenum,p.bwthresh(:,:,p.slicenum));
setappdata(0,'p',p);

% --- Executes during object creation, after setting all properties.
function contrastslider_CreateFcn(hObject, eventdata, handles)
% Contrast slider background
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end
