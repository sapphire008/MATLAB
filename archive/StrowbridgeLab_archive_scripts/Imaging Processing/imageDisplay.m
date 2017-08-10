
function varargout = imageDisplay(varargin)
% IMAGEDISPLAY MATLAB code for imageDisplay.fig
%      IMAGEDISPLAY, by itself, creates a new IMAGEDISPLAY or raises the existing
%      singleton*.
%
%      H = IMAGEDISPLAY returns the handle to a new IMAGEDISPLAY or the handle to
%      the existing singleton*.
%
%      IMAGEDISPLAY('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in IMAGEDISPLAY.M with the given input arguments.
%
%      IMAGEDISPLAY('Property','Value',...) creates a new IMAGEDISPLAY or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before imageDisplay_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to imageDisplay_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help imageDisplay

% Last Modified by GUIDE v2.5 29-Oct-2011 16:39:40

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @imageDisplay_OpeningFcn, ...
                   'gui_OutputFcn',  @imageDisplay_OutputFcn, ...
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


% --- Executes just before imageDisplay is made visible.
function imageDisplay_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to imageDisplay (see VARARGIN)

% Choose default command line output for imageDisplay
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes imageDisplay wait for user response (see UIRESUME)
% uiwait(handles.figure1);
 
 startingTitle = 'Image Display (ver. 0.94)';
 curTitle = get(handles.figure1, 'Name');
 switch curTitle 
     case 'imageDisplay'
         % first time through
          set(handles.figure1,'Name', startingTitle);
         % NET.addAssembly('d:\Lab System\Assemblies\XDMessaging.dll');
          import TheCodeKing.Net.Messaging.*
          GenericListener = TheCodeKing.Net.Messaging.XDListener;
          global RasterListener;
          RasterListener = GenericListener.CreateListener(XDTransportMode.MailSlot);
          addlistener(RasterListener,'MessageReceived',@MessageFromRasterInside);
          RasterListener.RegisterChannel('RasterToMatlab');
          setappdata(0, 'imageDisplayHandle', hObject);
          set(handles.figure1, 'CloseRequestFcn',@closeProgram)
     otherwise
         % already have done initial stuff
 end

 
 % Ben Functions below here
 
 % listener function
 function MessageFromRasterInside(sender , e)
     % hello
 fileName = char(e.DataGram.Message);
 loadImageFile(fileName);
 
 % load IMG function
 function loadImageFile(varargin)
     % hello
 if nargin == 0 
    [fileName pathName] = uigetfile('d:\*.img', 'Select *.img image stack file to open');
    fileName = [pathName fileName];
 else
    fileName = varargin{1};
 end
 zData = read2PRasterBen(fileName);
 hObject = getappdata(0, 'imageDisplayHandle');
 handles = guidata(hObject);
 set(handles.figure1,'Name',['Image Display - ' fileName '  (' num2str(zData.numFrames) ' frames)']);
 refreshDisplay;
 
% refreshes main display 
function refreshDisplay
hObject = getappdata(0, 'imageDisplayHandle');
handles = guidata(hObject);
zSet = readCurrentSettings;
[tempImage displayedFrames] = generateProcessedFrame(zSet);
zSet.displayedFrames = displayedFrames; 
if strcmp(zSet.autoPallete, 'on') 
   zSet.palleteMax = num2str(max(tempImage(:)));
   set(handles.txtMaxPallete, 'string', zSet.palleteMax);
   zSet.palleteMin = num2str(min(tempImage(:)));
   set(handles.txtMinPallete, 'string', zSet.palleteMin);
end
figHandle = displayFrame(tempImage, zSet);
setappdata(imageDisplay, 'figHandle', figHandle);
 
 % reads gui stuff
 function zSettings = readCurrentSettings
       % hello
 hObject = getappdata(0, 'imageDisplayHandle');
 handles = guidata(hObject);
 zSettings.curFrame = str2double(get(handles.txtFrameNum, 'string'));
 contents = cellstr(get(handles.popPallete, 'String'));
 zSettings.colorMode = contents{get(handles.popPallete,'Value')};
 zSettings.palleteMax = get(handles.txtMaxPallete, 'string');
 zSettings.palleteMin = get(handles.txtMinPallete, 'string');
 tempObj = get(handles.uipanel2, 'SelectedObject');
 zSettings.displayType = get(tempObj, 'string');
 tempObj = get(handles.uipanel4, 'SelectedObject');
 zSettings.zoom = get(tempObj, 'string');
 contents = cellstr(get(handles.popNumAverage, 'String'));
 zSettings.averageMode = contents{get(handles.popNumAverage,'Value')};
 zSettings.scaleBar = get(handles.mnuOptionsScaleBar, 'checked');
 zSettings.colorBar = get(handles.mnuOptionsColorBar, 'checked');  
 zSettings.baselineAverage = get(handles.txtNumBaselineFrames, 'string');
 enabled = get(handles.chkMedian, 'Value'); 
 if enabled == 1
   enableStr = 'on'; 
 else
    enableStr = 'off';
 end
 zSettings.medianEnable = enableStr;
 zSettings.medianNum = get(handles.txtMedianNum, 'string');
  enabled = get(handles.chkWeiner, 'Value'); 
 if enabled == 1
   enableStr = 'on'; 
 else
    enableStr = 'off';
 end
 zSettings.wienerEnable = enableStr;
 zSettings.wienerNum = get(handles.txtWeinerNum, 'string');
 enabled = get(handles.chkAuto, 'Value'); 
 if enabled == 1
   enableStr = 'on'; 
 else
    enableStr = 'off';
 end
 zSettings.autoPallete = enableStr;
 enabled = get(handles.chkInvert, 'Value'); 
 if enabled == 1
   enableStr = 'on'; 
 else
    enableStr = 'off';
 end
 zSettings.invertPallete = enableStr;
 enabled = get(handles.chkOdd, 'Value'); 
 if enabled == 1
   enableStr = 'on'; 
 else
    enableStr = 'off';
 end
 zSettings.oddRowsOkay = enableStr;
 
 
 % this is the universal way to end the program and release objects
 function closeProgram(src, evnt)
      % hello
 hFig = getappdata(imageDisplay, 'figHandle');
 close (hFig); % close display window with image
 global RasterListener;
 RasterListener.Dispose();
 clear('RasterListener');
 evalin('base', 'clear(''hFig'');');
 evalin('base', 'clear(''lastDisplayedFrame'');');
 evalin('base', 'clear(''displaySettings'');');
 delete(gcf);
         
  %
  %  End of Ben function
  %
 
% --- Outputs from this function are returned to the command line.
function varargout = imageDisplay_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in pushbutton1.
function pushbutton1_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in chkOdd.
function chkOdd_Callback(hObject, eventdata, handles)
% hObject    handle to chkOdd (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of chkOdd



function txtNumBaselineFrames_Callback(hObject, eventdata, handles)
% hObject    handle to txtNumBaselineFrames (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtNumBaselineFrames as text
%        str2double(get(hObject,'String')) returns contents of txtNumBaselineFrames as a double


% --- Executes during object creation, after setting all properties.
function txtNumBaselineFrames_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txtNumBaselineFrames (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --------------------------------------------------------------------
function mnuFile_Callback(hObject, eventdata, handles)
% hObject    handle to mnuFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function mnuDisplay_Callback(hObject, eventdata, handles)
% hObject    handle to mnuDisplay (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function mnuOptions_Callback(hObject, eventdata, handles)
% hObject    handle to mnuOptions (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function mnuOptionsColorBar_Callback(hObject, eventdata, handles)
% hObject    handle to mnuOptionsColorBar (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
enabled = get(hObject,'Checked');
if strcmp(enabled, 'on')
   enableStr = 'off'; 
else
   enableStr = 'on';
end
set(handles.mnuOptionsColorBar,'Checked', enableStr);

% --------------------------------------------------------------------
function mnuOptionsScaleBar_Callback(hObject, eventdata, handles)
% hObject    handle to mnuOptionsScaleBar (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
enabled = get(hObject,'Checked');
if strcmp(enabled, 'on')
   enableStr = 'off'; 
else
   enableStr = 'on';
end
set(handles.mnuOptionsScaleBar,'Checked', enableStr);

% --------------------------------------------------------------------
function mnuFileOpen_Callback(hObject, eventdata, handles)
% hObject    handle to mnuFileOpen (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
loadImageFile;

% --------------------------------------------------------------------
function mnuFileOpenStack_Callback(hObject, eventdata, handles)
% hObject    handle to mnuFileOpenStack (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function mnuFileSaveFrameAs_Callback(hObject, eventdata, handles)
% hObject    handle to mnuFileSaveFrameAs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function mnuFileEnd_Callback(hObject, eventdata, handles)
% hObject    handle to mnuFileEnd (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% RasterListener = getappdata(hObject, 'listeners');
% RasterListener.UnregisterChannel('RasterToMatlab');
close;

% --- Executes on selection change in popPallete.
function popPallete_Callback(hObject, eventdata, handles)
% hObject    handle to popPallete (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popPallete contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popPallete


% --- Executes during object creation, after setting all properties.
function popPallete_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popPallete (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in chkInvert.
function chkInvert_Callback(hObject, eventdata, handles)
% hObject    handle to chkInvert (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of chkInvert
refreshDisplay;


% --- Executes on button press in chkAuto.
function chkAuto_Callback(hObject, eventdata, handles)
% hObject    handle to chkAuto (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of chkAuto
enabled = get(hObject,'Value');
if enabled == 1
   enableStr = 'off'; 
else
   enableStr = 'on';
end
set(handles.txtMinPallete,'Enable', enableStr);
set(handles.txtMaxPallete,'Enable', enableStr);
refreshDisplay;

% --- Executes on selection change in popNumAverage.
function popNumAverage_Callback(hObject, eventdata, handles)
% hObject    handle to popNumAverage (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popNumAverage contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popNumAverage
refreshDisplay;


% --- Executes during object creation, after setting all properties.
function popNumAverage_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popNumAverage (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function txtFrameNum_Callback(hObject, eventdata, handles)
% hObject    handle to txtFrameNum (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtFrameNum as text
%        str2double(get(hObject,'String')) returns contents of txtFrameNum as a double
refreshDisplay;


% --- Executes during object creation, after setting all properties.
function txtFrameNum_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txtFrameNum (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in cmdForward.
function cmdForward_Callback(hObject, eventdata, handles)
% hObject    handle to cmdForward (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
curFrame = str2num(get(handles.txtFrameNum, 'String'));
if curFrame < evalin('base', 'zImage.numFrames')
    set(handles.txtFrameNum,'String', num2str(curFrame + 1));
    refreshDisplay;
end


% --- Executes on button press in cmdBack.
function cmdBack_Callback(hObject, eventdata, handles)
% hObject    handle to cmdBack (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
curFrame = str2num(get(handles.txtFrameNum, 'String'));
newFrame = curFrame - 1;
if newFrame < 1 
    newFrame = 1;
end
set(handles.txtFrameNum,'String', num2str(newFrame));
refreshDisplay;

% --- Executes on button press in cmdReset.
function cmdReset_Callback(hObject, eventdata, handles)
% hObject    handle to cmdReset (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.txtFrameNum,'String', '1');
refreshDisplay;


function txtMaxPallete_Callback(hObject, eventdata, handles)
% hObject    handle to txtMaxPallete (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtMaxPallete as text
%        str2double(get(hObject,'String')) returns contents of txtMaxPallete as a double
refreshDisplay;


% --- Executes during object creation, after setting all properties.
function txtMaxPallete_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txtMaxPallete (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function txtMinPallete_Callback(hObject, eventdata, handles)
% hObject    handle to txtMinPallete (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtMinPallete as text
%        str2double(get(hObject,'String')) returns contents of txtMinPallete as a double


% --- Executes during object creation, after setting all properties.
function txtMinPallete_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txtMinPallete (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in cmdRefresh.
function cmdRefresh_Callback(hObject, eventdata, handles)
% hObject    handle to cmdRefresh (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
refreshDisplay;


% --- Executes on button press in cmdWeiner.
function cmdWeiner_Callback(hObject, eventdata, handles)
% hObject    handle to cmdWeiner (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of cmdWeiner


% --- Executes on button press in chkMedian.
function chkMedian_Callback(hObject, eventdata, handles)
% hObject    handle to chkMedian (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of chkMedian
enabled = get(hObject,'Value');
if enabled == 1
   enableStr = 'on'; 
else
   enableStr = 'off';
end
set(handles.txtMedianNum,'Enable', enableStr);


function txtWeinerNum_Callback(hObject, eventdata, handles)
% hObject    handle to txtWeinerNum (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtWeinerNum as text
%        str2double(get(hObject,'String')) returns contents of txtWeinerNum as a double


% --- Executes during object creation, after setting all properties.
function txtWeinerNum_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txtWeinerNum (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit9_Callback(hObject, eventdata, handles)
% hObject    handle to edit9 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit9 as text
%        str2double(get(hObject,'String')) returns contents of edit9 as a double


% --- Executes during object creation, after setting all properties.
function edit9_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit9 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in chkWeiner.
function chkWeiner_Callback(hObject, eventdata, handles)
% hObject    handle to chkWeiner (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of chkWeiner
enabled = get(hObject,'Value');
if enabled == 1
   enableStr = 'on'; 
else
   enableStr = 'off';
end
set(handles.txtWeinerNum,'Enable', enableStr);

function txtMedianNum_Callback(hObject, eventdata, handles)
% hObject    handle to txtMedianNum (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtMedianNum as text
%        str2double(get(hObject,'String')) returns contents of txtMedianNum as a double


% --- Executes during object creation, after setting all properties.
function txtMedianNum_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txtMedianNum (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in chkOdd.
function checkbox9_Callback(hObject, eventdata, handles)
% hObject    handle to chkOdd (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of chkOdd
