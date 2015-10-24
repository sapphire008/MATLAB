function varargout = postproc_gui(varargin)
% POSTPROC_GUI MATLAB code for postproc_gui.fig
%      POSTPROC_GUI, by itself, creates a new POSTPROC_GUI or raises the existing
%      singleton*.
%
%      H = POSTPROC_GUI returns the handle to a new POSTPROC_GUI or the handle to
%      the existing singleton*.
%
%      POSTPROC_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in POSTPROC_GUI.M with the given input arguments.
%
%      POSTPROC_GUI('Property','Value',...) creates a new POSTPROC_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before postproc_gui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to postproc_gui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help postproc_gui

% Last Modified by GUIDE v2.5 01-Jul-2014 12:05:14

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @postproc_gui_OpeningFcn, ...
                   'gui_OutputFcn',  @postproc_gui_OutputFcn, ...
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


% --- Executes just before postproc_gui is made visible.
function postproc_gui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to postproc_gui (see VARARGIN)

% subj_id stores entered subject ID, run_dirs stores locations
% of the found run movement dirs within the given folder
handles.run_dirs = {};
handles.subj_id = '';
handles.subj_dir = '';
handles.rereference = 1;
set(handles.rereference_box,'Value',1);
if ~isempty(varargin)
    handles.subj_dir = varargin{1}{:};
    set(handles.folder_edit, 'String', handles.subj_dir);
    handles.run_dirs = update_directory(handles);
end

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes postproc_gui wait for user response (see UIRESUME)
uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = postproc_gui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
close(handles.figure1);


function run_dirs = update_directory(handles)
all_files = dir(handles.subj_dir);
all_file_names = {all_files.name};
dir_file_names = all_file_names([all_files.isdir]);
IND = cellfun(@(x) ~isempty(strfind(ls(fullfile(handles.subj_dir,x)),...
    'workspace')),dir_file_names);
run_dirs = dir_file_names(IND);

set(handles.listbox, 'String', run_dirs);

    % --- Executes on button press in dir_button.
function dir_button_Callback(hObject, eventdata, handles)
% hObject    handle to dir_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Open the chooser; if dir was chosen, update the GUI
chosendir = uigetdir(pwd);
if chosendir
    handles.subj_dir = chosendir;
    set(handles.folder_edit, 'String', chosendir);
    handles.run_dirs = update_directory(handles);
end
% Update handles structure
guidata(hObject, handles);

% --- Executes on button press in run_button.
function run_button_Callback(hObject, eventdata, handles)
% hObject    handle to run_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.subj_id = get(handles.subj_edit, 'String');
if isempty(handles.subj_id)
    set(handles.subj_text, 'ForegroundColor', 'r');
    return;
elseif isempty(handles.subj_dir) || isempty(handles.run_dirs)
    set(handles.dir_text, 'ForegroundColor', 'r');
    return;
end

% Update handles structure
handles.output{1} = handles.subj_id;
handles.output{2} = handles.run_dirs;
handles.output{3} = handles.subj_dir;
handles.output{4} = get(handles.rereference_box, 'Value');
guidata(hObject, handles);
uiresume(handles.figure1);

% --- Executes on button press in cancel_button.
function cancel_button_Callback(hObject, eventdata, handles)
% hObject    handle to cancel_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% If we cancel, return -1 and close the gui.
handles.output{1} = -1;
handles.output{2}= -1;
handles.output{3} = -1;

guidata(hObject, handles);
uiresume(handles.figure1);



function subj_edit_Callback(hObject, eventdata, handles)
% hObject    handle to subj_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of subj_edit as text
%        str2double(get(hObject,'String')) returns contents of subj_edit as a double


% --- Executes during object creation, after setting all properties.
function subj_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to subj_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function folder_edit_Callback(hObject, eventdata, handles)
% hObject    handle to folder_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of folder_edit as text
%        str2double(get(hObject,'String')) returns contents of folder_edit as a double


% --- Executes during object creation, after setting all properties.
function folder_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to folder_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in listbox3.
function listbox3_Callback(hObject, eventdata, handles)
% hObject    handle to listbox3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns listbox3 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listbox3


% --- Executes during object creation, after setting all properties.
function listbox3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listbox3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in listbox.
function listbox_Callback(hObject, eventdata, handles)
% hObject    handle to listbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns listbox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listbox


% --- Executes during object creation, after setting all properties.
function listbox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in rereference_box.
function rereference_box_Callback(hObject, eventdata, handles)
% hObject    handle to rereference_box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of rereference_box
