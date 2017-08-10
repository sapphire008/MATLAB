function varargout = episodeDisplay(varargin)
% EPISODEDISPLAY MATLAB code for episodeDisplay.fig
%      EPISODEDISPLAY, by itself, creates a new EPISODEDISPLAY or raises the existing
%      singleton*.
%
%      H = EPISODEDISPLAY returns the handle to a new EPISODEDISPLAY or the handle to
%      the existing singleton*.
%
%      EPISODEDISPLAY('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in EPISODEDISPLAY.M with the given input arguments.
%
%      EPISODEDISPLAY('Property','Value',...) creates a new EPISODEDISPLAY or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before episodeDisplay_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to episodeDisplay_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help episodeDisplay

% Last Modified by GUIDE v2.5 26-Nov-2011 16:48:06

% Last revised by BWS on 26 Nov 2011

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @episodeDisplay_OpeningFcn, ...
                   'gui_OutputFcn',  @episodeDisplay_OutputFcn, ...
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


% --- Executes just before episodeDisplay is made visible.
function episodeDisplay_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to episodeDisplay (see VARARGIN)

% Choose default command line output for episodeDisplay
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes episodeDisplay wait for user response (see UIRESUME)
% uiwait(handles.figure1);

startingTitle = 'Episode Display';
curTitle = get(handles.figure1, 'Name');
switch curTitle 
    case 'episodeDisplay'
        % first time through
        set(handles.figure1,'Name', startingTitle);
        % NET.addAssembly('d:\Lab System\Assemblies\XDMessaging.dll');
        import TheCodeKing.Net.Messaging.*
        GenericListener = TheCodeKing.Net.Messaging.XDListener;
        global SynapseListener;
        SynapseListener = GenericListener.CreateListener(XDTransportMode.MailSlot);
        addlistener(SynapseListener,'MessageReceived',@MessageFromSynapseInside);
        SynapseListener.RegisterChannel('ToMatlab');
        setappdata(0, 'episodeDisplayHandle', hObject);
        set(handles.figure1, 'CloseRequestFcn',@closeProgram)
    otherwise
        % already have done initial stuff
end

function MessageFromSynapseInside(sender , e)
     % hello
 fileName = char(e.DataGram.Message);
 hObject = getappdata(0, 'episodeDisplayHandle');
 handles = guidata(hObject);
 checked = get(handles.chkListenToSynapse, 'Value'); 
 if checked == 1
   zData = loadEpisodeFile(fileName);
   assignin('base', 'zData', zData);
   set(handles.pnlVarNames, 'String', getEpisodeDescStr);
   if get(handles.chkExecuteMFile, 'value') == 1
    runMFile;
   end
 end
 
 function descStr = getEpisodeDescStr
    % hello
  zData = evalin('base', 'zData');
  fn = getSeqEpiNumbers(zData.protocol.savedFileName);
  timeStr = getTimeAsString(zData.protocol.WCtime);
  numChan = num2str(zData.protocol.numTraces);
  descStr = [fn ' - ' numChan ' traces - ' timeStr '  (' num2str(zData.protocol.msPerPoint) ' ms)'];
 
 function loadMFileInside()
     % hello
 [fileName pathName] = uigetfile('D:\Lab Matlab Files\*.m;', 'Matlab mFiles');
 fileNameNoSuffix = fileName(1:end-2);
 hObject = getappdata(0, 'episodeDisplayHandle');
 handles = guidata(hObject);
 set(handles.txtMFileName, 'String', fileNameNoSuffix);

 function runMFile
     % hello
 hObject = getappdata(0, 'episodeDisplayHandle');
 handles = guidata(hObject);
 mFileName = get(handles.txtMFileName, 'String');
 try
     eval(mFileName);
 catch
     msgbox(['Problem executing mFile: ' mFileName]);
 end
 
 
 function closeProgram(src, evnt)
      % hello
 global SynapseListener;
 SynapseListener.Dispose();
 clear('SynapseListener');
 delete(gcf);



% --- Outputs from this function are returned to the command line.
function varargout = episodeDisplay_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in cmdExecuteMFile.
function cmdExecuteMFile_Callback(hObject, eventdata, handles)
% hObject    handle to cmdExecuteMFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
runMFile;

% --- Executes on button press in chkListenToSynapse.
function chkListenToSynapse_Callback(hObject, eventdata, handles)
% hObject    handle to chkListenToSynapse (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of chkListenToSynapse


% --- Executes on button press in chkExecuteMFile.
function chkExecuteMFile_Callback(hObject, eventdata, handles)
% hObject    handle to chkExecuteMFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of chkExecuteMFile
curState = get(hObject, 'Value');
if curState == 1
   enableStr = 'on'; 
 else
    enableStr = 'off';
end
set(handles.txtMFileName, 'Enable', enableStr);
set(handles.cmdExecuteMFile, 'Enable', enableStr);
set(handles.cmdFindMFile, 'Enable', enableStr);

function txtMFileName_Callback(hObject, eventdata, handles)
% hObject    handle to txtMFileName (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtMFileName as text
%        str2double(get(hObject,'String')) returns contents of txtMFileName as a double


% --- Executes during object creation, after setting all properties.
function txtMFileName_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txtMFileName (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in cmdFindMFile.
function cmdFindMFile_Callback(hObject, eventdata, handles)
% hObject    handle to cmdFindMFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
loadMFileInside;