function varargout = imreg_gui(varargin)
% IMREG_GUI M-file for imreg_gui.fig
% The imreg_gui function creates the initialization GUI for the image_reg
% program. Allows users to set analysis params for motion analysis without
% going into the code. All relevant parameters can be set from the GUI; For
% normal image analysis, user should not have to go into the scripts at all.


% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @imreg_gui_OpeningFcn, ...
                   'gui_OutputFcn',  @imreg_gui_OutputFcn, ...
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


% --- Executes just before imreg_gui is made visible.
function imreg_gui_OpeningFcn(hObject, eventdata, handles, varargin)

% Flag determines path; local comp or IRC servers?
% This is more of a development parameter; end users should running
% analyses locally at the IRC should keep this param at 0.
handles.remote_run = 0;
% Add all of our interface variables to the GUI structure
handles.params.project_name = '';
handles.params.save_dir = '';
handles.params.dir_name = '';
handles.params.post_proc = 0;
handles.params.sample_rate = 0; 
handles.params.bin_thresh = ''; 
handles.params.min_area = 0; 
handles.params.edge_alg = '';
handles.params.centerDist_mm = 0;
handles.params.medfilt = [];
handles.params.image_ext = '';
handles.params.ref_voxel = '';
handles.params.isref = 0;
% Update handles structure
guidata(hObject, handles);

% UIWAIT makes imreg_gui wait for user response (see UIRESUME)
uiwait(handles.figure1);


% --- Executes before figure close, returns the param struct
function varargout = imreg_gui_OutputFcn(hObject, eventdata, handles) 
% Get default command line output from handles structure
varargout{1} = handles.params;
close(handles.figure1);


% --- Executes on button press in image_button.
function image_button_Callback(hObject, eventdata, handles)
% Open the chooser; if dir was chosen, update the GUI
chosendir = uigetdir(pwd);
if chosendir
    handles.params.dir_name = chosendir;
    set(handles.image_dir, 'String', chosendir);
end
% Update the handles structure
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function save_dir_CreateFcn(hObject, eventdata, handles)
% Set object background color
if ispc && isequal(get(hObject,'BackgroundColor'),...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in save_button.
function save_button_Callback(hObject, eventdata, handles)
% Open a directory chooser and allow user to choose save dir.
chosendir = uigetdir(pwd);
if chosendir
    handles.params.save_dir = chosendir;
    set(handles.save_dir, 'String', chosendir);
end
% Update the handles structure.
guidata(hObject, handles);


% --- Executes on button press in analyze_button.
function analyze_button_Callback(hObject, eventdata, handles)
% When the analyze button is pressed, extract relevant parameters from the
% GUI and store in the params struct
handles.params.save_dir = get(handles.save_dir, 'String');
handles.params.project_name = get(handles.run_name, 'String');
handles.params.dir_name = get(handles.image_dir, 'String');
handles.params.post_proc = get(handles.post_proc, 'Value');
handles.params.sample_rate = str2num(get(handles.sample_rate, 'String'));
handles.params.bin_thresh = get(handles.bin_thresh, 'String');
handles.params.min_area = str2num(get(handles.feature_size, 'String'));
methods = get(handles.edge_alg, 'String');
handles.params.edge_alg = methods{get(handles.edge_alg, 'Value')};
handles.params.centerDist_mm = str2num(get(handles.icd, 'String'));
handles.params.save_workspace = get(handles.save_workspace, 'Value');
handles.params.medfilt = [str2num(get(handles.mf_row,'String')),str2num(get(handles.mf_col,'String'))];
handles.params.image_ext = get(handles.img_ext,'String');
handles.params.ref_voxel = get(handles.ref_voxel,'String');
handles.params.isref = get(handles.is_ref_scan_box,'Value');
% Update handles structure
guidata(hObject, handles);
uiresume(handles.figure1);
return;

% --- Executes on button press in clear_button.
function clear_button_Callback(hObject, eventdata, handles)
% Restores GUI input boxes to to their default values.
set(handles.run_name, 'String', '');
set(handles.image_dir, 'String', '');
set(handles.save_dir, 'String', '');
set(handles.post_proc, 'Value', 0);
set(handles.sample_rate, 'String', '5');
set(handles.bin_thresh, 'String', 'auto');
set(handles.feature_size, 'String', '350');
set(handles.edge_alg, 'Value', 1);
set(handles.icd, 'String', '4.9');
set(handles.save_workspace, 'Value', 0);
set(handles.mf_row,'String','3');
set(handles.mf_col,'String','3');
set(hahdles.img_ext,'String','.jpg');
set(handles.ref_voxel, 'String','None');
set(handles.is_ref_scan_box,'Value',0);



function cancel_button_Callback(hObject, eventdata, handles)
% If we cancel, return -1 and close the gui.
handles.params = -1;
guidata(hObject, handles);
uiresume;


% ------  The following are all CreateFcn stubs  ------- %

% --- Executes during object creation, after setting all properties.
function sample_rate_CreateFcn(hObject, eventdata, handles)
% Set object background color.
if ispc && isequal(get(hObject,'BackgroundColor'),...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function bin_thresh_CreateFcn(hObject, eventdata, handles)
% Set object background color.
if ispc && isequal(get(hObject,'BackgroundColor'),...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function edge_alg_CreateFcn(hObject, eventdata, handles)
% Set object background color.
if ispc && isequal(get(hObject,'BackgroundColor'),...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function feature_size_CreateFcn(hObject, eventdata, handles)
% Set object background color.
if ispc && isequal(get(hObject,'BackgroundColor'),...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function intercentroid_dist_CreateFcn(hObject, eventdata, handles)
% Set object background color.
if ispc && isequal(get(hObject,'BackgroundColor'),...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function run_name_CreateFcn(hObject, eventdata, handles)
% Set object background color
if ispc && isequal(get(hObject,'BackgroundColor'),...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function image_dir_CreateFcn(hObject, eventdata, handles)
% Set object background color
if ispc && isequal(get(hObject,'BackgroundColor'),...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% ------  The following function stubs are unused  ------- %

function run_name_Callback(hObject, eventdata, handles)
% Hints: get(hObject,'String') returns contents of run_name as text
%        str2double(get(hObject,'String')) returns contents of run_name as a double

function image_dir_Callback(hObject, eventdata, handles)
% Hints: get(hObject,'String') returns contents of image_dir as text
%        str2double(get(hObject,'String')) returns contents of image_dir as a double

function save_dir_Callback(hObject, eventdata, handles)
% Hints: get(hObject,'String') returns contents of save_dir as text
%        str2double(get(hObject,'String')) returns contents of save_dir as a double

% --- Executes on button press in post_proc.
function post_proc_Callback(hObject, eventdata, handles)
% Hint: get(hObject,'Value') returns toggle state of post_proc

function sample_rate_Callback(hObject, eventdata, handles)
% Hints: get(hObject,'String') returns contents of sample_rate as text
%        str2double(get(hObject,'String')) returns contents of sample_rate as a double

function bin_thresh_Callback(hObject, eventdata, handles)
% Hints: get(hObject,'String') returns contents of bin_thresh as text
%        str2double(get(hObject,'String')) returns contents of bin_thresh as a double

% --- Executes on selection change in edge_alg.
function edge_alg_Callback(hObject, eventdata, handles)
% Hints: contents = cellstr(get(hObject,'String')) returns edge_alg contents as cell array
%        contents{get(hObject,'Value')} returns selected item from edge_alg

function feature_size_Callback(hObject, eventdata, handles)
% Hints: get(hObject,'String') returns contents of feature_size as text
%        str2double(get(hObject,'String')) returns contents of feature_size as a double

function intercentroid_dist_Callback(hObject, eventdata, handles)
% Hints: get(hObject,'String') returns contents of intercentroid_dist as text
%        str2double(get(hObject,'String')) returns contents of intercentroid_dist as a double
% --- Outputs from this function are returned to the command line.




% --- Executes on key press with focus on image_button and none of its controls.
function image_button_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to image_button (see GCBO)
% eventdata  structure with the following fields (see UICONTROL)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)



function mf_row_Callback(hObject, eventdata, handles)
% hObject    handle to mf_row (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of mf_row as text
%        str2double(get(hObject,'String')) returns contents of mf_row as a double


% --- Executes during object creation, after setting all properties.
function mf_row_CreateFcn(hObject, eventdata, handles)
% hObject    handle to mf_row (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function mf_col_Callback(hObject, eventdata, handles)
% hObject    handle to mf_col (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of mf_col as text
%        str2double(get(hObject,'String')) returns contents of mf_col as a double


% --- Executes during object creation, after setting all properties.
function mf_col_CreateFcn(hObject, eventdata, handles)
% hObject    handle to mf_col (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% EoF %



function img_ext_Callback(hObject, eventdata, handles)
% hObject    handle to img_ext (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of img_ext as text
%        str2double(get(hObject,'String')) returns contents of img_ext as a double


% --- Executes during object creation, after setting all properties.
function img_ext_CreateFcn(hObject, eventdata, handles)
% hObject    handle to img_ext (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function icd_Callback(hObject, eventdata, handles)
% hObject    handle to icd (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of icd as text
%        str2double(get(hObject,'String')) returns contents of icd as a double


% --- Executes during object creation, after setting all properties.
function icd_CreateFcn(hObject, eventdata, handles)
% hObject    handle to icd (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function ref_voxel_Callback(hObject, eventdata, handles)
% hObject    handle to ref_voxel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ref_voxel as text
%        str2double(get(hObject,'String')) returns contents of ref_voxel as a double


% --- Executes during object creation, after setting all properties.
function ref_voxel_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ref_voxel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in is_ref_scan_box.
function is_ref_scan_box_Callback(hObject, eventdata, handles)
% hObject    handle to is_ref_scan_box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of is_ref_scan_box
