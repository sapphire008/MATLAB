function varargout = ROI_display(varargin)
% RejectedInd = ROI_display(image_dirs, ROI_dir,'display_text',crop_3D,delay)
% A GUI tool to help inspect ROI alignment onto the template images.
%
% Examine each image specified overlayed by the specified ROI, and then use
% the 'Reject' button to mark which image to mark has problematic.
%
% Inputs:
%       image_dirs: cell array of full image directories
%       ROI_dir: directory of ROI
%       display_text: text to display as the title of the current images;
%                     usually information regarding the current images,
%                     such as subjects, tasks, which ROI being used, etc.
%       crop_3D: which anatomical orientatino to look. Select amongst
%                'sagittal', 'coronal', and 'axial'
%       delay(optional): slow down the display of the images when
%                       playing as a movie. Default 0.05 second. See PAUSE.
%
% Outputs:
%       RejectedInd: a binary index that specifies which images are being
%                    rejected by user. 1 indicates rejection, and 0
%                    indicates keeping. The length of this vector is the
%                    same as the length of image_dirs, as well as following
%                    the order of image_dirs.
%
% Requirements:
%   1). nifti package, to use load_nii function
%   2). ROI_find_bounded_img.m, crops the image volumes to fit ROI
%
%
% Warning:
%       This function will import all the images into the memory. For very
%       large images, this can slow down other processes or may crash the
%       whole system. 

% Last Modified by GUIDE v2.5 30-Jul-2013 18:18:11
% Created by Edward DongBo Cui, cui23327@gmail.com

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ROI_display_OpeningFcn, ...
                   'gui_OutputFcn',  @ROI_display_OutputFcn, ...
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
end

% --- Executes just before ROI_display is made visible.
function ROI_display_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to ROI_display (see VARARGIN)

% Choose default command line output for ROI_display
handles.output = hObject;
% Toggles the control button state: 0 for pause, 1 for continue
global control_toggle;
control_toggle = 1;
% Stores the images that are passed in
global image_dirs;
image_dirs = varargin{1};
% Number of frames
global image_num;
image_num = length(image_dirs);
% the image frame we are currently on
global current_index;
current_index = 1;
% set the slice to be displayed
global current_slice;
current_slice = 1;
handles.SliceSlider = current_slice;
handles.SliceNumber = num2str(current_slice);
% get the directory of the ROI for overlay
global ROI_overlay;
ROI_overlay = load_nii(varargin{2});
ROI_overlay = ROI_overlay.img;
% Set the Display Text for [subject | task | ROI]
% Set the image field text
set(handles.ImageName, 'String',  varargin{3});
% Set current slice number
set(handles.SliceText,'String',['Slice: ' num2str(current_slice)]);
%Set default view point of dispaly (saggital, coronal, or axial)
global current_view;
current_view = varargin{4};
handles.AnatView = current_view;
global display_delay;%delay time of each image, see PAUSE.
if length(varargin)<5
    display_delay = 0.05;%default pause 0.05 second
else
    display_delay = varargin{5};
end
global RejectedInd;% a binary vector that which volume is rejected
RejectedInd = false(1,image_num);
% Update handles structure
guidata(hObject, handles);

%ASSUMING: all the images specified in the path are in the same space
global image_frames current_dim num_slice;
%load in all the images to memory for faster indexing
%use this scheme assuming large memory (LARGE = total_image_size * 8)
image_frames = cell(1,image_num);
for n = 1:length(image_dirs)
    image_frames{n} = load_nii(image_dirs{n});
    [image_frames{n},current_dim,num_slice] = ROI_find_bounded_img(...
        image_frames{n}.img,ROI_overlay,current_view);
end
% Make sure current axes is right
set(handles.imageAxes,'XTick',[],'YTick',[],'Visible','off');
axes(handles.imageAxes);
%display current_slice of reduced image
imagesc(squeeze(eval(['image_frames{current_index}(',regexprep(':,:,:)',...
    ':',num2str(current_slice),current_dim)])));
colormap('gray');%change color to grayscale

% UIWAIT makes ROI_display wait for user response (see UIRESUME)
uiwait(handles.ROI_display);
end

% --- Outputs from this function are returned to the command line.
function varargout = ROI_display_OutputFcn(hObject, eventdata, handles)
global RejectedInd;
% Get default command line output from handles structure
varargout{1} = RejectedInd;
%delete(handles.ROI_display);
end

% --- Executes on button press in FastReverse.
function FastReverse_Callback(hObject, eventdata, handles)
% The fastReverseButton cycles backwards through the images

% Global variables control image cycling
global control_toggle image_frames image_num current_index  ...
    current_slice current_dim display_delay;

% If we are not at the first image already
if current_index > 1
    % Enable / disable relevant buttons
    set(handles.Reverse, 'enable', 'off');
    set(handles.Forward, 'enable', 'off');
    set(handles.FastForward, 'enable', 'off');
    set(handles.FastReverse, 'enable', 'off');
    set(handles.Pause, 'enable', 'on');
    set(handles.RejectImage,'enable','off');
    % Update handles structure, make sure right axes is set
    guidata(hObject, handles);
    axes(handles.imageAxes);
    control_toggle = 1;
    
    % While we can still cycle back and user has not pressed pause
    % Cycle backwards through the images, update relevant params
    while (control_toggle == 1) && (current_index > 1)
        current_index = current_index - 1;
        imagesc(squeeze(eval(['image_frames{current_index}(',regexprep(':,:,:)',...
            ':',num2str(current_slice),current_dim)])));
        %colormap('gray');%change color to grayscale
        set(handles.ImageFrameText, 'String',['Image ' num2str(current_index)...
            ' of ' num2str(image_num)]);
        % Pause image for set view rate
        pause(display_delay);
    end
end

% If we are already at the first image
% Enable / disable relevant buttons
if current_index == 1
    set(handles.FastReverse, 'enable', 'off');
    set(handles.Reverse, 'enable', 'off');
    set(handles.Pause, 'enable', 'off');
    set(handles.Forward, 'enable', 'on');
    set(handles.FastForward, 'enable', 'on');
    set(handles.RejectImage, 'enable', 'on');
    control_toggle = 0;
    guidata(hObject, handles);
end

% Update the handles structure
guidata(hObject, handles);

end

% --- Executes on button press in Reverse.
function Reverse_Callback(hObject, eventdata, handles)
% hObject    handle to Reverse (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Global variables control image cycling
global current_index image_frames image_num current_slice current_dim;

% Enable / disable relevant buttons
set(handles.Forward, 'enable', 'on');
set(handles.FastForward, 'enable', 'on');

% If able, display the previous image
axes(handles.imageAxes);
if current_index > 1
    current_index = current_index - 1;
    imagesc(squeeze(eval(['image_frames{current_index}(',regexprep(':,:,:)',...
            ':',num2str(current_slice),current_dim)])));
    set(handles.ImageFrameText, 'String',['Image ' num2str(current_index)...
            ' of ' num2str(image_num)]);
end

% If this is the first image, disable relevant buttons
if current_index == 1
    set(handles.Reverse, 'enable', 'off');
    set(handles.FastReverse, 'enable', 'off');
end

% Update the handles structure
guidata(hObject, handles);
end


% --- Executes on button press in Pause.
function Pause_Callback(hObject, eventdata, handles)
% Global variables control image cycling
global control_toggle;

% Enable / disable relevant buttons when paused
control_toggle = 0;
set(handles.FastReverse, 'enable', 'on');
set(handles.Reverse, 'enable', 'on');
set(handles.Pause, 'enable', 'off');
set(handles.Forward, 'enable', 'on');
set(handles.FastForward, 'enable', 'on');
set(handles.RejectImage, 'enable', 'on');

% Update the handles structure
guidata(hObject, handles);

end

% --- Executes on button press in Forward.
function Forward_Callback(hObject, eventdata, handles)
% The forward button cycles forward one image

% Global variables control image cycling
global current_index image_frames image_num current_slice current_dim;

% Enable / disable relevant buttons
set(handles.Reverse, 'enable', 'on');
set(handles.FastReverse, 'enable', 'on');

% If able, display the next image
axes(handles.imageAxes);
if current_index < image_num
    current_index = current_index + 1;
    imagesc(squeeze(eval(['image_frames{current_index}(',regexprep(':,:,:)',...
        ':',num2str(current_slice),current_dim)])));
    set(handles.ImageFrameText, 'String',['Image ' num2str(current_index)...
        ' of ' num2str(image_num)]);
end

% If this is the last image, disable relevant buttons
if current_index == image_num
    set(handles.Forward, 'enable', 'off');
    set(handles.FastForward, 'enable', 'off');
end

% Update the handles structure
guidata(hObject, handles);
end


% --- Executes on button press in FastForward.
function FastForward_Callback(hObject, eventdata, handles)
% The fastForwardButton cycles forward through the images

% Global variables control image cycling
global control_toggle current_index current_slice current_dim ...
    image_frames image_num display_delay;

% If we are not already at the last image
if current_index < image_num
    % Enable / disable relevant buttons
    set(handles.FastReverse, 'enable', 'on');
    set(handles.Reverse, 'enable', 'on');
    set(handles.Pause, 'enable', 'on');
    set(handles.Forward, 'enable', 'off');
    set(handles.FastForward, 'enable', 'off');
    set(handles.RejectImage, 'enable', 'off');
    control_toggle = 1;
    % Update the handles structure, make sure correct axes is set
    guidata(hObject, handles);
    axes(handles.imageAxes);
    
    % While we can still cycle forward and user has not pressed pause
    % Cycle forward through the images, update relevant params
    while (control_toggle == 1) && ...
            (current_index < image_num)
        current_index = current_index + 1;
        imagesc(squeeze(eval(['image_frames{current_index}(',regexprep(':,:,:)',...
            ':',num2str(current_slice),current_dim)])));
        set(handles.ImageFrameText, 'String',['Image ' num2str(current_index)...
            ' of ' num2str(image_num)]);
        % Pause image for set view rate
        pause(display_delay);
    end
end

% If we are already at the last image
% Enable / disable relevant buttons
if current_index == image_num
    set(handles.FastReverse, 'enable', 'on');
    set(handles.Reverse, 'enable', 'on');
    set(handles.Pause, 'enable', 'off');
    set(handles.Forward, 'enable', 'off');
    set(handles.FastForward, 'enable', 'off');
    set(handles.RejectImage, 'enable', 'on');
    control_toggle = 0;
    guidata(hObject, handles);
end
 % Update the handles structure
guidata(hObject, handles);
end


% --- Executes on mouse press over figure background, over a disabled or
% --- inactive control, or over an axes background.
function ROI_display_WindowButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to ROI_display (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
end


% --- Executes on button press in RejectImage.
function RejectImage_Callback(hObject, eventdata, handles)
% hObject    handle to RejectImage (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global RejectedInd current_index;
RejectedInd(current_index) = true;
end


% --- Executes on selection change in AnatView.
function AnatView_Callback(hObject, eventdata, handles)
% hObject    handle to AnatView (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns AnatView contents as cell array
%        contents{get(hObject,'Value')} returns selected item from AnatView

global current_view image_frames current_dim num_slice image_dirs image_num...
    ROI_overlay current_slice current_index;
contents = cellstr(get(hObject,'String'));
new_view = contents{get(hObject,'Value')};

if ~strcmpi(new_view,current_view)
    current_view = new_view;
    %reload  all the images to memory if new_view is different from
    %current_view
    image_frames = cell(1,image_num);
    for n = 1:length(image_dirs)
        image_frames{n} = load_nii(image_dirs{n});
        [image_frames{n},current_dim,num_slice] = ROI_find_bounded_img(...
            image_frames{n}.img,ROI_overlay,current_view);
    end
    % Make sure current axes is right
    axes(handles.imageAxes);
    current_slice = 1;%reset slice
    current_index = 1;%reset index
    %display current_slice of reduced image
    imagesc(squeeze(eval(['image_frames{current_index}(',regexprep(':,:,:)',...
        ':',num2str(current_slice),current_dim)])));
    colormap('gray');%change color to grayscale
    %reset some displays
    handles.AnatView = current_view;
    set(handles.ImageFrameText, 'String',['Image ' num2str(current_index)...
        ' of ' num2str(image_num)]);%reset image text
    %reset buttons
    set(handles.FastReverse, 'enable', 'off');
    set(handles.Reverse, 'enable', 'off');
    set(handles.Pause, 'enable', 'off');
    set(handles.Forward, 'enable', 'on');
    set(handles.FastForward, 'enable', 'on');
    set(handles.RejectImage, 'enable', 'on');
    % Update the handles structure
    guidata(hObject, handles);
end
end

% --- Executes during object creation, after setting all properties.
function AnatView_CreateFcn(hObject, eventdata, handles)
% hObject    handle to AnatView (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
global current_view;
which_selection = find(ismember(cellstr(get(hObject,'String')),current_view));
set(hObject,'Value',which_selection);%set startup selection as the one called in the function
end


function SliceNumber_Callback(hObject, eventdata, handles)
% hObject    handle to SliceNumber (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of SliceNumber as text
%        str2double(get(hObject,'String')) returns contents of SliceNumber as a double
global current_slice;
current_slice = round(str2double(get(hObject,'String')));
end

% --- Executes during object creation, after setting all properties.
function SliceNumber_CreateFcn(hObject, eventdata, handles)
% hObject    handle to SliceNumber (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

% --- Executes on slider movement.
function SliceSlider_Callback(hObject, eventdata, handles)
% hObject    handle to SliceSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
global current_slice current_dim current_index image_frames;
current_slice = round(get(hObject,'Value'));%round in case get decimals
%change the text displayed in SliceNumber textbox
set(handles.SliceText,'String',['Slice: ' num2str(current_slice)]);
%update the image
imagesc(squeeze(eval(['image_frames{current_index}(',regexprep(':,:,:)',...
    ':',num2str(current_slice),current_dim)])));
% Update the handles structure
guidata(hObject, handles);
end

% --- Executes during object creation, after setting all properties.
function SliceSlider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to SliceSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

global num_slice current_slice;
set(hObject,'Min',1);
set(hObject,'Max',num_slice);
set(hObject,'SliderStep',[1,1]/(num_slice-1));
set(hObject,'Value',current_slice);

end
