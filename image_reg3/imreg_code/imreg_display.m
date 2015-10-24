function varargout = imreg_display(varargin)
%[iamges_out,replaced_ind] = imreg_display(images,'image_field')
% IMREG_DISPLAY M-file for imreg_display.fig
% Use: images = imreg_display(images, 'image_field');
% The imreg_display m-file handles the back end logic of the imreg_display
% figure. This function takes in the images struct and the field we wish to
% view; it returns the edited image struct.

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @imreg_display_OpeningFcn, ...
                   'gui_OutputFcn',  @imreg_display_OutputFcn, ...
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


% --- Executes just before imreg_display is made visible.
function imreg_display_OpeningFcn(hObject, eventdata, handles, varargin)

% Choose default command line output for imreg_display
handles.output = hObject;
% Toggles the control button state: 1 for pause, 2 for continue
global control_toggle;
control_toggle = 2;
% Stores the images that are passed in
global image_frames;
image_frames = varargin{1};
% Number of frames
global image_num;
image_num = length(image_frames);
% the frame we are currently on
global current_index;
current_index = 1;
global replaced_ind;%EDC101613
replaced_ind = [];%EDC101613
% how fast do we cycle through the images?
handles.view_rate = 0.01;
% Determines which struct field of the images struct we display
handles.field = varargin{2};
% Set the image field text
set(handles.text4, 'String',  ['Image Field: ' upper(handles.field)]);
% Update handles structure
guidata(hObject, handles);

% Make sure current axes is right
axes(handles.imageAxes);
% Display the first image
imshow(eval([...
    'image_frames(' num2str(current_index)...
    ').' handles.field ';']));
% Set the current index text
set(handles.indexText, 'String', [ 'Image ' num2str(current_index)...
    ' of ' num2str(image_num)]);
set(handles.dispSpeed, 'String', num2str(handles.view_rate));
% UIWAIT makes imreg_display wait for user response
uiwait(handles.figure1);



% --- Outputs from this function are returned to the command line.
function varargout = imreg_display_OutputFcn(hObject, eventdata, handles)
global image_frames;
global replaced_ind;%EDC101613
% Get default command line output from handles structure
varargout{1} = image_frames;
varargout{2} = replaced_ind;%EDC101613
delete(handles.figure1);


% --- Executes when pause button is pressed.
function controlButton_Callback(hObject, eventdata, handles)
% The control button pauses image cycling

% Global variables control image cycling
global control_toggle;

% Enable / disable relevant buttons when paused
control_toggle = 2;
set(handles.controlButton, 'enable', 'off');
set(handles.backButton, 'enable', 'on');
set(handles.forwButton, 'enable', 'on');
set(handles.deleteButton, 'enable', 'on');
set(handles.fastForwardButton, 'enable', 'on');
set(handles.fastReverseButton, 'enable', 'on');
set(handles.dispSpeed, 'enable', 'on');

% Update the handles structure
guidata(hObject, handles);


% --- Executes on button press in backButton.
function backButton_Callback(hObject, eventdata, handles)
% The back button cycles back one image

% Global variables control image cycling
global current_index;
global image_frames;
global image_num;

% Enable / disable relevant buttons
set(handles.forwButton, 'enable', 'on');
set(handles.fastForwardButton, 'enable', 'on');

% If able, display the previous image
 axes(handles.imageAxes);
if current_index > 1
    current_index = current_index - 1;
    imshow(eval([...
        'image_frames(' num2str(current_index)...
        ').' handles.field ';']));
    set(handles.indexText, 'String',  [ 'Image ' num2str(current_index)...
        ' of ' num2str(image_num)]);
end

% If this is the first image, disable relevant buttons
if current_index == 1
    set(handles.backButton, 'enable', 'off');
    set(handles.fastReverseButton, 'enable', 'off');
end

% Update the handles structure
guidata(hObject, handles);


% --- Executes on button press in forwButton.
function forwButton_Callback(hObject, eventdata, handles)
% The forward button cycles forward one image

% Global variables control image cycling
global current_index;
global image_frames;
global image_num;

% Enable / disable relevant buttons
set(handles.backButton, 'enable', 'on');
set(handles.fastReverseButton, 'enable', 'on');

% If able, display the next image
axes(handles.imageAxes);
if current_index < image_num
    current_index = current_index + 1;
    imshow(eval([...
        'image_frames(' num2str(current_index)...
        ').' handles.field ';']));
    set(handles.indexText, 'String',  [ 'Image ' num2str(current_index)...
        ' of ' num2str(image_num)]);
end

% If this is the last image, disable relevant buttons
if current_index == image_num
    set(handles.forwButton, 'enable', 'off');
    set(handles.fastForwardButton, 'enable', 'off');
end

% Update the handles structure
guidata(hObject, handles);


% --- Executes on button press in deleteButton.
function deleteButton_Callback(hObject, eventdata, handles)
% The delete button replaces the current image with the previous image

% Global variables control image cycling
global current_index;
global image_frames;
global replaced_ind;%EDC101613

% Replace the current image
axes(handles.imageAxes);
if current_index == 1
    % If we are replacing the first image, replace with next image
    image_frames(current_index) = image_frames(current_index + 1);
    replaced_ind = [replaced_ind,current_index];%EDC101613
    imshow(eval([...
        'image_frames(' num2str(current_index)...
        ').' handles.field ';']));
else
    % Otherwise, we replace with the current image with prev image
    image_frames(current_index) = image_frames(current_index - 1);
    replaced_ind = [replaced_ind,current_index];%EDC101613
    imshow(eval([...
        'image_frames(' num2str(current_index)...
        ').' handles.field ';']));
end

% Update the handles structure
guidata(hObject, handles);


% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% Code executes on figure close; resumes gui (uiresume)
global control_toggle;
control_toggle = 2;
uiresume;


% --- Executes on button press in fastReverseButton.
function fastReverseButton_Callback(hObject, eventdata, handles)
% The fastReverseButton cycles backwards through the images

% Global variables control image cycling
global control_toggle;
global current_index;
global image_frames;
global image_num;

% If we are not at the first image already
if current_index > 1
    % Enable / disable relevant buttons
    set(handles.controlButton, 'enable', 'on');
    set(handles.backButton, 'enable', 'off');
    set(handles.forwButton, 'enable', 'off');
    set(handles.deleteButton, 'enable', 'off');
    set(handles.fastForwardButton, 'enable', 'off');
    set(handles.fastReverseButton, 'enable', 'off');
    set(handles.dispSpeed, 'enable', 'off');
    control_toggle = 1;
    % Update handles structure, make sure right axes is set
    guidata(hObject, handles);
    axes(handles.imageAxes);
    
    % While we can still cycle back and user has not pressed pause
    % Cycle backwards through the images, update relevant params
    while (control_toggle == 1) && ...
            (current_index > 1)
        current_index = current_index - 1;
        imshow(eval([...
            'image_frames(' num2str(current_index)...
            ').' handles.field ';']));
        set(handles.indexText, 'String',  [ 'Image ' num2str(current_index)...
            ' of ' num2str(image_num)]);
        % Pause image for set view rate
        pause(handles.view_rate);
    end
end

% If we are already at the first image
% Enable / disable relevant buttons
if current_index == 1
    set(handles.controlButton, 'enable', 'off');
    set(handles.backButton, 'enable', 'off');
    set(handles.forwButton, 'enable', 'on');
    set(handles.deleteButton, 'enable', 'on');
    set(handles.fastForwardButton, 'enable', 'on');
    set(handles.fastReverseButton, 'enable', 'off');
    set(handles.dispSpeed, 'enable', 'on');
    control_toggle = 2;
    guidata(hObject, handles);
end

% Update the handles structure
guidata(hObject, handles);



% --- Executes on button press in fastForwardButton.
function fastForwardButton_Callback(hObject, eventdata, handles)
% The fastForwardButton cycles forward through the images

% Global variables control image cycling
global control_toggle;
global current_index;
global image_frames;
global image_num;

% If we are not already at the last image
if current_index < image_num
    % Enable / disable relevant buttons
    set(handles.controlButton, 'enable', 'on');
    set(handles.backButton, 'enable', 'off');
    set(handles.forwButton, 'enable', 'off');
    set(handles.deleteButton, 'enable', 'off');
    set(handles.fastForwardButton, 'enable', 'off');
    set(handles.fastReverseButton, 'enable', 'off');
    set(handles.dispSpeed, 'enable', 'off');
    control_toggle = 1;
    % Update the handles structure, make sure correct axes is set
    guidata(hObject, handles);
    axes(handles.imageAxes);
    
    % While we can still cycle forward and user has not pressed pause
    % Cycle forward through the images, update relevant params
    while (control_toggle == 1) && ...
            (current_index < image_num)
        current_index = current_index + 1;
        imshow(eval([...
            'image_frames(' num2str(current_index)...
            ').' handles.field ';']));
        set(handles.indexText, 'String',  [ 'Image ' num2str(current_index)...
            ' of ' num2str(image_num)]);
        % Pause image for set view rate
        pause(handles.view_rate);
    end
end

% If we are already at the last image
% Enable / disable relevant buttons
if current_index == image_num
    set(handles.controlButton, 'enable', 'off');
    set(handles.backButton, 'enable', 'on');
    set(handles.forwButton, 'enable', 'off');
    set(handles.deleteButton, 'enable', 'on');
    set(handles.fastForwardButton, 'enable', 'off');
    set(handles.fastReverseButton, 'enable', 'on');
    set(handles.dispSpeed, 'enable', 'on');
    control_toggle = 2;
    guidata(hObject, handles);
end
 % Update the handles structure
guidata(hObject, handles);



function dispSpeed_Callback(hObject, eventdata, handles)
% The dispSeed text box sets the delay of each frame, in seconds

% Get the new frame rate, update the handles structure
handles.view_rate = str2num(get(hObject, 'String'));
guidata(hObject, handles);


% Executes upon object creation.
function dispSpeed_CreateFcn(hObject, eventdata, handles)
% Set background color
if ispc && isequal(get(hObject,'BackgroundColor'),...
        get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
