function varargout = pvssas(varargin)
% PVS Semi-Automatic Segmentation 

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @pvssas_OpeningFcn, ...
                   'gui_OutputFcn',  @pvssas_OutputFcn, ...
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

% --- Executes just before pvssas is made visible.
function pvssas_OpeningFcn(hObject, eventdata, handles, varargin)

% Choose default command line output for pvssas
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% Default Options
% segpath - Path viewer of segmentation file
% segopen - Browse button for segpath
% is3d_cb - Checkbox for doing a 3d segmentation
% segFile - Name of segmentation file (without .m)
% lastpathname - Current path name, updates on your last visit

set(handles.segpath,'Enable','off');
set(handles.segopen,'Enable','off');
set(handles.is3d_cb,'Enable','off');
setappdata(0,'segFile','frangi');
setappdata(0,'lastpathname',strcat(fullfile(getenv('USERPROFILE'),'Downloads'),filesep));

% --- Outputs from this function are returned to the command line.
function varargout = pvssas_OutputFcn(hObject, eventdata, handles) 
% Get default command line output from handles structure
varargout{1} = handles.output;

% --- Executes on button press in loadbutton.
function loadbutton_Callback(hObject, eventdata, handles)
% Gets the data-paths, and if they exist, runs the viewer with these files
% im - orginal image, 3d double
% wmMask - white matter (or other mask), 3d double
% pm - pvs mask if we have one saved from before, 3d double (binary)

datapath = get(handles.datapath,'String');
wmpath = get(handles.wmpath,'String');
pmpath = get(handles.pmpath,'String');
is3d = get(handles.is3d_cb,'Value');
segFile = getappdata(0,'segFile');

% Saves the data
if (exist(datapath,'file') && exist(wmpath,'file') && ~isempty(segFile))
    imtemp = squeeze(mat2gray(niftiread(datapath)));
    setappdata(0,'im',imtemp);
    setappdata(0,'wmMask',squeeze(double(mat2gray(niftiread(wmpath))>.5)));
    % GENERAL USE
    % setappdata(0,'wmMask',squeeze(mat2gray(niftiread(wmpath)))); 
    if (exist(pmpath,'file'))
        setappdata(0,'pm',cell2mat(struct2cell(open(pmpath))));
    else
        setappdata(0,'pm',zeros(size(imtemp,1),size(imtemp,2),size(imtemp,3))); %empty pvs mask
    end
    setappdata(0,'is3d',is3d);
    View; % Opens the viewer
    close('pvssas');
else
    f = errordlg('Files invalid or not found.','Error');
end

% --- Executes on button press in dataopen.
function dataopen_Callback(hObject, eventdata, handles)
% Selects brain using file-selector
[filename,pathname] = uigetfile(strcat(getappdata(0,'lastpathname'),'.nii'),'File Selector');

if ~isequal(pathname,0) % Updates path name for future use
    setappdata(0,'lastpathname',pathname);
end
if ~isequal(filename,0) % Stores data path
    path = strcat(pathname,filename);
    set(handles.datapath,'String',path);
end

% --- Executes on button press in dataopen.
function wmopen_Callback(hObject, eventdata, handles)
% Selects white matter mask using file-selector
[filename,pathname] = uigetfile(strcat(getappdata(0,'lastpathname'),'.nii'),'File Selector');

if ~isequal(pathname,0)
    setappdata(0,'lastpathname',pathname);
end
if ~isequal(filename,0)
    path = strcat(pathname,filename);
    set(handles.wmpath,'String',path);
end

% --- Executes on button press in pmopen.
function pmopen_Callback(hObject, eventdata, handles)
% Selects pvs mask using file-selector (optional input)
[filename,pathname] = uigetfile(strcat(getappdata(0,'lastpathname'),'.mat'),'File Selector');

if ~isequal(pathname,0)
    setappdata(0,'lastpathname',pathname);
end
if ~isequal(filename,0)
    path = strcat(pathname,filename);
    set(handles.pmpath,'String',path);
end

% --- Executes on button press in segopen.
function segopen_Callback(hObject, eventdata, handles)
% Selects segmentation file using file-selector (optional input)
[filename,pathname] = uigetfile(strcat(getappdata(0,'lastpathname'),'.m'),'File Selector');

if ~isequal(pathname,0)
    setappdata(0,'lastpathname',pathname);
end
if ~isequal(filename,0)
    path = strcat(pathname,filename);
    set(handles.segpath,'String',path);
    setappdata(0,'segFile',filename(1:end-2));
end

% --- Executes when selected object is changed in segmentation_bg.
function segmentation_bg_SelectionChangedFcn(hObject, eventdata, handles)
% Radioboxes to choose default or custom segmentation
radiobutton = get(handles.segmentation_bg,'SelectedObject');
rbtag = get(radiobutton,'Tag');

switch rbtag
    case 'frangi_rb' % Frangi segmentation
        set(handles.segpath,'Enable','off');
        set(handles.segopen,'Enable','off');
        set(handles.is3d_cb,'Enable','off');
        set(handles.is3d_cb,'Value',0);
        setappdata(0,'segFile','frangi');
    case 'selectseg_rb' % Custom segmentation
        set(handles.segpath,'Enable','on');
        set(handles.segopen,'Enable','on');
        set(handles.is3d_cb,'Enable','on');
        setappdata(0,'segFile',get(handles.segpath,'String'));
end