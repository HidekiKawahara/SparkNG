function varargout = recordingGUIV7(varargin)
%   Reconding GUI with realtime FFT analyzer and other viewers. Type:
%   recordingGUIV7
%   to start.

%   Designed and coded by Hideki Kawahara (kawahara AT sys.wakayama-u.ac.jp)
%   28/Nov./2013
%   29/Nov./2013 minor bug fix
%   13/Dec./2013 spectrogram and playback functions are added.
%   15/Dec./2013 scrubbing mode is added.
%   21/Dec./2013 load button is added.
%   17/April/2014 audio related I/O and other revisions
%   03/May/2014 audio out is revised
%   04/May/2014 alternate audo out server
%   31/Aug./2015 machine independent and resizable

% This work is licensed under the Creative Commons 
% Attribution 4.0 International License.
% To view a copy of this license, visit
% http://creativecommons.org/licenses/by/4.0/.

% RECORDINGGUIV7 MATLAB code for recordingGUIV7.fig
%      RECORDINGGUIV7, by itself, creates a new RECORDINGGUIV7 or raises the existing
%      singleton*.
%
%      H = RECORDINGGUIV7 returns the handle to a new RECORDINGGUIV7 or the handle to
%      the existing singleton*.
%
%      RECORDINGGUIV7('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in RECORDINGGUIV7.M with the given input arguments.
%
%      RECORDINGGUIV7('Property','Value',...) creates a new RECORDINGGUIV7 or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before recordingGUIV7_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to recordingGUIV7_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help recordingGUIV7

% Last Modified by GUIDE v2.5 04-May-2014 07:46:29

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @recordingGUIV7_OpeningFcn, ...
    'gui_OutputFcn',  @recordingGUIV7_OutputFcn, ...
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

% --- Executes just before recordingGUIV7 is made visible.
function recordingGUIV7_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to recordingGUIV7 (see VARARGIN)

%global handleForTimer;
% Choose default command line output for recordingGUIV7
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);
%handles
delete(timerfindall);
%pause(0.05)
initializeDisplay(handles);
myGUIdata = guidata(handles.multiScopeMainGUI);
%set(myGUIdata.largeViewTypePopup,'enable','off');
set(myGUIdata.saveButton,'enable','off');
set(myGUIdata.spectrogramHandle,'visible','off');
set(myGUIdata.sgramAxis,'visible','off');
set(myGUIdata.playAllButton,'enable','off');
set(myGUIdata.playVisibleButton,'enable','off');
set(myGUIdata.saveVisibleButton,'enable','off');
set(myGUIdata.playTFregion,'enable','off');
set(myGUIdata.loadButton,'enable','off');
%pause(0.5)
timerEventInterval = 0.1; % in second
timer50ms = timer('TimerFcn',@synchDrawGUI, 'Period',timerEventInterval,'ExecutionMode','fixedRate', ...
    'userData',handles.multiScopeMainGUI);
myGUIdata.timer50ms = timer50ms;
timerEventIntervalForPlay = 0.10; % in second
timerForPlayer = timer('TimerFcn',@audioTimerServer, 'Period',timerEventIntervalForPlay,'ExecutionMode','fixedRate', ...
    'userData',handles.multiScopeMainGUI);
myGUIdata.timerForPlayer = timerForPlayer;
myGUIdata.player1 = audioplayer(zeros(1000,1),44100);
myGUIdata.player2 = audioplayer(zeros(1000,1),44100);
myGUIdata.player3 = audioplayer(zeros(1000,1),44100);
myGUIdata.player4 = audioplayer(zeros(1000,1),44100);
myGUIdata.player5 = audioplayer(zeros(1000,1),44100);
myGUIdata.maximumNumberOfAudioPlayers = 3;
myGUIdata.smallviewerWidth = 30; % 30 ms is defaule
myGUIdata.samplingFrequency = 44100;
myGUIdata.recordObj1 = audiorecorder(myGUIdata.samplingFrequency,24,1);
myGUIdata.liveData = 'yes';
record(myGUIdata.recordObj1)
switch get(myGUIdata.recordObj1,'Running')
    case 'on'
        stop(myGUIdata.recordObj1);
end
myGUIdata.pointerMode = 'normal';
myGUIdata.initializeScrubbing = 0;
guidata(handles.multiScopeMainGUI,myGUIdata);
startButton_Callback(hObject, eventdata, handles)
% UIWAIT makes recordingGUIV7 wait for user response (see UIRESUME)
% uiwait(handles.multiScopeMainGUI);
end

function audioTimerServer(obj, event, string_arg)
%global handleForTimer;
handleForTimer = get(obj,'userData');
myGUIdata = guidata(handleForTimer);
visibleIndex = get(myGUIdata.cursorFringeHandle,'userdata');
switch myGUIdata.pointerMode
    case 'dragging'
        switch get(myGUIdata.withAudioRadioButton,'value')
            case 1
                if ~isplaying(myGUIdata.player1)
                    play(myGUIdata.player1,[visibleIndex(1) visibleIndex(end)]);
                    %myGUIdata.player1 = audioplayer(myGUIdata.audioData(visibleIndex),myGUIdata.samplingFrequency);
                    %play(myGUIdata.player1);
                elseif myGUIdata.maximumNumberOfAudioPlayers >= 2 && ~isplaying(myGUIdata.player2)
                    play(myGUIdata.player2,[visibleIndex(1) visibleIndex(end)]);
                elseif myGUIdata.maximumNumberOfAudioPlayers >= 3 && ~isplaying(myGUIdata.player3)
                    play(myGUIdata.player3,[visibleIndex(1) visibleIndex(end)]);
                elseif myGUIdata.maximumNumberOfAudioPlayers >= 4 && ~isplaying(myGUIdata.player4)
                    play(myGUIdata.player4,[visibleIndex(1) visibleIndex(end)]);
                elseif myGUIdata.maximumNumberOfAudioPlayers >= 5 && ~isplaying(myGUIdata.player5)
                    play(myGUIdata.player5,[visibleIndex(1) visibleIndex(end)]);
                end
        end;
end;
end

function initializeDisplay(handles)
myGUIdata = guidata(handles.multiScopeMainGUI);
myGUIdata.maxAudioRecorderCount = 200;
myGUIdata.audioRecorderCount = myGUIdata.maxAudioRecorderCount;
myGUIdata.maxLevelIndicator = -100*ones(myGUIdata.maxAudioRecorderCount,1);
myGUIdata.yMax = 1;
axes(myGUIdata.smallViewerAxis);
myGUIdata.windowViewHandle = plot(randn(1000,1),'g-','linewidth',3);
hold on;
myGUIdata.smallViewerPlotHandle = plot(randn(1000,1),'b');
set(myGUIdata.smallViewerAxis,'xtick',[],'ytick',[]);
axes(myGUIdata.largeViewerAxis);
fs = 44100;
dataLength = round(30/1000*fs);
fftl = 2.0.^ceil(log2(dataLength));
fAxis = (0:fftl-1)/fftl*fs;
w = blackman(dataLength);
pw = 20*log10(abs(fft(randn(dataLength,1).*w,fftl)/sqrt(sum(w.^2))));
myGUIdata.axisType = 'Logarithmic';
myGUIdata.window = w;
myGUIdata.fAxis = fAxis;
switch myGUIdata.axisType
    case 'Linear'
        myGUIdata.largeViewerPlotHandle = plot(fAxis,pw);grid on;
        axis([0 fs/2 [-90 20]]);
    case 'Logarithmic'
        myGUIdata.largeViewerPlotHandle = semilogx(fAxis,pw);grid on;
        axis([10 fs/2 [-90 20]]);
end;
set(gca,'fontsize',15);
xlabel('frequency (Hz)');
ylabel('level (dB)');
axes(myGUIdata.wholeViewerAxis);
myGUIdata.wholeViewerHandle = plot(myGUIdata.maxLevelIndicator);
axis([0 myGUIdata.maxAudioRecorderCount -100 0]);
set(myGUIdata.wholeViewerAxis,'xtick',[],'ylim',[-80 0]);grid on;
axes(myGUIdata.sgramAxis);
myGUIdata.spectrogramHandle = imagesc(rand(1024,200));axis('xy');
hold on;
myGUIdata.cursorFringeHandle = plot([180 180 220 220],[-5 1027 1027 -5],'g','linewidth',2);
myGUIdata.cursorHandle = plot([200 200],[0 1024],'ws-','linewidth',4);
hold off;
axis('off')
set(myGUIdata.sgramAxis,'visible','off')
set(myGUIdata.cursorFringeHandle,'visible','off')
set(myGUIdata.cursorFringeHandle,'userdata',[0 1]);
set(myGUIdata.cursorHandle,'visible','off','userData',handles.multiScopeMainGUI);
set(myGUIdata.cursotPositionText,'visible','off');
myGUIdata.channelMenuString = cellstr(get(myGUIdata.channelPopupMenu,'String'));
set(myGUIdata.channelPopupMenu,'visible','off');
set(myGUIdata.withAudioRadioButton,'enable','off');
set(myGUIdata.withAudioRadioButton,'value',0);
myGUIdata.player = audioplayer(zeros(1000,1),44100);
myGUIdata.maximumNumberOfAudioPlayers = 1;
for ii = 1:myGUIdata.maximumNumberOfAudioPlayers
    myGUIdata.audioPlayerGroup(ii) = audioplayer(zeros(1000,1),44100);
end;
guidata(handles.multiScopeMainGUI,myGUIdata);
end

function synchDrawGUI(obj, event, string_arg)
%global handleForTimer;
handleForTimer = get(obj,'userData');
myGUIdata = guidata(handleForTimer);
myGUIdata.smallviewerWidth = get(myGUIdata.radiobutton10ms,'value')*10+ ...
    get(myGUIdata.radiobutton30ms,'value')*30+ ...
    get(myGUIdata.radiobutton100ms,'value')*100+ ...
    get(myGUIdata.radiobutton300ms,'value')*300;
numberOfSamples = round(myGUIdata.smallviewerWidth*myGUIdata.samplingFrequency/1000);
if get(myGUIdata.recordObj1,'TotalSamples') > numberOfSamples
    tmpAudio = getaudiodata(myGUIdata.recordObj1);
    currentPoint = length(tmpAudio);
    xdata = 1:numberOfSamples;
    fs = myGUIdata.samplingFrequency;
    %disp(myGUIdata.audioRecorderCount)
    if length(currentPoint-numberOfSamples+1:currentPoint) > 10
        ydata = tmpAudio(currentPoint-numberOfSamples+1:currentPoint);
        myGUIdata.audioRecorderCount = myGUIdata.audioRecorderCount-1;
        set(myGUIdata.smallViewerPlotHandle,'xdata',xdata,'ydata',ydata);
        if myGUIdata.yMax < max(abs(ydata))
            myGUIdata.yMax = max(abs(ydata));
        else
            myGUIdata.yMax = myGUIdata.yMax*0.8;
        end;
        set(myGUIdata.smallViewerAxis,'xlim',[0 numberOfSamples],'ylim',myGUIdata.yMax*[-1 1]);
        fftl = 2^ceil(log2(numberOfSamples));
        fAxis = (0:fftl-1)/fftl*fs;
        switch get(myGUIdata.windowTypePopup,'value')
            case 1
                w = blackman(numberOfSamples);
            case 2
                w = hamming(numberOfSamples);
            case 3
                w = hanning(numberOfSamples);
            case 4
                w = bartlett(numberOfSamples);
            case 5
                w = ones(numberOfSamples,1);
            case 6
                w = nuttallwin(numberOfSamples);
            otherwise
                w = blackman(numberOfSamples);
        end;
        windowView = w*myGUIdata.yMax*2-myGUIdata.yMax;
        set(myGUIdata.windowViewHandle,'xdata',xdata,'ydata',windowView);
        pw = 20*log10(abs(fft(ydata.*w,fftl)/sqrt(sum(w.^2))));
        set(myGUIdata.largeViewerPlotHandle,'xdata',fAxis,'ydata',pw);
        myGUIdata.maxLevelIndicator(max(1,myGUIdata.maxAudioRecorderCount-myGUIdata.audioRecorderCount)) ...
            = max(20*log10(abs(ydata)));
        set(myGUIdata.wholeViewerHandle,'ydata',myGUIdata.maxLevelIndicator);
    else
        disp('overrun!')
    end;
    if myGUIdata.audioRecorderCount < 0
        switch get(myGUIdata.timer50ms,'running')
            case 'on'
                stop(myGUIdata.timer50ms);
        end
        stop(myGUIdata.recordObj1);
        record(myGUIdata.recordObj1);
        myGUIdata.audioRecorderCount = myGUIdata.maxAudioRecorderCount;
        myGUIdata.maxLevelIndicator = 0;
        %    switch get(myGUIdata.timer50ms,'running')
        %        case 'on'
        %            stop(myGUIdata.timer50ms)
        %    end;
        switch get(myGUIdata.timer50ms,'running')
            case 'off'
                start(myGUIdata.timer50ms);
        end
    end;
    guidata(handleForTimer,myGUIdata);
else
    disp(['Recorded data is not enough! Skipping this interruption....at ' datestr(now,30)]);
end;
end

% --- Outputs from this function are returned to the command line.
function varargout = recordingGUIV7_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
end

% --- Executes on button press in startButton.
function startButton_Callback(hObject, eventdata, handles)
% hObject    handle to startButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%global handleForTimer
myGUIdata = guidata(handles.multiScopeMainGUI);
switch myGUIdata.liveData
    case 'no'
        myGUIdata.liveData = 'yes';
        myGUIdata.samplingFrequency = 44100;
end;
stop(myGUIdata.timerForPlayer);
set(myGUIdata.saveButton,'enable','off');
set(myGUIdata.startButton,'enable','off');
set(myGUIdata.stopButton,'enable','on');
set(myGUIdata.playAllButton,'enable','off');
set(myGUIdata.playVisibleButton,'enable','off');
set(myGUIdata.saveVisibleButton,'enable','off');
set(myGUIdata.playTFregion,'enable','off');
set(myGUIdata.loadButton,'enable','off');
set(myGUIdata.cursorHandle,'visible','off');
set(myGUIdata.cursorFringeHandle,'visible','off');
set(myGUIdata.scrubbingButton,'enable','off','value',0);
set(myGUIdata.channelPopupMenu,'visible','off');
switch get(myGUIdata.timer50ms,'running')
    case 'on'
        stop(myGUIdata.timer50ms);
end
myGUIdata.audioRecorderCount = myGUIdata.maxAudioRecorderCount;
myGUIdata.maxLevelIndicator = -100*ones(myGUIdata.maxAudioRecorderCount,1);
myGUIdata.yMax = 1;
record(myGUIdata.recordObj1);
datacursormode off
switch get(myGUIdata.timer50ms,'running')
    case 'off'
        start(myGUIdata.timer50ms);
    case 'on'
    otherwise
        disp('timer is bloken!');
end
set(myGUIdata.sgramAxis,'visible','off')
set(myGUIdata.spectrogramHandle,'visible','off')
set(myGUIdata.wholeViewerAxis,'visible','on');
set(myGUIdata.zoomInTool,'enable','on');
set(myGUIdata.zoomOutTool,'enable','on');
set(myGUIdata.PanTool,'enable','on');
set(myGUIdata.dataCursorTool,'enable','on');
guidata(handles.multiScopeMainGUI,myGUIdata);
end


% --- Executes on button press in stopButton.
function stopButton_Callback(hObject, eventdata, handles)
% hObject    handle to stopButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
myGUIdata = guidata(handles.multiScopeMainGUI);
myGUIdata.audioData = getaudiodata(myGUIdata.recordObj1);
%disp('timer ends')
%set(myGUIdata.startButton,'enable','off');
set(myGUIdata.saveButton,'enable','on');
set(myGUIdata.startButton,'enable','on');
set(myGUIdata.stopButton,'enable','off');
set(myGUIdata.playAllButton,'enable','on');
set(myGUIdata.playVisibleButton,'enable','on');
set(myGUIdata.saveVisibleButton,'enable','on');
set(myGUIdata.loadButton,'enable','on');
datacursormode off
switch get(myGUIdata.timer50ms,'running')
    case 'on'
        stop(myGUIdata.timer50ms)
    case 'off'
    otherwise
        disp('timer is bloken!');
end;
stop(myGUIdata.recordObj1);
myGUIdata.player1 = audioplayer(myGUIdata.audioData,myGUIdata.samplingFrequency);
myGUIdata.player2 = audioplayer(myGUIdata.audioData,myGUIdata.samplingFrequency);
myGUIdata.player3 = audioplayer(myGUIdata.audioData,myGUIdata.samplingFrequency);
myGUIdata.player4 = audioplayer(myGUIdata.audioData,myGUIdata.samplingFrequency);
myGUIdata.player5 = audioplayer(myGUIdata.audioData,myGUIdata.samplingFrequency);
set(handles.multiScopeMainGUI,'pointer','watch');drawnow
sgramStructure = stftSpectrogramStructure(myGUIdata.audioData,myGUIdata.samplingFrequency,15,2,'blackman');
set(myGUIdata.spectrogramHandle,'cdata',max(-80,sgramStructure.dBspectrogram),'visible','on', ...
    'xdata',sgramStructure.temporalPositions,'ydata',sgramStructure.frequencyAxis);
set(myGUIdata.sgramAxis,'visible','on', ...
    'xlim',[sgramStructure.temporalPositions(1) sgramStructure.temporalPositions(end)], ...
    'ylim',[sgramStructure.frequencyAxis(1) sgramStructure.frequencyAxis(end)]);
set(myGUIdata.wholeViewerAxis,'visible','off');
set(handles.multiScopeMainGUI,'pointer','arrow');drawnow
set(myGUIdata.playTFregion,'enable','on');
set(myGUIdata.scrubbingButton,'enable','on','value',0);
start(myGUIdata.timerForPlayer);
guidata(handles.multiScopeMainGUI,myGUIdata);
end


% --- Executes on selection change in windowTypePopup.
function windowTypePopup_Callback(hObject, eventdata, handles)
% hObject    handle to windowTypePopup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns windowTypePopup contents as cell array
%        contents{get(hObject,'Value')} returns selected item from windowTypePopup
myGUIdata = guidata(handles.multiScopeMainGUI);
switch get(myGUIdata.timer50ms,'running')
    case 'off'
        myGUIdata.initializeScrubbing = 1;
        myGUIdata.pointerMode = 'dragging';
        guidata(handles.multiScopeMainGUI,myGUIdata);
        windowMotionFcnForManipulation(handles.multiScopeMainGUI,eventdata)
        myGUIdata.pointerMode = 'normal';
        guidata(handles.multiScopeMainGUI,myGUIdata);
end;
end


% --- Executes during object creation, after setting all properties.
function windowTypePopup_CreateFcn(hObject, eventdata, handles)
% hObject    handle to windowTypePopup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


% --- Executes on button press in radiobutton10ms.
function radiobutton10ms_Callback(hObject, eventdata, handles)
% hObject    handle to radiobutton10ms (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of radiobutton10ms
myGUIdata = guidata(handles.multiScopeMainGUI);
set(handles.radiobutton10ms,'value',1);
set(handles.radiobutton30ms,'value',0);
set(handles.radiobutton100ms,'value',0);
set(handles.radiobutton300ms,'value',0);
switch get(myGUIdata.timer50ms,'running')
    case 'off'
        myGUIdata.initializeScrubbing = 1;
        myGUIdata.pointerMode = 'dragging';
        guidata(handles.multiScopeMainGUI,myGUIdata);
        windowMotionFcnForManipulation(handles.multiScopeMainGUI,eventdata)
        myGUIdata.pointerMode = 'normal';
        guidata(handles.multiScopeMainGUI,myGUIdata);
end;
end


% --- Executes on button press in radiobutton30ms.
function radiobutton30ms_Callback(hObject, eventdata, handles)
% hObject    handle to radiobutton30ms (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of radiobutton30ms
myGUIdata = guidata(handles.multiScopeMainGUI);
set(handles.radiobutton10ms,'value',0);
set(handles.radiobutton30ms,'value',1);
set(handles.radiobutton100ms,'value',0);
set(handles.radiobutton300ms,'value',0);
switch get(myGUIdata.timer50ms,'running')
    case 'off'
        myGUIdata.initializeScrubbing = 1;
        myGUIdata.pointerMode = 'dragging';
        guidata(handles.multiScopeMainGUI,myGUIdata);
        windowMotionFcnForManipulation(handles.multiScopeMainGUI,eventdata)
        myGUIdata.pointerMode = 'normal';
        guidata(handles.multiScopeMainGUI,myGUIdata);
end;
end


% --- Executes on button press in radiobutton100ms.
function radiobutton100ms_Callback(hObject, eventdata, handles)
% hObject    handle to radiobutton100ms (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of radiobutton100ms
myGUIdata = guidata(handles.multiScopeMainGUI);
set(handles.radiobutton10ms,'value',0);
set(handles.radiobutton30ms,'value',0);
set(handles.radiobutton100ms,'value',1);
set(handles.radiobutton300ms,'value',0);
switch get(myGUIdata.timer50ms,'running')
    case 'off'
        myGUIdata.initializeScrubbing = 1;
        myGUIdata.pointerMode = 'dragging';
        guidata(handles.multiScopeMainGUI,myGUIdata);
        windowMotionFcnForManipulation(handles.multiScopeMainGUI,eventdata)
        myGUIdata.pointerMode = 'normal';
        guidata(handles.multiScopeMainGUI,myGUIdata);
end;
end


% --- Executes on button press in radiobutton300ms.
function radiobutton300ms_Callback(hObject, eventdata, handles)
% hObject    handle to radiobutton300ms (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of radiobutton300ms
myGUIdata = guidata(handles.multiScopeMainGUI);
set(handles.radiobutton10ms,'value',0);
set(handles.radiobutton30ms,'value',0);
set(handles.radiobutton100ms,'value',0);
set(handles.radiobutton300ms,'value',1);
switch get(myGUIdata.timer50ms,'running')
    case 'off'
        myGUIdata.initializeScrubbing = 1;
        myGUIdata.pointerMode = 'dragging';
        guidata(handles.multiScopeMainGUI,myGUIdata);
        windowMotionFcnForManipulation(handles.multiScopeMainGUI,eventdata)
        myGUIdata.pointerMode = 'normal';
        guidata(handles.multiScopeMainGUI,myGUIdata);
end;
end


% --- Executes on selection change in axisTypePopup.
function axisTypePopup_Callback(hObject, eventdata, handles)
% hObject    handle to axisTypePopup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns axisTypePopup contents as cell array
%        contents{get(hObject,'Value')} returns selected item from axisTypePopup
myGUIdata = guidata(handles.multiScopeMainGUI);
fs = myGUIdata.samplingFrequency;
switch get(myGUIdata.axisTypePopup,'value')
    case 1
        set(myGUIdata.largeViewerAxis,'xlim',[10 fs/2],'xscale','log');
    case 2
        set(myGUIdata.largeViewerAxis,'xlim',[0 fs/2],'xscale','linear');
    case 3
        set(myGUIdata.largeViewerAxis,'xlim',[0 10000],'xscale','linear');
    case 4
        set(myGUIdata.largeViewerAxis,'xlim',[0 8000],'xscale','linear');
    case 5
        set(myGUIdata.largeViewerAxis,'xlim',[0 4000],'xscale','linear');
    otherwise
        set(myGUIdata.largeViewerAxis,'xlim',[10 fs/2],'xscale','log');
end;
switch get(myGUIdata.timer50ms,'running')
    case 'off'
        myGUIdata.initializeScrubbing = 1;
        myGUIdata.pointerMode = 'dragging';
        guidata(handles.multiScopeMainGUI,myGUIdata);
        windowMotionFcnForManipulation(handles.multiScopeMainGUI,eventdata)
        myGUIdata.pointerMode = 'normal';
        guidata(handles.multiScopeMainGUI,myGUIdata);
end;
end


% --- Executes during object creation, after setting all properties.
function axisTypePopup_CreateFcn(hObject, eventdata, handles)
% hObject    handle to axisTypePopup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


% --- Executes on button press in quitButton.
function quitButton_Callback(hObject, eventdata, handles)
% hObject    handle to quitButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
myGUIdata = guidata(handles.multiScopeMainGUI);
%disp('timer ends')
switch get(myGUIdata.timer50ms,'running')
    case 'on'
        stop(myGUIdata.timer50ms)
end;
stop(myGUIdata.recordObj1);
delete(myGUIdata.timer50ms);
delete(myGUIdata.recordObj1);
close(handles.multiScopeMainGUI);
end


% --- Executes on button press in saveButton.
function saveButton_Callback(hObject, eventdata, handles)
% hObject    handle to saveButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
myGUIdata = guidata(handles.multiScopeMainGUI);
outFileName = ['audioIn' datestr(now,30) '.wav'];
[file,path] = uiputfile(outFileName,'Save the captured data');
if length(file) == 1 && length(path) == 1
    if file == 0 || path == 0
        %okInd = 0;
        disp('Save is cancelled!');
        return;
    end;
end;
%audiowrite(myGUIdata.audioData,myGUIdata.samplingFrequency,24,[path file]);
audiowrite([path file],myGUIdata.audioData,myGUIdata.samplingFrequency,'BitsPerSample',24);
end


% --- Executes on button press in saveVisibleButton.
function saveVisibleButton_Callback(hObject, eventdata, handles)
% hObject    handle to saveVisibleButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
myGUIdata = guidata(handles.multiScopeMainGUI);
outFileName = ['audioInTrim' datestr(now,30) '.wav'];
[file,path] = uiputfile(outFileName,'Save the visible data');
if length(file) == 1 && length(path) == 1
    if file == 0 || path == 0
        %okInd = 0;
        disp('Save is cancelled!');
        return;
    end;
end;
xLimit = get(myGUIdata.sgramAxis,'xlim');
fs = myGUIdata.samplingFrequency;
x = myGUIdata.audioData;
x = x(max(1,min(length(x),round(fs*xLimit(1)):round(fs*xLimit(end)))));
audiowrite([path file],x,fs,'BitsPerSample',24);
end

% --- Executes on button press in playAllButton.
function playAllButton_Callback(hObject, eventdata, handles)
% hObject    handle to playAllButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
myGUIdata = guidata(handles.multiScopeMainGUI);
x = myGUIdata.audioData;
fs = myGUIdata.samplingFrequency;
myGUIdata.player = audioplayer(x/max(abs(x))*0.9,fs);
guidata(handles.multiScopeMainGUI,myGUIdata);
play(myGUIdata.player);
end

% --- Executes on button press in playVisibleButton.
function playVisibleButton_Callback(hObject, eventdata, handles)
% hObject    handle to playVisibleButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
myGUIdata = guidata(handles.multiScopeMainGUI);
xLimit = get(myGUIdata.sgramAxis,'xlim');
fs = myGUIdata.samplingFrequency;
x = myGUIdata.audioData;
x = x(max(1,min(length(x),round(fs*xLimit(1)):round(fs*xLimit(end)))));
myGUIdata.player = audioplayer(x/max(abs(x))*0.99,fs);
guidata(handles.multiScopeMainGUI,myGUIdata);
playblocking(myGUIdata.player);
end


% --------------------------------------------------------------------
function Untitled_1_Callback(hObject, eventdata, handles)
% hObject    handle to Untitled_1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
end


% --- Executes on button press in playTFregion.
function playTFregion_Callback(hObject, eventdata, handles)
% hObject    handle to playTFregion (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
myGUIdata = guidata(handles.multiScopeMainGUI);
xLimit = get(myGUIdata.sgramAxis,'xlim');
yLimit = get(myGUIdata.sgramAxis,'ylim');
fs = myGUIdata.samplingFrequency;
fqLow = min(fs/2,max(0,yLimit(1)));
fqHigh = max(0,min(fs/2,yLimit(2)));
if fqLow < 20
    fftl = 2.0.^ceil(log2(fs/fqHigh*6));
    fAxis = (0:fftl/2)'/fftl*fs;
    doubleFAxis = [fAxis(:);fAxis(end-1:-1:2)];
    gain = 1*(abs(doubleFAxis)<fqHigh); % low pass filter
elseif fqHigh > fs/2*0.9
    fftl = 2.0.^ceil(log2(fs/fqLow*6));
    fAxis = (0:fftl/2)'/fftl*fs;
    doubleFAxis = [fAxis(:);fAxis(end-1:-1:2)];
    gain = 1*(abs(doubleFAxis)>fqLow); % high pass filter
else
    fftl = 2.0.^ceil(log2(fs/fqLow*6));
    fAxis = (0:fftl/2)'/fftl*fs;
    doubleFAxis = [fAxis(:);fAxis(end-1:-1:2)];
    gain = 1*((abs(doubleFAxis)>fqLow) & (abs(doubleFAxis)<fqHigh)); % high pass filter
end;
switch get(myGUIdata.windowTypePopup,'value')
    case 1
        w = blackman(fftl);
    case 2
        w = hamming(fftl);
    case 3
        w = hanning(fftl);
    case 4
        w = bartlett(fftl);
    case 5
        w = ones(fftl,1);
    case 6
        w = nuttallwin(fftl);
    otherwise
        w = blackman(numberOfSamples);
end;
wFIR = real(fftshift(ifft(gain)).*w);
x = myGUIdata.audioData;
x = x(max(1,min(length(x),round(fs*xLimit(1)):round(fs*xLimit(end)))));
y = fftfilt(wFIR,x);
myGUIdata.player = audioplayer(y/max(abs(y))*0.99,fs);
guidata(handles.multiScopeMainGUI,myGUIdata);
playblocking(myGUIdata.player);
end


% --- Executes on button press in scrubbingButton.
function scrubbingButton_Callback(hObject, eventdata, handles)
% hObject    handle to scrubbingButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of scrubbingButton
myGUIdata = guidata(handles.multiScopeMainGUI);
switch get(myGUIdata.zoomInTool,'state')
    case 'on'
        set(hObject,'value',0)
        return;
end
switch get(myGUIdata.zoomOutTool,'state')
    case 'on'
        set(hObject,'value',0)
        return;
end
switch get(myGUIdata.PanTool,'state')
    case 'on'
        set(hObject,'value',0)
        return;
end
switch get(myGUIdata.dataCursorTool,'state')
    case 'on'
        set(hObject,'value',0)
        return;
end
switch get(hObject,'value')
    case 1
        set(myGUIdata.zoomInTool,'enable','off');
        set(myGUIdata.zoomOutTool,'enable','off');
        set(myGUIdata.PanTool,'enable','off');
        set(myGUIdata.dataCursorTool,'enable','off');
        set(myGUIdata.withAudioRadioButton,'enable','on');
        xlim = get(myGUIdata.sgramAxis,'xlim');
        ylim = get(myGUIdata.sgramAxis,'ylim');
        ylimShrink = (ylim*0.98+0.02*mean(ylim));
        set(myGUIdata.cursorHandle,'xdata',[1 1]*mean(xlim),...
            'ydata',ylimShrink,'visible','on');
        set(myGUIdata.multiScopeMainGUI,'WindowButtonMotionFcn',@windowMotionFcnForManipulation);
        set(myGUIdata.multiScopeMainGUI,'WindowButtonUpFcn',@windowButtonUpFcnForManipulation);
        set(handles.cursorHandle,'ButtonDownFcn',@sgramCursorButtonDownFCN);
        myGUIdata.initializeScrubbing = 1;
        myGUIdata.pointerMode = 'dragging';
        guidata(handles.multiScopeMainGUI,myGUIdata);
        windowMotionFcnForManipulation(handles.multiScopeMainGUI,eventdata)
        myGUIdata.pointerMode = 'normal';
        guidata(handles.multiScopeMainGUI,myGUIdata);
    case 0
        set(myGUIdata.zoomInTool,'enable','on');
        set(myGUIdata.zoomOutTool,'enable','on');
        set(myGUIdata.PanTool,'enable','on');
        set(myGUIdata.dataCursorTool,'enable','on');
        set(myGUIdata.cursorHandle,'visible','off');
        set(myGUIdata.withAudioRadioButton,'enable','off');
        set(myGUIdata.multiScopeMainGUI,'WindowButtonMotionFcn','');
        set(myGUIdata.multiScopeMainGUI,'WindowButtonUpFcn','');
        set(handles.cursorHandle,'ButtonDownFcn','');
end;
end

% ----------------- private event handlers ------------------

function windowMotionFcnForManipulation(src,evnt)
myGUIdata = guidata(src);
%switch get(myGUIdata.player,'Running')
%    case 'on'
%        return;
%end;
currentPointInSgram = get(myGUIdata.sgramAxis,'currentpoint'); % (1,1): x, (1,2): y
xLimSgram = get(myGUIdata.sgramAxis,'xlim');
yLimSgram = get(myGUIdata.sgramAxis,'ylim');
switch myGUIdata.pointerMode
    case 'normal'
        set(myGUIdata.cursorFringeHandle,'visible','off');
        scrubbKnobPosition = mean(get(myGUIdata.cursorHandle,'xdata'));
        if (xLimSgram(1)-currentPointInSgram(1,1))*(xLimSgram(2)-currentPointInSgram(1,1)) < 0 && ...
                (yLimSgram(1)-currentPointInSgram(1,2))*(yLimSgram(2)-currentPointInSgram(1,2)) < 0
            % inside sgram
            proximityWidth = abs(diff(xLimSgram))*0.01;
            if abs(currentPointInSgram(1,1)-scrubbKnobPosition)<proximityWidth
                set(gcf,'pointer','hand');
            else
                set(gcf,'pointer','arrow');
            end;
        else
            set(gcf,'pointer','arrow');
        end;
    case 'dragging'
        switch myGUIdata.initializeScrubbing
            case 0
                nextPosition = max(xLimSgram(1),min(xLimSgram(2),currentPointInSgram(1,1)));
            case 1
                %nextPosition = mean(xLimSgram);
                nextPosition = mean(get(myGUIdata.cursorHandle,'xdata'));
                myGUIdata.initializeScrubbing = 0;
                guidata(src,myGUIdata)
        end;
        set(myGUIdata.cursorHandle,'visible','on');
        set(myGUIdata.cursorFringeHandle,'visible','on');
        set(myGUIdata.cursorHandle,'xdata',[0 0]+nextPosition);
        set(myGUIdata.cursotPositionText,'string',['Cursor: ' num2str(nextPosition,'%2.3f') ' s']);
        myGUIdata.smallviewerWidth = get(myGUIdata.radiobutton10ms,'value')*10+ ...
            get(myGUIdata.radiobutton30ms,'value')*30+ ...
            get(myGUIdata.radiobutton100ms,'value')*100+ ...
            get(myGUIdata.radiobutton300ms,'value')*300;
        set(myGUIdata.cursorFringeHandle,'xdata',[-0.5 -0.5 0.5 0.5]*myGUIdata.smallviewerWidth/1000+nextPosition);
        yLimStretch = yLimSgram*1.1-0.05*mean(yLimSgram);
        set(myGUIdata.cursorFringeHandle,'ydata',[yLimStretch(1) yLimStretch(2) yLimStretch(2) yLimStretch(1)]);
        numberOfSamples = round(myGUIdata.smallviewerWidth*myGUIdata.samplingFrequency/1000);
        x = myGUIdata.audioData;
        fs = myGUIdata.samplingFrequency;
        visibleIndex = max(1,min(length(x),round(nextPosition*fs+(1:numberOfSamples)'-numberOfSamples/2)));
        ydata = x(visibleIndex);
        yMax = max(abs(ydata));
        xdata = 1:numberOfSamples;
        %ydata = tmpAudio(currentPoint-numberOfSamples+1:currentPoint);
        set(myGUIdata.smallViewerPlotHandle,'xdata',xdata,'ydata',ydata);
        set(myGUIdata.smallViewerAxis,'xlim',[0 numberOfSamples],'ylim',yMax*[-1 1]);
        set(myGUIdata.cursorFringeHandle,'userdata',visibleIndex);
        fftl = 2^ceil(log2(numberOfSamples));
        fAxis = (0:fftl-1)/fftl*fs;
        switch get(myGUIdata.windowTypePopup,'value')
            case 1
                w = blackman(numberOfSamples);
            case 2
                w = hamming(numberOfSamples);
            case 3
                w = hanning(numberOfSamples);
            case 4
                w = bartlett(numberOfSamples);
            case 5
                w = ones(numberOfSamples,1);
            case 6
                w = nuttallwin(numberOfSamples);
            otherwise
                w = blackman(numberOfSamples);
        end;
        windowView = w*yMax*2-yMax;
        set(myGUIdata.windowViewHandle,'xdata',xdata,'ydata',windowView);
        pw = 20*log10(abs(fft(ydata.*w,fftl)/sqrt(sum(w.^2))));
        set(myGUIdata.largeViewerPlotHandle,'xdata',fAxis,'ydata',pw);
        switch get(myGUIdata.axisTypePopup,'value')
            case 1
                set(myGUIdata.largeViewerAxis,'xlim',[10 fs/2],'xscale','log');
            case 2
                set(myGUIdata.largeViewerAxis,'xlim',[0 fs/2],'xscale','linear');
            case 3
                set(myGUIdata.largeViewerAxis,'xlim',[0 10000],'xscale','linear');
            case 4
                set(myGUIdata.largeViewerAxis,'xlim',[0 8000],'xscale','linear');
            case 5
                set(myGUIdata.largeViewerAxis,'xlim',[0 4000],'xscale','linear');
            otherwise
                set(myGUIdata.largeViewerAxis,'xlim',[10 fs/2],'xscale','log');
        end;
end;
end

function windowButtonUpFcnForManipulation(src,evnt)
myGUIdata = guidata(src);
myGUIdata.pointerMode = 'normal';
set(myGUIdata.cursotPositionText,'visible','off');
set(myGUIdata.cursorFringeHandle,'visible','off');
guidata(src,myGUIdata);
end

function sgramCursorButtonDownFCN(src,evnt)
multiScopeMainGUI = get(src,'userData');
myGUIdata = guidata(multiScopeMainGUI);
%disp('cursor was hit!')
myGUIdata.pointerMode = 'dragging';
set(myGUIdata.cursotPositionText,'visible','on');
set(myGUIdata.cursorFringeHandle,'visible','on');
guidata(multiScopeMainGUI,myGUIdata);
end

function sgramCursorButtonMotionFCN(src,evnt)
end


% --- Executes on button press in loadButton.
function loadButton_Callback(hObject, eventdata, handles)
% hObject    handle to loadButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
myGUIdata = guidata(handles.multiScopeMainGUI);
set(myGUIdata.cursorFringeHandle,'visible','off')
set(myGUIdata.cursorHandle,'visible','off');
set(myGUIdata.zoomInTool,'enable','on');
set(myGUIdata.zoomOutTool,'enable','on');
set(myGUIdata.PanTool,'enable','on');
set(myGUIdata.dataCursorTool,'enable','on');
[file,path] = uigetfile('*.wav','Select sound file');
if length(file) == 1 && length(path) == 1
    if file == 0 || path == 0
        disp('Load is cancelled!');
        return;
    end;
end;
[x,fs] = audioread([path file]);
myGUIdata.audioData = x(:,1);
numberOfChannels = size(x,2);
set(myGUIdata.channelPopupMenu,'visible','on');
set(myGUIdata.channelPopupMenu,'string',myGUIdata.channelMenuString(1:min(8,numberOfChannels)));
myGUIdata.loadedData = x;
myGUIdata.samplingFrequency = fs;
set(handles.multiScopeMainGUI,'pointer','watch');drawnow
sgramStructure = stftSpectrogramStructure(myGUIdata.audioData,myGUIdata.samplingFrequency,15,2,'blackman');
set(myGUIdata.spectrogramHandle,'cdata',max(-80,sgramStructure.dBspectrogram),'visible','on', ...
    'xdata',sgramStructure.temporalPositions,'ydata',sgramStructure.frequencyAxis);
set(myGUIdata.sgramAxis,'visible','on', ...
    'xlim',[sgramStructure.temporalPositions(1) sgramStructure.temporalPositions(end)], ...
    'ylim',[sgramStructure.frequencyAxis(1) sgramStructure.frequencyAxis(end)]);
set(myGUIdata.wholeViewerAxis,'visible','off');
set(handles.multiScopeMainGUI,'pointer','arrow');drawnow
set(myGUIdata.playTFregion,'enable','on');
set(myGUIdata.scrubbingButton,'enable','on','value',0);
myGUIdata.liveData = 'no';
guidata(handles.multiScopeMainGUI,myGUIdata);
end


% --- Executes on selection change in channelPopupMenu.
function channelPopupMenu_Callback(hObject, eventdata, handles)
% hObject    handle to channelPopupMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns channelPopupMenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from channelPopupMenu
myGUIdata = guidata(handles.multiScopeMainGUI);
channelID = get(hObject,'Value');
myGUIdata.audioData = myGUIdata.loadedData(:,channelID);
set(handles.multiScopeMainGUI,'pointer','watch');drawnow
sgramStructure = stftSpectrogramStructure(myGUIdata.audioData,myGUIdata.samplingFrequency,15,2,'blackman');
set(myGUIdata.spectrogramHandle,'cdata',max(-80,sgramStructure.dBspectrogram),'visible','on', ...
    'xdata',sgramStructure.temporalPositions,'ydata',sgramStructure.frequencyAxis);
set(myGUIdata.sgramAxis,'visible','on', ...
    'xlim',[sgramStructure.temporalPositions(1) sgramStructure.temporalPositions(end)], ...
    'ylim',[sgramStructure.frequencyAxis(1) sgramStructure.frequencyAxis(end)]);
set(myGUIdata.wholeViewerAxis,'visible','off');
set(handles.multiScopeMainGUI,'pointer','arrow');drawnow
set(myGUIdata.playTFregion,'enable','on');
set(myGUIdata.scrubbingButton,'enable','on','value',0);
set(myGUIdata.cursorFringeHandle,'visible','off')
set(myGUIdata.cursorHandle,'visible','off');
set(myGUIdata.zoomInTool,'enable','on');
set(myGUIdata.zoomOutTool,'enable','on');
set(myGUIdata.PanTool,'enable','on');
set(myGUIdata.dataCursorTool,'enable','on');
myGUIdata.liveData = 'no';
guidata(handles.multiScopeMainGUI,myGUIdata);
end

% --- Executes during object creation, after setting all properties.
function channelPopupMenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to channelPopupMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

% --- Executes on button press in withAudioRadioButton.
function withAudioRadioButton_Callback(hObject, eventdata, handles)
% hObject    handle to withAudioRadioButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of withAudioRadioButton
end
