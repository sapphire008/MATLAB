function varargout = imreg_findthresh(varargin)
% IMREG_FINDTHRESH MATLAB code for imreg_findthresh.fig
%      IMREG_FINDTHRESH, by itself, creates a new IMREG_FINDTHRESH or raises the existing
%      singleton*.
%
%      H = IMREG_FINDTHRESH returns the handle to a new IMREG_FINDTHRESH or the handle to
%      the existing singleton*.
%
%      IMREG_FINDTHRESH('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in IMREG_FINDTHRESH.M with the given input arguments.
%
%      IMREG_FINDTHRESH('Property','Value',...) creates a new IMREG_FINDTHRESH or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before imreg_findthresh_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to imreg_findthresh_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help imreg_findthresh

% Last Modified by GUIDE v2.5 13-Mar-2012 17:53:43

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @imreg_findthresh_OpeningFcn, ...
                   'gui_OutputFcn',  @imreg_findthresh_OutputFcn, ...
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


% --- Executes just before imreg_findthresh is made visible.
function imreg_findthresh_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to imreg_findthresh (see VARARGIN)

% Choose default command line output for imreg_findthresh
handles.output = hObject;


global sliderVal; 
sliderVal = 0.25;

global base_im;
base_im = varargin{1};

global haxes;
haxes = handles.imageAxes;

global invert_image;
invert_image = get(handles.invert_image, 'Value');

imshow(im2bw(base_im, sliderVal), 'parent', haxes);

% Update handles structure
guidata(hObject, handles);

addlistener(handles.threshSlider, 'ContinuousValueChange', @updateThresh);
uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = imreg_findthresh_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global sliderVal;
varargout{1} = sliderVal;
varargout{2} = get(handles.invert_image, 'Value');
delete(hObject);


% --- Executes on slider movement.
function threshSlider_Callback(hObject, eventdata, handles)
% hObject    handle to threshSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global sliderVal;

% Get new value, update the slider value and text box
val = get(handles.threshSlider, 'Value');
set(handles.threshEdit, 'String', num2str(val));
sliderVal = val;

% Update the handles struct
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function threshSlider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to threshSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on button press in submitButton.
function submitButton_Callback(hObject, eventdata, handles)
% hObject    handle to submitButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

uiresume;

function threshEdit_Callback(hObject, eventdata, handles)
% hObject    handle to threshEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes during object creation, after setting all properties.
function threshEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to threshEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function updateThresh(hObject, event)

global sliderVal;
global base_im;
global haxes;
global invert_image;

val = get(hObject, 'Value');
htext = findall(0, 'Tag', 'threshEdit');
set(htext, 'String', num2str(val));
if invert_image == 1
    imshow(~im2bw(base_im, val), 'parent', haxes);
else
    imshow(im2bw(base_im, val), 'parent', haxes);
end
sliderVal = val;


% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure
global sliderVal; 
sliderVal = -1;
uiresume;


% --- Executes on button press in invert_image.
function invert_image_Callback(hObject, eventdata, handles)
% hObject    handle to invert_image (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global sliderVal;
global base_im;
global invert_image;
invert_image = get(handles.invert_image, 'Value');

haxes = handles.imageAxes;
if invert_image == 1
    imshow(~im2bw(base_im, sliderVal), 'parent', haxes);
else
    imshow(im2bw(base_im, sliderVal), 'parent', haxes);
end

