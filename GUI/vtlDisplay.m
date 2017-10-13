function varargout = vtlDisplay(varargin)
% VTLDISPLAY MATLAB code for vtlDisplay.fig
%      VTLDISPLAY, by itself, creates a new VTLDISPLAY or raises the existing
%      singleton*.
%
%      H = VTLDISPLAY returns the handle to a new VTLDISPLAY or the handle to
%      the existing singleton*.
%
%      VTLDISPLAY('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in VTLDISPLAY.M with the given input arguments.
%
%      VTLDISPLAY('Property','Value',...) creates a new VTLDISPLAY or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before vtlDisplay_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to vtlDisplay_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% This work is licensed under the Creative Commons 
% Attribution 4.0 International License.
% To view a copy of this license, visit
% http://creativecommons.org/licenses/by/4.0/.

% Release note
%   Realtime vocal tract log area function display
%   by Hideki Kawahara
%   17/Jan./2014 
%   26/Jan./2014 frame rate monirot
%   31/Aug./2015 machine independence and resizable GUI

% Edit the above text to modify the response to help vtlDisplay

% Last Modified by GUIDE v2.5 16-Jan-2014 23:57:35

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @vtlDisplay_OpeningFcn, ...
                   'gui_OutputFcn',  @vtlDisplay_OutputFcn, ...
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


% --- Executes just before vtlDisplay is made visible.
function vtlDisplay_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to vtlDisplay (see VARARGIN)

% Choose default command line output for vtlDisplay
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

delete(timerfindall);
initializeDisplay(handles);
myGUIdata = guidata(handles.vtVisualizeGUI);
timerEventInterval = 0.010; % in second
timer50ms = timer('TimerFcn',@synchDrawGUI, 'Period',timerEventInterval,'ExecutionMode','fixedRate', ...
    'userData',handles.vtVisualizeGUI);
%handleForTimer = handles.multiScopeMainGUI; % global
myGUIdata.timer50ms = timer50ms;
myGUIdata.smallviewerWidth = 30; % 30 ms is defaule
myGUIdata.recordObj1 = audiorecorder(myGUIdata.samplingFrequency,24,1);
set(myGUIdata.recordObj1,'TimerPeriod',0.2);
record(myGUIdata.recordObj1)
myGUIdata.maxAudioRecorderCount = 1000;
myGUIdata.maxLevel = -100;
myGUIdata.audioRecorderCount = myGUIdata.maxAudioRecorderCount;
myGUIdata.startTic = tic;
myGUIdata.lastTime = toc(myGUIdata.startTic);
%myGUIdata.displayTypeList = myGUIdata.displayTypeList(1:2);
guidata(handles.vtVisualizeGUI,myGUIdata);
startButton_Callback(hObject, eventdata, handles)

% UIWAIT makes vtlDisplay wait for user response (see UIRESUME)
% uiwait(handles.vtVisualizeGUI);
end

function initializeDisplay(handles)
myGUIdata = guidata(handles.vtVisualizeGUI);
myGUIdata.samplingFrequency = 8000; % in Hz
myGUIdata.windowLength = 0.08; % in second
myGUIdata.windowLengthInSamples = round(myGUIdata.windowLength*myGUIdata.samplingFrequency/2)*2+1;
myGUIdata.fftl = 2.0^ceil(log2(myGUIdata.windowLengthInSamples));
axes(handles.spectrumDisplayAxis);
w = blackman(myGUIdata.windowLengthInSamples);
w = w/sqrt(sum(w.^2));
myGUIdata.window = w;
fs = myGUIdata.samplingFrequency;
myGUIdata.displayFrequencyAxis = (0:myGUIdata.fftl-1)/myGUIdata.fftl*fs;
tt = (1:myGUIdata.windowLengthInSamples)'/fs;
%x = randn(myGUIdata.windowLengthInSamples,1);
x = sin(2*pi*440*tt);
pw = 10*log10(abs(fft(x.*w,myGUIdata.fftl)).^2/myGUIdata.fftl);
myGUIdata.spectrumPlotHandle = plot(myGUIdata.displayFrequencyAxis,pw);
hold on;
myGUIdata.spectrumLPCPlotHandle = plot(myGUIdata.displayFrequencyAxis,pw,'r', ...
    'linewidth',2);grid on;
%set(handles.spectrumDisplayAxis,'xlim',[0 fs/2]);
axis([0 fs/2 -110 0]);
set(gca,'fontsize',14,'linewidth',2);
xlabel('frequency (Hz)')
ylabel('level (dB rel. MSB)');
legend('power spectrum','14th order LPC');
set(handles.spectrumDisplayAxis,'HandleVisibility','off');
axes(handles.VTDisplayAxis);
logAreaFunction = [4 3.7 4 2.7 2.2 1.9 1.9 1.5 0.8 0];
locationList = [1 3 5 7 9 11 13 15 17 19];
displayLocationList = 0:0.1:21;
displayLogArea = interp1(locationList,logAreaFunction,displayLocationList,'nearest','extrap');
myGUIdata.logAreaHandle = plot(displayLocationList,displayLogArea-mean(displayLogArea),'linewidth',4);
hold on;
plot(displayLocationList,0*displayLogArea,'linewidth',1);
for ii = 0:20
    magCoeff = 1;
    if rem(ii,5) == 0
        magCoeff = 2;
        text(ii,-0.7,num2str(ii),'fontsize',16,'HorizontalAlignment','center');
    end;
    if rem(ii,10) == 0
        magCoeff = 3;
    end;
    plot([ii ii],[-0.1 0.1]*magCoeff);
end;
axis([-0.5 20.5 -5 5]);
axis off
set(handles.VTDisplayAxis,'HandleVisibility','off');
axes(handles.tract3DAxis);
crossSection =  [0.2803; ...
    0.6663; ...
    0.5118; ...
    0.3167; ...
    0.1759; ...
    0.1534; ...
    0.1565; ...
    0.1519; ...
    0.0878; ...
    0.0737];
[X,Y,Z] = cylinder(crossSection,40);
myGUIdata.tract3D = surf(Z,Y,X);
view(-26,12);
axis([0 1 -1 1 -1 1]);
axis off;
axis('vis3d');
rotate3d on;
guidata(handles.vtVisualizeGUI,myGUIdata);
end

function synchDrawGUI(obj, event, string_arg)
handleForTimer = get(obj,'userData');
myGUIdata = guidata(handleForTimer);
w = myGUIdata.window;
numberOfSamples = length(w);
if get(myGUIdata.recordObj1,'TotalSamples') > numberOfSamples
    tmpAudio = getaudiodata(myGUIdata.recordObj1);
    currentPoint = length(tmpAudio);
    x = tmpAudio(currentPoint-numberOfSamples+1:currentPoint);
    %x = [0;diff(x)];
    pw = abs(fft(x.*w,myGUIdata.fftl)).^2/myGUIdata.fftl;
    pwdB = 10*log10(pw);
    set(myGUIdata.spectrumPlotHandle,'ydata',pwdB);
    ac = real(ifft(pw));
    [alp,err,k] = levinson(ac,14);
    env = 1.0./abs(fft(alp,myGUIdata.fftl)).^2;
    env = sum(pw)*env/sum(env);
    envDB = 10*log10(env);
    set(myGUIdata.spectrumLPCPlotHandle,'ydata',envDB);
    logArea = signal2logArea(x);
    nSection = length(logArea);
    locationList = (1:nSection)*2-1;
    xdata = get(myGUIdata.logAreaHandle,'xdata');
    displayLogArea = interp1(locationList,logArea,xdata,'nearest','extrap');
    set(myGUIdata.logAreaHandle,'ydata',displayLogArea-mean(displayLogArea));
    [X,Y,Z] = cylinder(tubeDisplay(logArea),40);
    set(myGUIdata.tract3D,'xdata',Z,'ydata',Y,'zdata',X);
    if myGUIdata.audioRecorderCount < 0
        switch get(myGUIdata.timer50ms,'running')
            case 'on'
                stop(myGUIdata.timer50ms);
        end
        stop(myGUIdata.recordObj1);
        record(myGUIdata.recordObj1);
        myGUIdata.audioRecorderCount = myGUIdata.maxAudioRecorderCount;
        currentTime = toc(myGUIdata.startTic);
        framePerSecond = 1.0./(currentTime-myGUIdata.lastTime)*1000;
        set(myGUIdata.fpsDisplayText,'String',[num2str(framePerSecond,'%3.3f') ' fps']);
        myGUIdata.lastTime = currentTime;
        switch get(myGUIdata.timer50ms,'running')
            case 'off'
                start(myGUIdata.timer50ms);
        end
    else
        set(myGUIdata.countDownText,'String',num2str(myGUIdata.audioRecorderCount));
        myGUIdata.audioRecorderCount = myGUIdata.audioRecorderCount-1;
    end;
else
    %disp(['Recorded data is not enough! Skipping this interruption....at ' datestr(now,30)]);
    set(myGUIdata.countDownText,'String','Initilizing...');
end;
guidata(myGUIdata.vtVisualizeGUI,myGUIdata);
end

% --- Outputs from this function are returned to the command line.
function varargout = vtlDisplay_OutputFcn(hObject, eventdata, handles) 
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
myGUIdata = guidata(handles.vtVisualizeGUI);
myGUIdata.startTic = tic;
myGUIdata.lastTime = toc(myGUIdata.startTic);
set(myGUIdata.startButton,'enable','off');
set(myGUIdata.stopButton,'enable','on');
switch get(myGUIdata.timer50ms,'running')
    case 'on'
        stop(myGUIdata.timer50ms);
end
myGUIdata.audioRecorderCount = myGUIdata.maxAudioRecorderCount;
myGUIdata.lastPosition = 1;
record(myGUIdata.recordObj1);
switch get(myGUIdata.timer50ms,'running')
    case 'off'
        start(myGUIdata.timer50ms);
    case 'on'
    otherwise
        disp('timer is bloken!');
end
guidata(handles.vtVisualizeGUI,myGUIdata);
end

% --- Executes on button press in stopButton.
function stopButton_Callback(hObject, eventdata, handles)
% hObject    handle to stopButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
myGUIdata = guidata(handles.vtVisualizeGUI);
myGUIdata.audioData = getaudiodata(myGUIdata.recordObj1);
currentTime = toc(myGUIdata.startTic);
framePerSecond = 1.0./(currentTime-myGUIdata.lastTime)*(1000-myGUIdata.audioRecorderCount);
set(myGUIdata.fpsDisplayText,'String',[num2str(framePerSecond,'%3.3f') ' fps']);
%disp('timer ends')
%set(myGUIdata.startButton,'enable','off');
set(myGUIdata.startButton,'enable','on');
set(myGUIdata.stopButton,'enable','off');
switch get(myGUIdata.timer50ms,'running')
    case 'on'
        stop(myGUIdata.timer50ms)
    case 'off'
    otherwise
        disp('timer is bloken!');
end;
stop(myGUIdata.recordObj1);
guidata(handles.vtVisualizeGUI,myGUIdata);
end

% --- Executes on button press in quitButton.
function quitButton_Callback(hObject, eventdata, handles)
% hObject    handle to quitButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
myGUIdata = guidata(handles.vtVisualizeGUI);
%disp('timer ends')
switch get(myGUIdata.timer50ms,'running')
    case 'on'
        stop(myGUIdata.timer50ms)
end;
stop(myGUIdata.recordObj1);
delete(myGUIdata.timer50ms);
delete(myGUIdata.recordObj1);
close(handles.vtVisualizeGUI);
end
