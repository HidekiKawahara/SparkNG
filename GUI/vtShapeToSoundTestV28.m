function varargout = vtShapeToSoundTestV28(varargin)
% VTSHAPETOSOUNDTESTV28 MATLAB code for vtShapeToSoundTestV28.fig
%      VTSHAPETOSOUNDTESTV28, by itself, creates a new VTSHAPETOSOUNDTESTV28 or raises the existing
%      singleton*.
%
%      H = VTSHAPETOSOUNDTESTV28 returns the handle to a new VTSHAPETOSOUNDTESTV28 or the handle to
%      the existing singleton*.
%
%      VTSHAPETOSOUNDTESTV28('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in VTSHAPETOSOUNDTESTV28.M with the given input arguments.
%
%      VTSHAPETOSOUNDTESTV28('Property','Value',...) creates a new VTSHAPETOSOUNDTESTV28 or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before vtShapeToSoundTestV28_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to vtShapeToSoundTestV28_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES
%
%   Designed and coded by Hideki Kawahara.
%   http://www.wakayama-u.ac.jp/%7ekawahara/index_e.html
%   Originally prepared for the World Vioce Day 2015 at Showa,
%   18/April/2015.
%   28/July/2015 Introduction of L-F model
%   30/July/2015 Interaction senario is revised
%   01/Aug./2015 bug fix (GUI of L-F model)
%   23/Aug./2015 Adjustable GUI
%   06/Nov./2015 Out signal display
%   15/Nov./2015 Input spectrum display
%   16/Dec./2015 Interactive F0 manipulation

% Edit the above text to modify the response to help vtShapeToSoundTestV28

% Last Modified by GUIDE v2.5 22-Nov-2015 13:32:09

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @vtShapeToSoundTestV28_OpeningFcn, ...
    'gui_OutputFcn',  @vtShapeToSoundTestV28_OutputFcn, ...
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

% --- Executes just before vtShapeToSoundTestV28 is made visible.
function vtShapeToSoundTestV28_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to vtShapeToSoundTestV28 (see VARARGIN)

% Choose default command line output for vtShapeToSoundTestV28
handles.output = hObject;
handles.LFDesigner = [];
handles.mfilename = mfilename;

% setup recorder object
handles.audioRecorder = audiorecorder(44100,16,1);
handles.maximumRecordCount = 200;
handles.audioRecordCount = handles.maximumRecordCount;
% Update handles structure
guidata(hObject, handles);
handles = initialize_display(handles);
syncVTL(handles.vtLength,handles);
handles.inputSegment = [];
handles.monitoredSound = [0;0];
handles.releaseToPlay = get(handles.releaseToPlayEnableRadioButton,'Value');

%hObject
%handles
% Final stage update handles structure
guidata(hObject, handles);
set(handles.audioRecorder,'TimerPeriod',0.1,'TimerFcn',{@spectrumMonitor,handles});
%handles
%handles
synchSource(handles);
%guidata(handles.vtTester,handles);

% UIWAIT makes vtShapeToSoundTestV28 wait for user response (see UIRESUME)
% uiwait(handles.vtTester);
end


% --- Outputs from this function are returned to the command line.
function varargout = vtShapeToSoundTestV28_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
end

% --- Executes on button press in SoundItButton.
function SoundItButton_Callback(hObject, eventdata, handles)
% hObject    handle to SoundItButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
soundItBody(handles);
end

% --- Executes on button press in QuitButton.
function QuitButton_Callback(hObject, eventdata, handles)
% hObject    handle to QuitButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
stop(handles.timer);
delete(timerfindall);
if ~isempty(handles.LFDesigner)
    if ishghandle(handles.LFDesigner)
        close(handles.LFDesigner);
    end;
end;
close(handles.vtTester);
end

function updatedHandles = initialize_display(handles)
updatedHandles = handles;
updatedHandles.samplingFrequency = 44100;
updatedHandles.vtLengthNorimal = 17; % 17 cm
updatedHandles.soundSpeed = 35000; % 35000 cm/s at 31 degree centigrade (ref. Story 1996)
updatedHandles.nSection = ...
    ceil(updatedHandles.vtLengthNorimal*2/updatedHandles.soundSpeed*updatedHandles.samplingFrequency);
updatedHandles.logArea = zeros(updatedHandles.nSection+1,1);
updatedHandles.vtLengthReference = updatedHandles.nSection/2*updatedHandles.soundSpeed/updatedHandles.samplingFrequency;
updatedHandles.vtLength = updatedHandles.vtLengthReference;
updatedHandles.F0 = 125;

fs = updatedHandles.samplingFrequency;
c = updatedHandles.soundSpeed;
%l = updatedHandles.vtLength;
%----- vocal tract drawing pad
axes(handles.VTDrawer)
maxArea = log(2^8);
bottomLvl = log(2^(-1));
updatedHandles.defaultMaxArea = maxArea;
updatedHandles.defaultBottomLvl = bottomLvl;
updatedHandles.areaFrame = plot([0 18 18 0 0],[bottomLvl bottomLvl maxArea maxArea bottomLvl],'b');
updatedHandles.areaFrameDefaultYdata = [bottomLvl bottomLvl maxArea maxArea bottomLvl];
hold on
updatedHandles.vtlHandle = plot([8 8],[bottomLvl-5 maxArea+5],'c','linewidth',3);
updatedHandles.vtlHandleOriginalXdata = get(updatedHandles.vtlHandle,'xdata');
xGridHandleList = zeros(35,1);
for ii = 1:35
    xGridHandleList (ii) = plot([ii ii],[bottomLvl-5 maxArea+5],'b:');
end;
updatedHandles.vtDrawerXGridHandleList = xGridHandleList;
for ii = -5:12
    plot([0 35],[1 1]*log(2^ii),'b:');
end;
updatedHandles.logAreaPlotHandle = ...
    plot(((0:updatedHandles.nSection)+0.5)*c/fs/2,updatedHandles.logArea,'b-o','linewidth',3);
updatedHandles.traceBuffer = zeros(1000,2)+NaN;
updatedHandles.pointCount = 1;
updatedHandles.traceHandle = plot(updatedHandles.traceBuffer(:,1), ...
    updatedHandles.traceBuffer(:,2),'g-','linewidth',2);
updatedHandles.modifierIndicatorHandle = ...
    plot((0:updatedHandles.nSection)*c/fs/2,updatedHandles.logArea*0+log(16),'color',[0 0.8 0]);
updatedHandles.logAreaDeviation = updatedHandles.logArea;

set(gca,'fontsize',14);
set(gca,'ytick',log(2.0.^(-3:12)),'ytickLabel',{'0.125';'0.25';'0.5';'1';'2';'4'; ...
    '8';'16';'32';'64';'128';'256';'512';'1024';'2048';'4096'});
set(gca,'xtick',5:5:35,'xtickLabel',{'5';'10';'15';'20';'25';'30';'35'});
updatedHandles.vtDrawerXtick = get(gca,'xtick');
updatedHandles.vtDrawerXtickLabel = get(gca,'xtickLabel');
axis([0 18 bottomLvl maxArea]);
xlabel('distance from lip (cm)');
ylabel('relative area');
%------- vocal tract shape modifier
axes(handles.modifierAxis);
xData = (0:updatedHandles.nSection)'*c/fs/2;
xBase = xData/xData(end-1)*pi;
yData = zeros(length(xData),7);
for ii = 1:3
    yData(:,ii*2-1) = sin(ii*xBase);
    yData(:,ii*2) = cos(ii*xBase);
end;
yData(:,7) = cos(0*xBase);
updatedHandles.modifierComponentHandle = plot(xData+c/fs/2*0.5,yData,'linewidth',2);
updatedHandles.modifierBasis = yData;
hold on
modifierHandleList = [1/2 0 1/4 1 1/6 2/3 3/4]*xData(end-1);
compositeModifierShape = sum(yData,2);
if max(abs(compositeModifierShape))>1
    modifierScalerValue = max(abs(compositeModifierShape));
    compositeModifierShapeViewer = compositeModifierShape/modifierScalerValue;
else
    modifierScalerValue = 1;
    compositeModifierShapeViewer = compositeModifierShape;
end;
updatedHandles.modifierHandleList = modifierHandleList;
updatedHandles.coefficientList = modifierHandleList*0+1;
updatedHandles.modifierScalerValue = modifierScalerValue;
updatedHandles.modifierHandle = plot(xData+c/fs/2*0.5,compositeModifierShapeViewer,'k','linewidth',4);
updatedHandles.modifierTraceBuffer = zeros(1000,2)+NaN;
updatedHandles.modifierCount = 1;
updatedHandles.modifierTraceBufferHandle = plot(xData++c/fs/2*0.5,compositeModifierShapeViewer+NaN,'g','linewidth',2);
%updatedHandles.modifierTraceBufferHandle
plot(xData,xData*0,'k');
releaseID = version('-release');
yearID = str2double(releaseID(1:4));
if yearID >= 2015 || strcmp(releaseID,'2014b')
    set(gca,'colororderindex',1);
end;
modifierAnchorHandles = zeros(7,1);
for ii = 1:7
    modifierAnchorHandles(ii) = plot(modifierHandleList(ii)++c/fs/2*0.5,1,'o','linewidth',2);
end;
updatedHandles.modifierAnchorHandles = modifierAnchorHandles;
minorGrid = 0:35;
modifierMinorGridList = zeros(length(minorGrid),1);
for ii = 1:length(minorGrid)
    modifierMinorGridList(ii) = plot(minorGrid(ii)*[1 1],[-1.2 1.2],'k:');
end;
updatedHandles.minorGrid = minorGrid;
updatedHandles.modifierMinorGridList = modifierMinorGridList;
majorGrid = 5:5:35;
modifierMajorGridList = zeros(length(majorGrid),1);
for ii = 1:length(majorGrid)
    modifierMajorGridList(ii) = plot(majorGrid(ii)*[1 1],[-1.2 1.2],'k-');
end;
updatedHandles.majorGrid = majorGrid;
updatedHandles.modifierMajorGridList = modifierMajorGridList;
axis([0 18 -1.2 1.2]);
axis('off');
%axis('off')
axes(handles.sliderAxis);
updatedHandles.sliderRail = plot([0 0],[-4 4],'b-','linewidth',5);
hold on;
updatedHandles.magnifierValue = 0;
updatedHandles.magnifierKnob = plot(0,0,'b+','linewidth',5,'markersize',18);
%updatedHandles.sliderAxis
axis('off');
%-------- vocal tract 3D display
axes(handles.VT3d)
crossSection = exp(updatedHandles.logArea);
crossSection = crossSection/max(crossSection);
[X,Y,Z] = cylinder(crossSection,40);
updatedHandles.tract3D = surf(Z,Y,X);
view(-8,12);
axis([0 1 [-1 1 -1 1]*1.5]);
axis off;
axis('vis3d');
vis3dUserData.initialCamereLocation = get(handles.VT3d,'cameraposition');
vis3dUserData.counter = 1;
set(handles.VT3d,'userdata',vis3dUserData);
%-------- vocal tract frequency domain display
[gaindB,fx] = handleToGain(updatedHandles);
axes(handles.gainPlot);
rootVector = [500 1200;1500 1400;2500 1300;3500 1200;4500 1500];
[ax,h1,h2] = plotyy(fx,gaindB,rootVector(:,1),-log10(rootVector(:,2)));%'linewidth',2,...
%,'linewidth',2);grid on;
updatedHandles.gainPlotHandle = h1;
updatedHandles.rootsPlotHandle = h2;
updatedHandles.gainRootAxis = ax;
maxGain = max(gaindB(fx<5000));
%axis([0 5000 maxGain+[-60 5]]);
set(ax(1),'xlim',[0 5000],'ylim',maxGain+[-80 5]);
set(ax(1),'fontsize',13,'ytick',-70:10:60,'xgrid','on','ygrid','on');
set(ax(1),'xtick',[1000:1000:10000],'xtickLabel',{'1';'2';'3';'4';'5';...
    '6';'7';'8';'9';'10'});
updatedHandles.gainRootAxisXtick = get(ax(1),'xtick');
updatedHandles.gainRootAxisXtickLabel = get(ax(1),'xtickLabel');
set(ax(2),'xlim',[0 5000],'ylim',-log10([1100 1]));
set(ax(2),'fontsize',13,'ytick',-log10([2000 1000 700 500 300 200 100 70 50 30 20 10 7 5 3 2 1]), ...
    'yticklabel',{'2000';'1000';' ';'500';' ';'200';'100';' ';'50';' ';'20';'10';' ';'5';' ';'2';'1'});
set(h1,'linewidth',2);
set(h2,'linestyle','none','marker','o','linewidth',2);
xlabel('frequency (kHz)');
ylabel('Gain (dB)');
axes(ax(1));
hold on;
maxDisplayHarmonics = round(10000/40/4)*4;
updatedHandles.harmonicAxis = reshape(cumsum(ones(maxDisplayHarmonics,2))',maxDisplayHarmonics*2,1);
updatedHandles.harmonicLines = reshape([-ones(maxDisplayHarmonics/2,1) ones(maxDisplayHarmonics/2,1) ...
    ones(maxDisplayHarmonics/2,1) -ones(maxDisplayHarmonics/2,1)]',maxDisplayHarmonics*2,1);
updatedHandles.harmonicsHandle = ...
    plot(updatedHandles.harmonicAxis*updatedHandles.F0,100*updatedHandles.harmonicLines,'c');
set(updatedHandles.harmonicsHandle,'zdata',updatedHandles.harmonicAxis*0-1);
h3 = plot(fx,gaindB*0,'r');
updatedHandles.outSpectrumHandle = h3;
h4 = plot(fx,gaindB*0+2,'color',[0 0.7 0]);
updatedHandles.totalEnvelopeHandle = h4;
h5 = plot(fx,gaindB*0+4,'k');
updatedHandles.inSpectrumHandle = h5;
axes(ax(2));
ylabel('bandwidth (Hz)');
hold on;
updatedHandles.poleMarker = plot(500,-log10(2000),'g+','markersize',23,'linewidth',5);
lsfList = 10000+(1:updatedHandles.nSection);
lsfMark = [-100*ones(1,length(lsfList));100*ones(1,length(lsfList))];
updatedHandles.lsfHandle = plot([lsfList;lsfList],lsfMark,'b--','linewidth',1);
%cameraLocation = get(handles.VT3d,'cameraposition');
%cameraLocation
%rotate3d(handles.VT3d);
%----- define pointer shape data for pen
updatedHandles = definePenPointerShape(updatedHandles);
updatedHandles = definePickerPointerShape(updatedHandles);
updatedHandles = defineLRPointerShape(updatedHandles);
%----- handlear assignement
set(handles.vtTester,'WindowButtonMotionFcn',@moveWhileMouseUp);
set(handles.vtTester,'windowbuttonDownFcn',@MousebuttonDown);
set(handles.frequencyValue,'visible','off');
set(handles.bandWidthValue,'visible','off');
set(handles.frequencyTitleText,'visible','off');
set(handles.bandWidthTitleText,'visible','off');
set(updatedHandles.outSpectrumHandle,'visible','off');
set(updatedHandles.totalEnvelopeHandle,'visible','off');
set(updatedHandles.inSpectrumHandle,'visible','off');
set(updatedHandles.harmonicsHandle,'visible','off');
set(handles.SoundMonitorPanel,'visible','off');
set(handles.stopMonitorButton,'visible','off');
set(handles.startMonitorButton,'visible','off');
set(handles.audioCounterText,'visible','off');
set(handles.playMonitorButton,'visible','off');
updatedHandles.timer = timer('period',0.1,'timerFcn',{@rotateCamera,handles},'executionmode','fixedrate');
%set(handles.vtTester,'userdata',updatedHandles);
start(updatedHandles.timer);
set(handles.SaveButton,'enable','off');
%----- source information preparation
updatedHandles.durationList = [0.25 0.5 1 2 4];
updatedHandles.duration = 1;
set(handles.durationPopup,'value',3);
updatedHandles.vibratoDepth = 50;
updatedHandles.vibratoFrequency = 5.5;
updatedHandles.variableF0 = 'off';
updatedHandles = defaultLFparameters(updatedHandles);
set(handles.voiceQualityPopup,'visible','on');
end

function updatedHandles = defaultLFparameters(updatedHandles)
updatedHandles.LFparametersBaseSet = ...
    [0.4134 0.5530 0.0041 0.5817; ...
    0.4808 0.5955 0.0269 0.7200; ...
    0.4621 0.6604 0.0270 0.7712];
updatedHandles.LFparameterNames = {'modal';'fry';'breathy'};
updatedHandles.currentVQName = char(updatedHandles.LFparameterNames{1});
LFparameters = struct;
LFparameters.tp = updatedHandles.LFparametersBaseSet(1,1);
LFparameters.te = updatedHandles.LFparametersBaseSet(1,2);
LFparameters.ta = updatedHandles.LFparametersBaseSet(1,3);
LFparameters.tc = updatedHandles.LFparametersBaseSet(1,4);
updatedHandles.LFparameters = LFparameters;
updatedHandles.LFDesigner = [];
%--- equalizer design
%cosineCoefficient = [0.355768 0.487396 0.144232 0.012604]; % Nuttall win12
%upperLimit = 50;
%halfSample = 50;
hc = [0.2624710164 0.4265335164 0.2250165621 0.0726831633 0.0125124215 0.0007833203];
updatedHandles.equalizerStr = equalizerDesignAAFX(hc, 68, 80, 1.5);
%updatedHandles.equalizerStr = equalizerDesignAAFX(cosineCoefficient,upperLimit,halfSample, 1.5);
end

function rotateCamera(src,evnt,handles)
cameraLocation = get(handles.VT3d,'cameraposition');
vis3dUserData = get(handles.VT3d,'userdata');
vis3dUserData.counter = vis3dUserData.counter+1;
deltaRotation = exp(1i*pi*0.03*sin(vis3dUserData.counter/50*2*pi));
xyComplex = vis3dUserData.initialCamereLocation(1)+1i*vis3dUserData.initialCamereLocation(2);
newCameraLocation = cameraLocation;
newCameraLocation(1) = real(xyComplex*deltaRotation);
newCameraLocation(2) = imag(xyComplex*deltaRotation);
set(handles.VT3d,'cameraposition',newCameraLocation);
set(handles.VT3d,'userdata',vis3dUserData);
%guidata(handles.vtTester,handles);
end

function MousebuttonDown(src,evnt)
handles = guidata(src);
pointerShape = get(handles.vtTester,'pointer');
%pointerShape
%switch pointerShape
%    case 'cross'
if isInsideAxis(handles.VTDrawer)
    %disp('hit m d')
    if strcmp(pointerShape,'hand')
        handles.initialLocation = get(handles.VTDrawer,'currentPoint');
        set(handles.vtTester,'WindowButtonMotionFcn',@moveVTLWhileMouseDown);
        set(handles.vtTester,'windowbuttonUpFcn',@penUpVTLFunction);
        set(handles.vtTester,'pointer','custom','pointerShapeCData',handles.pointerShapeCDataForLR, ...
            'pointerShapeHotSpot',handles.hotSpotForLR);
        set(handles.vtlHandle,'linewidth',5);
        guidata(src,handles);
    else
        handles.initialLocation = get(handles.VTDrawer,'currentPoint');
        handles.pointCount = 1;
        handles.traceBuffer = handles.traceBuffer+NaN;
        handles.traceBuffer(handles.pointCount,:) = handles.initialLocation(1,1:2);
        set(handles.vtTester,'WindowButtonMotionFcn',@moveWhileMouseDown);
        set(handles.vtTester,'windowbuttonUpFcn',@penUpFunction);
        set(handles.vtTester,'pointer','custom','pointerShapeCData',handles.pointerShapeCDataForPen, ...
            'pointerShapeHotSpot',handles.hotSpotForPen);
        guidata(src,handles);
    end;
    %    case 'hand'
elseif isInsideAxis(handles.gainRootAxis(2)) && strcmp(pointerShape,'hand')
    currentPoint = get(handles.gainRootAxis(2),'currentPoint');
    xLimit = get(handles.gainRootAxis(2),'xlim');
    yLimit = get(handles.gainRootAxis(2),'ylim');
    proxiIndStr = proximityCheck(handles,currentPoint,xLimit,yLimit);
    fs = handles.samplingFrequency;
    xData = get(handles.rootsPlotHandle,'xdata');
    yData = 10.0.^(-get(handles.rootsPlotHandle,'ydata'));
    r = exp(-yData/fs*pi).*exp(1i*xData/fs*2*pi);
    [minV,minIndex] = min(abs(r(proxiIndStr.minIndex)-conj(r)));
    handles.selectedPair = [proxiIndStr.minIndex minIndex];
    vtl = handles.vtLength;
    set(handles.frequencyValue,'string', ...
        num2str(xData(proxiIndStr.minIndex)/vtl*handles.vtLengthReference,'%6.1f'));
    set(handles.bandWidthValue,'string',...
        num2str(yData(proxiIndStr.minIndex)/vtl*handles.vtLengthReference,'%6.1f'));
    handles.lastFrequencyValue = xData(proxiIndStr.minIndex);
    handles.lastBandWidthValue = yData(proxiIndStr.minIndex);
    set(handles.poleMarker,'xdata',handles.lastFrequencyValue, ...
        'ydata',-log10(handles.lastBandWidthValue),'visible','on');
    handles.roots = r;
    set(handles.vtTester,'WindowButtonMotionFcn',@moveRootsWhileMouseDown);
    set(handles.vtTester,'windowbuttonUpFcn',@penUpForRootsFunction);
    %set(src,'Pointer','crosshair');
    set(handles.vtTester,'pointer','custom','pointerShapeCData',handles.pointerShapeCDataForPicker, ...
        'pointerShapeHotSpot',handles.hotSpotForPicker);
    set(handles.frequencyValue,'visible','on');
    set(handles.bandWidthValue,'visible','on');
    set(handles.frequencyTitleText,'visible','on');
    set(handles.bandWidthTitleText,'visible','on');
    guidata(src,handles);
elseif isInsideAxis(handles.sliderAxis) && strcmp(pointerShape,'hand')
    set(handles.magnifierKnob,'color',[0 0.8 0])
    set(handles.sliderRail,'color',[0 0.8 0])
    set(handles.vtTester,'WindowButtonMotionFcn',@moveSliderWhileMouseDown);
    set(handles.vtTester,'windowbuttonUpFcn',@penUpForSliderFunction);
elseif isInsideAxis(handles.modifierAxis) && strcmp(pointerShape,'hand')
    set(handles.modifierAnchorHandles(handles.selectedMarkerIndex),'linewidth',5)
    set(handles.modifierComponentHandle(handles.selectedMarkerIndex),'linewidth',5)
    set(handles.vtTester,'WindowButtonMotionFcn',@moveModifierComponentWhileMouseDown);
    set(handles.vtTester,'windowbuttonUpFcn',@penUpForModifierComponentFunction);
elseif isInsideAxis(handles.modifierAxis) && strcmp(pointerShape,'crosshair')
    set(handles.vtTester,'pointer','custom','pointerShapeCData',handles.pointerShapeCDataForPen, ...
        'pointerShapeHotSpot',handles.hotSpotForPen);
    set(handles.vtTester,'WindowButtonMotionFcn',@moveModifierPenWhileMouseDown);
    set(handles.vtTester,'windowbuttonUpFcn',@penUpForModifierPenFunction);
    currentPoint = get(handles.modifierAxis,'currentPoint');
    handles.modifierCount = 1;
    handles.modifierTraceBuffer(handles.modifierCount,:) = currentPoint(1,1:2);
    set(handles.modifierTraceBufferHandle,'xdata',handles.modifierTraceBuffer(1:handles.modifierCount,1), ...
        'ydata',handles.modifierTraceBuffer(1:handles.modifierCount,2));
    guidata(src,handles);
end
end

function moveVTLWhileMouseDown(src,evnt)
handles = guidata(src);
currentPoint = get(handles.VTDrawer,'currentPoint');
set(handles.vtlHandle,'xdata',currentPoint(1,1)*[1 1]);
vtl = 8/currentPoint(1,1)*handles.vtLengthReference;
if abs(vtl) < 8;vtl = 8;end;
if abs(vtl) > 35;vtl = 35;end;
syncVTL(vtl,handles);
handles.vtLength = vtl;
guidata(src,handles);
end

function penUpVTLFunction(src,evnt)
handles = guidata(src);
set(handles.vtTester,'WindowButtonMotionFcn',@moveWhileMouseUp);
set(handles.vtTester,'windowbuttonUpFcn','');
set(src,'Pointer','hand');
set(handles.vtlHandle,'linewidth',3);
set(handles.totalEnvelopeHandle,'linewidth',1);
guidata(src,handles);
if handles.releaseToPlay
    soundItBody(handles)
end;
end


function moveModifierPenWhileMouseDown(src,evnt)
handles = guidata(src);
currentPoint = get(handles.modifierAxis,'currentPoint');
handles.modifierCount = handles.modifierCount+1;
handles.modifierTraceBuffer(handles.modifierCount,:) = currentPoint(1,1:2);
set(handles.modifierTraceBufferHandle,'xdata',handles.modifierTraceBuffer(1:handles.modifierCount,1), ...
    'ydata',handles.modifierTraceBuffer(1:handles.modifierCount,2));
guidata(src,handles);
end

function penUpForModifierPenFunction(src,evnt)
handles = guidata(src);
set(handles.vtTester,'WindowButtonMotionFcn',@moveWhileMouseUp);
set(handles.vtTester,'windowbuttonUpFcn','');
xData = get(handles.modifierHandle,'xdata');
yData = get(handles.modifierHandle,'ydata');
[orderededPoints,sortIndex] = sort(handles.modifierTraceBuffer(1:handles.modifierCount,1));
orderedValue = handles.modifierTraceBuffer(sortIndex,2);
orderededPoints = orderededPoints(:)+cumsum(ones(handles.modifierCount,1))/10000;
indexList = 1:length(xData);
boundaryIndex = interp1(xData,indexList,[orderededPoints(1) orderededPoints(end)],'linear','extrap');
boundaryIndex(1) = max(1,ceil(boundaryIndex(1)));
boundaryIndex(2) = min(length(xData),floor(boundaryIndex(2)));
segmentValue = interp1(orderededPoints,orderedValue,xData(boundaryIndex(1):boundaryIndex(2)), ...
    'linear','extrap');
yData(boundaryIndex(1):boundaryIndex(2)) = segmentValue;
set(handles.modifierHandle,'ydata',yData);
handles.modifierTraceBuffer = handles.modifierTraceBuffer+NaN;
set(handles.modifierTraceBufferHandle,'xdata',handles.modifierTraceBuffer(1:handles.modifierCount,1), ...
    'ydata',handles.modifierTraceBuffer(1:handles.modifierCount,2));
set(src,'Pointer','crosshair');
set(handles.modifierIndicatorHandle,'ydata',yData*handles.magnifierValue+log(16));
handles.logArea = get(handles.logAreaPlotHandle,'ydata');
handles.logAreaDeviation = handles.logArea(:)-yData(:)*handles.magnifierValue;
handles.modifierCount = 1;
updatePlots(handles);
set(handles.SaveButton,'enable','off');
guidata(src,handles);
if handles.releaseToPlay
    soundItBody(handles)
end;
end

function penUpForModifierComponentFunction(src,evnt)
handles = guidata(src);
set(handles.modifierAnchorHandles(handles.selectedMarkerIndex),'linewidth',2)
set(handles.modifierComponentHandle(handles.selectedMarkerIndex),'linewidth',2)
set(handles.vtTester,'WindowButtonMotionFcn',@moveWhileMouseUp);
set(handles.vtTester,'windowbuttonUpFcn','');
set(handles.SaveButton,'enable','off');
guidata(src,handles);
set(handles.SaveButton,'enable','off');
if handles.releaseToPlay
    soundItBody(handles)
end;
end

function moveModifierComponentWhileMouseDown(src,evnt)
handles = guidata(src);
currentPoint = get(handles.modifierAxis,'currentPoint');
handles.coefficientList(handles.selectedMarkerIndex) = currentPoint(1,2);
set(handles.modifierAnchorHandles(handles.selectedMarkerIndex),'ydata',currentPoint(1,2));
set(handles.modifierComponentHandle(handles.selectedMarkerIndex),'ydata',...
    handles.modifierBasis(:,handles.selectedMarkerIndex)*currentPoint(1,2));
modifierValue = handles.modifierBasis*handles.coefficientList(:);
if max(abs(modifierValue)) > 1
    modifierValue = modifierValue/max(abs(modifierValue));
end;
set(handles.modifierHandle,'ydata',modifierValue);
set(handles.modifierIndicatorHandle,'ydata',modifierValue*handles.magnifierValue+log(16));
handles.logArea = handles.logAreaDeviation(:)+modifierValue(:)*handles.magnifierValue;
handles.logArea(end) = 0;
set(handles.logAreaPlotHandle,'ydata',handles.logArea);
updatePlots(handles)
guidata(src,handles);
end


function moveSliderWhileMouseDown(src,evnt)
handles = guidata(src);
currentPoint = get(handles.sliderAxis,'currentPoint');
set(handles.magnifierKnob,'ydata',max(-4,min(4,currentPoint(1,2))));
handles.magnifierValue = max(-4,min(4,currentPoint(1,2)));
ydata = get(handles.modifierHandle,'ydata');
set(handles.modifierIndicatorHandle,'ydata',ydata*handles.magnifierValue+log(16));
handles.logArea = handles.logAreaDeviation(:)+ydata(:)*handles.magnifierValue;
handles.logArea(end) = 0;
%set(handles.logAreaPlotHandle,'ydata',handles.logArea);
updatePlots(handles);
guidata(src,handles);
end

function penUpForSliderFunction(src,evnt)
handles = guidata(src);
set(handles.magnifierKnob,'color','b')
set(handles.sliderRail,'color','b')
set(handles.vtTester,'WindowButtonMotionFcn',@moveWhileMouseUp);
set(handles.vtTester,'windowbuttonUpFcn','');
guidata(src,handles);
set(handles.SaveButton,'enable','off');
if handles.releaseToPlay
    soundItBody(handles)
end;
end

function moveRootsWhileMouseDown(src,evnt)
handles = guidata(src);
currentPoint = get(handles.gainRootAxis(2),'currentPoint');
frequency = currentPoint(1,1);
bandWidth = 10.0.^(-currentPoint(1,2));
handles = updateParametersFromRoots(handles,frequency,bandWidth);
%----- log area plot
logAreaPlot(handles);
%------
crossSection = exp(handles.logArea);
crossSection = crossSection/max(crossSection);
[X,Y,Z] = cylinder(crossSection,40);
set(handles.tract3D,'xdata',Z,'ydata',Y,'zdata',X);
handles.lastFrequency = frequency;
handles.lastBandWidth = bandWidth;
guidata(src,handles);
end

function handles = updateParametersFromRoots(handles,frequency,bandWidth)
fs = handles.samplingFrequency;
currentR = exp(-bandWidth/fs*pi).*exp(1i*frequency/fs*2*pi);
vtl = handles.vtLength;
set(handles.frequencyValue,'string',num2str(frequency/vtl*handles.vtLengthReference,'%6.1f'));
set(handles.bandWidthValue,'string',num2str(bandWidth/vtl*handles.vtLengthReference,'%6.1f'));
rootVector = handles.roots; %size(rootVector)
rootVector(handles.selectedPair(1)) = currentR;
rootVector(handles.selectedPair(2)) = conj(currentR);
xData = get(handles.rootsPlotHandle,'xdata');
yData = get(handles.rootsPlotHandle,'ydata');
xData(handles.selectedPair(1)) = frequency;%currentPoint(1,1);
xData(handles.selectedPair(2)) = -frequency;%currentPoint(1,1);
yData(handles.selectedPair(1)) = -log10(bandWidth);%currentPoint(1,2);
yData(handles.selectedPair(2)) = -log10(bandWidth);%currentPoint(1,2);
set(handles.rootsPlotHandle,'xdata',xData);
set(handles.rootsPlotHandle,'ydata',yData);
set(handles.poleMarker,'xdata',frequency,'ydata',-log10(bandWidth),'visible','on');
predictorOrginal = poly(rootVector);
predictorTmp = real(predictorOrginal);
[gaindB,fx,logArea] = predictorToGain(handles,predictorTmp);
set(handles.gainPlotHandle,'ydata',gaindB,'xdata',fx); % Start modification: 10/Nov./2015
if ~isempty(handles.LFDesigner) && ishghandle(handles.LFDesigner)
    lfDesignerGUIdata = guidata(handles.LFDesigner);
    if isfield(handles,'F0')
        %disp('F0 exist')
        f0Base = handles.F0;
    else
        f0Base = 125;
    end
    modelFaxis = fx;%get(handles.gainPlotHandle,'xdata');
    modelVTgain = gaindB;%get(handles.gainPlotHandle,'ydata');
    if isfield(lfDesignerGUIdata,'LFmodelGenericSpectrum')
    sourceSpectrum = lfDesignerGUIdata.LFmodelGenericSpectrum;
    levelAtF0 = interp1(lfDesignerGUIdata.LFmodelGenericFaxis,sourceSpectrum,1);
    sourceGain = interp1(lfDesignerGUIdata.LFmodelGenericFaxis*f0Base,sourceSpectrum-levelAtF0,modelFaxis,'linear','extrap');
    set(handles.totalEnvelopeHandle,'visible','on',...
        'xdata',modelFaxis,'ydata',modelVTgain(:)+sourceGain(:));
    envelopeSpec = modelVTgain(:)+sourceGain(:);
    maxEnvelope = max(envelopeSpec(modelFaxis<5000));
    switch get(handles.inSpectrumHandle,'visible')
        case 'on'
    inputSpecData = get(handles.inSpectrumHandle,'ydata');
    inputSpecFAxis = get(handles.inSpectrumHandle,'xdata');
    maxInputSpec = max(inputSpecData(inputSpecFAxis<5000));
    set(handles.inSpectrumHandle,'ydata',inputSpecData-maxInputSpec+maxEnvelope);
    end;
    end;
end;% End of modification: 10/Nov./2015
maxGain = max(gaindB(fx<5000));
set(handles.gainPlot,'ylim',maxGain+[-70 5]);
handles.roots = rootVector;
handles.logArea = logArea(:);
yData = get(handles.modifierIndicatorHandle,'ydata');
handles.logAreaDeviation = handles.logArea-(yData(:)-log(16));
lsfVector = handleToLsf(handles);
for ii = 1:length(lsfVector<5000)
    set(handles.lsfHandle(ii),'xdata',[lsfVector(ii) lsfVector(ii)], ...
        'ydata',[-100 100]);
end;
end

function logAreaPlot(handles)
set(handles.logAreaPlotHandle,'ydata',handles.logArea);
areaFrameYdata = get(handles.areaFrame,'ydata');
if max(handles.logArea) > handles.defaultMaxArea
    areaFrameYdata(3:4) = max(handles.logArea);
else
    areaFrameYdata(3:4) = handles.defaultMaxArea;
end;
if min(handles.logArea) < handles.defaultBottomLvl
    areaFrameYdata([1 2 5]) = min(handles.logArea);
else
    areaFrameYdata([1 2 5]) = handles.defaultBottomLvl;
end;
set(handles.areaFrame,'ydata',areaFrameYdata);
set(handles.VTDrawer,'ylim',[areaFrameYdata(1) areaFrameYdata(3)]);
end

function [gaindB,fx,logArea] = predictorToGain(handles,predictorTmp)
fs = handles.samplingFrequency;
alp = predictorTmp;
fftl = 32768;
x = zeros(fftl,1);
x(1) = 1;
y = filter(1,alp,x);
gaindB = 20*log10(abs(fft(y)));
gaindB = gaindB-gaindB(1);
fx = (0:fftl-1)/fftl*fs;
k = zalp2k(alp);
logArea = log(zref2area(k));
end


function k = zalp2k(alp)

n = length(alp(2:end));
a = -alp(2:end);
b = a*0;
k = zeros(n,1);
for ii = n:-1:1
    k(ii) = a(ii);
    for jj = 1:ii-1
        b(jj) = (a(jj)+k(ii)*a(ii-jj))/(1-k(ii)*k(ii));
    end;
    a = b;
end;
end

function s = zref2area(k)

n = length(k);
s = zeros(n+1,1);
s(end) = 1;
for ii = n:-1:1
    s(ii) = s(ii+1)*(1-k(ii))/(1+k(ii));
end;
end

function penUpForRootsFunction(src,evnt)
handles = guidata(src);
set(handles.vtTester,'WindowButtonMotionFcn',@moveWhileMouseUp);
set(handles.vtTester,'windowbuttonDownFcn',@MousebuttonDown);
set(handles.vtTester,'windowbuttonUpFcn','');
set(src,'Pointer','hand');
%set(handles.frequencyValue,'visible','off');
%set(handles.bandWidthValue,'visible','off');
%set(handles.frequencyTitleText,'visible','off');
%set(handles.bandWidthTitleText,'visible','off');
guidata(src,handles);
set(handles.SaveButton,'enable','off');
if handles.releaseToPlay
    soundItBody(handles)
end;
end

function moveWhileMouseDown(src,evnt)
handles = guidata(src);
[nRow,nColumn] = size(handles.traceBuffer);
handles.pointCount = min(nRow,handles.pointCount+1);
currentPoint = get(handles.VTDrawer,'currentPoint');
handles.traceBuffer(handles.pointCount,:) = currentPoint(1,1:2);
set(handles.traceHandle,'xdata',handles.traceBuffer(:,1),'ydata',handles.traceBuffer(:,2));
guidata(src,handles);
end

function penUpFunction(src,evnt)
handles = guidata(src);
set(handles.vtTester,'WindowButtonMotionFcn',@moveWhileMouseUp);
set(handles.vtTester,'windowbuttonDownFcn',@MousebuttonDown);
set(handles.vtTester,'windowbuttonUpFcn','');
tmpAreaCoordinate = handles.traceBuffer(1:handles.pointCount,:);
handles.traceBuffer = handles.traceBuffer+NaN;
[sortedX,sortIndex] = sort(tmpAreaCoordinate(:,1));
sortedY = tmpAreaCoordinate(sortIndex,2);
finalIndex = 1;
trimmedAreaCoordinate = tmpAreaCoordinate*0;
trimmedAreaCoordinate(1,:) = [sortedX(1) sortedY(1)];
lastX = sortedX(1);
for ii = 2:handles.pointCount
    if lastX ~= sortedX(ii)
        finalIndex = finalIndex+1;
        trimmedAreaCoordinate(finalIndex,:) = [sortedX(ii) sortedY(ii)];
        lastX = sortedX(ii);
    end;
end;
trimmedAreaCoordinate = trimmedAreaCoordinate(1:finalIndex,:);
set(handles.traceHandle,'xdata',trimmedAreaCoordinate(:,1),'ydata',trimmedAreaCoordinate(:,2)+NaN);
minX = trimmedAreaCoordinate(1,1);
maxX = trimmedAreaCoordinate(end,1);
xData = get(handles.logAreaPlotHandle,'xdata');
if minX < xData(2)/2
    minX = -1;
end;
baseIndex = (1:length(xData))';
segmentedIndex = baseIndex(xData>minX & xData < maxX);
areaUpdator = interp1(trimmedAreaCoordinate(:,1),trimmedAreaCoordinate(:,2),xData(segmentedIndex), ...
    'linear','extrap');
handles.logArea(segmentedIndex) = areaUpdator(:);
handles.logArea(end) = 0;
set(src,'Pointer','cross');
yData = get(handles.modifierIndicatorHandle,'ydata');
handles.logAreaDeviation = handles.logArea(:)-(yData(:)-log(16));
guidata(src,handles);
set(handles.SaveButton,'enable','off');
updatePlots(handles);
if handles.releaseToPlay
    soundItBody(handles)
end;
end

function moveWhileMouseUp(src,evnt)
handles = guidata(src);
if isInsideAxis(handles.VTDrawer)
    currentPoint = get(handles.VTDrawer,'currentPoint');
    vtlHandleXdata = get(handles.vtlHandle,'xdata');
    if abs(currentPoint(1,1)-vtlHandleXdata(1))<0.2
        set(src,'Pointer','hand');
    else
        set(src,'Pointer','cross');
    end;
    set(handles.frequencyValue,'visible','off');
    set(handles.bandWidthValue,'visible','off');
    set(handles.frequencyTitleText,'visible','off');
    set(handles.bandWidthTitleText,'visible','off');
    set(handles.poleMarker,'visible','off');
else
    currentPoint = get(handles.gainRootAxis(2),'currentPoint');
    xLimit = get(handles.gainRootAxis(2),'xlim');
    yLimit = get(handles.gainRootAxis(2),'ylim');
    if isInsideAxis(handles.gainRootAxis(2))
        proxiIndStr = proximityCheck(handles,currentPoint,xLimit,yLimit);
        if proxiIndStr.proxiInd == 1
            set(src,'Pointer','hand');
        else
            set(src,'Pointer','circle');
        end;
    elseif isInsideAxis(handles.modifierAxis) || isInsideAxis(handles.sliderAxis)
        set(handles.frequencyValue,'visible','off');
        set(handles.bandWidthValue,'visible','off');
        set(handles.frequencyTitleText,'visible','off');
        set(handles.bandWidthTitleText,'visible','off');
        set(handles.poleMarker,'visible','off');
        if isCloseToSliderMarker(handles)
            set(src,'Pointer','hand');
        elseif isCloseToModifierMarker(handles)
            set(src,'Pointer','hand');
        else
            set(src,'Pointer','crosshair');
        end;
    else
        set(src,'Pointer','arrow');
    end;
end;
end

function isCloseInd = isCloseToModifierMarker(handles)
isCloseInd = false;
currentPoint = get(handles.modifierAxis,'currentPoint');
xLimit = get(handles.modifierAxis,'xlim');
%yLimit = get(handles.sliderAxis,'ylim');
distanceInModifier = zeros(length(handles.modifierAnchorHandles),1);
for ii = 1:length(handles.modifierAnchorHandles)
    xData = get(handles.modifierAnchorHandles(ii),'xdata');
    yData = get(handles.modifierAnchorHandles(ii),'ydata');
    distanceInModifier(ii) = sqrt(((currentPoint(1,1)-xData)/diff(xLimit)*6)^2+(currentPoint(1,2)-yData)^2);
end;
[minimumDistance,selectedIndex] = min(distanceInModifier);
if minimumDistance < 0.1
    isCloseInd = true;
    handles.selectedMarkerIndex = selectedIndex;
    guidata(handles.vtTester,handles)
end;
end

function isCloseInd = isCloseToSliderMarker(handles)
isCloseInd = false;
currentPoint = get(handles.sliderAxis,'currentPoint');
%xLimit = get(handles.sliderAxis,'xlim');
%yLimit = get(handles.sliderAxis,'ylim');
xData = get(handles.magnifierKnob,'xdata');
yData = get(handles.magnifierKnob,'ydata');
distanceInSlider = sqrt((currentPoint(1,1)-xData)^2+(currentPoint(1,2)-yData)^2);
if distanceInSlider < 0.2
    isCloseInd = true;
end;
end


function proxiIndStr = proximityCheck(handles,currentPoint,xLimit,yLimit)
proxiIndStr = struct;
proxiIndStr.proxiInd = 0;
xData = get(handles.rootsPlotHandle,'xdata');
yData = get(handles.rootsPlotHandle,'ydata');
distanceVector = sqrt(((xData-currentPoint(1,1))/diff(xLimit)*2).^2+ ...
    ((yData-currentPoint(1,2))/diff(yLimit)).^2);
[minDist,minIndex] = min(distanceVector);
if minDist<0.02
    proxiIndStr.proxiInd = 1;
    proxiIndStr.minIndex = minIndex;
end;
end

% --- Executes on button press in ResetButton.
function ResetButton_Callback(hObject, eventdata, handles)
% hObject    handle to ResetButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
nSection = length(handles.logArea);
handles.logArea = zeros(nSection,1);
handles.logArea(end) = 0;
ydata = get(handles.modifierIndicatorHandle,'ydata');
handles.logAreaDeviation(:) = handles.logArea(:)-ydata(:);
set(handles.totalEnvelopeHandle,'linewidth',1);
guidata(handles.vtTester, handles);
updatePlots(handles)
end

%---- private function
function updatePlots(handles)
%set(handles.logAreaPlotHandle,'ydata',handles.logArea);
logAreaPlot(handles);
yData = get(handles.modifierIndicatorHandle,'ydata');
handles.logAreaDeviation = handles.logArea(:)-(yData(:)-log(16));
crossSection = exp(handles.logArea);
crossSection = crossSection/max(crossSection);
[X,Y,Z] = cylinder(crossSection,40);
set(handles.tract3D,'xdata',Z,'ydata',Y,'zdata',X);
[gaindB,fx] = handleToGain(handles);
set(handles.gainPlotHandle,'ydata',gaindB,'xdata',fx);
maxGain = max(gaindB(fx<5000));
set(handles.gainPlot,'ylim',maxGain+[-80 5]);
rootVector = handleToRoots(handles);
set(handles.rootsPlotHandle,'xdata',rootVector(:,1), ...
    'ydata',-log10(rootVector(:,2)));
lsfVector = handleToLsf(handles);
for ii = 1:length(lsfVector<5000)
    set(handles.lsfHandle(ii),'xdata',[lsfVector(ii) lsfVector(ii)], ...
        'ydata',[-100 100]);
end;
if ~isempty(handles.LFDesigner) && ishghandle(handles.LFDesigner)
    lfDesignerGUIdata = guidata(handles.LFDesigner);
    if isfield(handles,'F0')
        %disp('F0 exist')
        f0Base = handles.F0;
    else
        f0Base = 125;
    end
    modelFaxis = get(handles.gainPlotHandle,'xdata')/handles.vtLength*handles.vtLengthReference;
    modelVTgain = get(handles.gainPlotHandle,'ydata');
    if isfield(lfDesignerGUIdata,'LFmodelGenericSpectrum')
    sourceSpectrum = lfDesignerGUIdata.LFmodelGenericSpectrum;
    levelAtF0 = interp1(lfDesignerGUIdata.LFmodelGenericFaxis,sourceSpectrum,1);
    sourceGain = interp1(lfDesignerGUIdata.LFmodelGenericFaxis*f0Base,sourceSpectrum-levelAtF0,...
        modelFaxis*handles.vtLengthReference/handles.vtLength,'linear','extrap');
    scaledVTgain = interp1(modelFaxis/handles.vtLengthReference*handles.vtLength,modelVTgain,modelFaxis,'linear','extrap');
    set(handles.totalEnvelopeHandle,'visible','on',...
        'xdata',modelFaxis,'ydata',scaledVTgain(:)+sourceGain(:));
    %ylim = get(handles.gainRootAxis(1),'ylim');
    envelopeSpec = get(handles.totalEnvelopeHandle,'ydata');
envelopeFaxis = get(handles.totalEnvelopeHandle,'xdata');
maxEnvelope = max(envelopeSpec(envelopeFaxis<5000));
    switch get(handles.inSpectrumHandle,'visible')
        case 'on'
    inputSpecData = get(handles.inSpectrumHandle,'ydata');
    inputSpecFAxis = get(handles.inSpectrumHandle,'xdata');
    maxInputSpec = max(inputSpecData(inputSpecFAxis<5000));
    set(handles.inSpectrumHandle,'ydata',inputSpecData-maxInputSpec+maxEnvelope);
    end;
    end;
end;
set(handles.harmonicsHandle,'xdata', ...
    handles.harmonicAxis*handles.F0*handles.vtLength/handles.vtLengthReference);
guidata(handles.vtTester, handles);
%axes(handles.VT3d)
%axis([0 1 [-1 1 -1 1]/max(crossSection)]);
%axes(handles.gainPlot);
end

function lsfVector = handleToLsf(handles)
fs = handles.samplingFrequency;
areaFunction = exp(handles.logArea);
ref = Zarea2ref(areaFunction);
alp = Zk2alp(ref);
lsfVector = poly2lsf(alp)/2/pi*fs;
end

function [gaindB,fx] = handleToGain(handles)
fs = handles.samplingFrequency;
areaFunction = exp(handles.logArea);
ref = Zarea2ref(areaFunction);
alp = Zk2alp(ref);
fftl = 8192*2;%32768; make this compatible with LF designer
x = zeros(fftl,1);
x(1) = 1;
y = filter(1,alp,x);
gaindB = 20*log10(abs(fft(y)));
gaindB = gaindB-gaindB(1);
fx = (0:fftl-1)/fftl*fs;
end

function rootVector = handleToRoots(handles)
fs = handles.samplingFrequency;
areaFunction = exp(handles.logArea);
ref = Zarea2ref(areaFunction);
alp = Zk2alp(ref);
r = roots(alp);
poleFrequencies = angle(r)/pi*fs/2;
poleBandWidths = -log(abs(r))/pi*fs;
rootVector = [poleFrequencies poleBandWidths];
end

function soundItBody(handles)
fs = handles.samplingFrequency;
areaFunction = exp(handles.logArea);
ref = Zarea2ref(areaFunction);
alp = Zk2alp(ref);
sourceSignalStr = generateSource(handles);
handles = sourceSignalStr.handles;
x = sourceSignalStr.signal;
y = filter(1,alp,x);
y = y/max(abs(y))*0.9;
if handles.vtLength == handles.vtLengthReference
    handles.player1 = audioplayer(y,fs);
    vtl = handles.vtLength;
else
    vtl = handles.vtLength;
    tx = (0:length(y)-1)'/fs;
    y = interp1(tx*vtl/handles.vtLengthReference,y,...
        (0:1/fs:tx(end)*vtl/handles.vtLengthReference)','linear','extrap');
    handles.player1 = audioplayer(y,fs);
end;
if isfield(handles,'F0')
    %disp('F0 exist')
    f0Base = handles.F0;
else
    f0Base = 125;
end
windowLengthInms = 60;
handles.windowShiftInms = 50;
windowType = 'nuttallwin12';
handles.sgramStr = stftSpectrogramStructure(y,fs,windowLengthInms,handles.windowShiftInms,windowType);
sgramFaxis = handles.sgramStr.frequencyAxis;
transferFunction = get(handles.gainPlotHandle,'ydata');
fAxis = get(handles.gainPlotHandle,'xdata');
f0Index = round(f0Base/fAxis(2)*vtl/handles.vtLengthReference);
handles.currentTransferFunction = transferFunction;
handles.fAxisForTrandferFunction = fAxis;
handles.outSignalScanIndex = round(f0Base/sgramFaxis(2)+(-4:4));
handles.levelAtF0 = transferFunction(f0Index);
set(handles.player1,'TimerFcn',{@outSpectrumDisplayFcn,handles},'TimerPeriod',0.10);
handles.playInterruptionCount = 0;
handles.maxInterruptionCount = floor(length(y)/fs/(handles.windowShiftInms/1000)-1);
guidata(handles.vtTester,handles);
stop(handles.timer);
playblocking(handles.player1);
set(handles.outSpectrumHandle,'visible','off');
start(handles.timer);
handles.synthesizedSound = y;
set(handles.SaveButton,'enable','on');
guidata(handles.vtTester,handles);
end

function outSpectrumDisplayFcn(src,evnt,handles)
handles = guidata(handles.vtTester);
handles.playInterruptionCount = handles.playInterruptionCount+1;
if handles.playInterruptionCount <= handles.maxInterruptionCount
    tmpSpectrumSlice = handles.sgramStr.dBspectrogram(:,handles.playInterruptionCount);
    tmplevelAtF0 = max(tmpSpectrumSlice(handles.outSignalScanIndex));
    tmpSpectrumSlice = tmpSpectrumSlice-tmplevelAtF0+handles.levelAtF0;
    set(handles.outSpectrumHandle,'visible','on', ...
        'ydata',tmpSpectrumSlice, ...
        'xdata',handles.sgramStr.frequencyAxis*handles.vtLength/handles.vtLengthReference);
%    sourceSpectrumSlice = handles.sourceSgram(:,handles.playInterruptionCount);
%    resampledSlice = interp1(handles.sourceFx(:,handles.playInterruptionCount),sourceSpectrumSlice, ...
%        handles.fAxisForTrandferFunction*handles.vtLength/handles.vtLengthReference,'linear','extrap');
%    resampledTransferFunctionSlice = interp1(handles.fAxisForTrandferFunction*handles,handles.currentTransferFunction, ...
%        handles.fAxisForTrandferFunction*handles.vtLength/handles.vtLengthReference,'linear','extrap');
%handles.sourceSgram = sourceSgram;
%handles.sourceFx = sourceFx;
%    set(handles.totalEnvelopeHandle,'visible','on','ydata',resampledTransferFunctionSlice(:)+resampledSlice(:), ...
%        'xdata',handles.fAxisForTrandferFunction*handles.vtLength/handles.vtLengthReference);
end;
guidata(handles.vtTester,handles);
end

function sourceSignalStr = generateSource(handles)
vtl = handles.vtLength;
fs = handles.samplingFrequency/vtl*handles.vtLengthReference;
duration = handles.duration;
tt = (0:1/fs:duration)';
pWidth = 0.003; % pulse width 3 ms

tHalf = tt(tt<pWidth);
pSingle = sin(pi*(tHalf/pWidth).^2);
if isfield(handles,'F0')
    %disp('F0 exist')
    f0Base = handles.F0;
else
    f0Base = 125;
end
vibratoDepth = handles.vibratoDepth; %0.25;
vibratoFrequency = handles.vibratoFrequency; %5.5;
switch handles.currentVQName
    case 'Design'
        if isempty(handles.LFDesigner)
            handles.LFDesigner = lfModelDesignerX(handles.vtTester);
            guidata(handles.vtTester,handles);
        end;
        if ~ishghandle(handles.LFDesigner)
            handles.LFDesigner = lfModelDesignerX(handles.vtTester);
            guidata(handles.vtTester,handles);
        end;
        lfDesignerGUIdata = guidata(handles.LFDesigner);
        LFparameters = lfDesignerGUIdata.LFparameters;
        
    otherwise
        LFparameters = handles.LFparameters;
end;
switch handles.variableF0
    case 'off'
        f0 = 2.0.^((log2(f0Base)*12+0.005*vibratoDepth*sin(2*pi*vibratoFrequency*tt))/12);
        outStr = AAFLFmodelFromF0Trajectory(f0,tt,fs,LFparameters.tp,LFparameters.te,LFparameters.ta,LFparameters.tc);
    case 'on'
        if isempty(handles.LFDesigner)
            handles.LFDesigner = lfModelDesignerX(handles.vtTester);
            guidata(handles.vtTester,handles);
        end;
        if ~ishghandle(handles.LFDesigner)
            handles.LFDesigner = lfModelDesignerX(handles.vtTester);
            guidata(handles.vtTester,handles);
        end;
        %vtShapeToSoundTestV24('SoundItButton_Callback',handles.parentUserData.SoundItButton,[], ...
        %    handles.parentUserData);
        lfModelHandles = guidata(handles.LFDesigner);
        lfModelDesignerX('generateSource_Callback',handles.vtTester,[],lfModelHandles);
        handles = guidata(handles.vtTester);
        outStr = handles.outStr;
        f0 = handles.generatedF0;
        tt = handles.generatedTime;
        f0Base = handles.f0Base;
end;
x = outStr.antiAliasedSignal;
sourceSignalStr.signal = fftfilt(handles.equalizerStr.minimumPhaseResponseW,x);
%sourceSignalStr.handles = handles;
%a = 1;
%if 1 == 2;
Tw = 2/(fs/2);
Tworg = Tw*f0Base;
timeAxis = ((round(-0.2*fs/f0Base):round(1.2*fs/f0Base))'/fs)/(1/f0Base);
fftlTmp = 8192*2;
fxTmp = (0:fftlTmp-1)'/fftlTmp*fs;
modelOut = sourceByLFmodelAAF(timeAxis,LFparameters.tp,LFparameters.te,LFparameters.ta,LFparameters.tc,Tworg);
%if 1 == 2
sgramTemporalPositions = 0:0.10:length(x)/fs;
f0Sgram = interp1(tt,f0,sgramTemporalPositions,'linear','extrap');
sourceSgram = zeros(fftlTmp/2+1,length(f0Sgram));
sourceFx = sourceSgram;
for ii = 1:length(sgramTemporalPositions)
    rawPw = 20*log10(abs(fft(modelOut.antiAliasedSource,fftlTmp)));
    iidx = round(f0Sgram(ii)/fxTmp(2))+1;
    rawPw = rawPw-rawPw(iidx);
    sourceSgram(:,ii) = rawPw(1:fftlTmp/2+1);
    sourceFx(:,ii) = fxTmp(1:fftlTmp/2+1)*f0Sgram(ii)/f0Base;
end;
handles.sourceSgram = sourceSgram;
handles.sourceFx = sourceFx;
if 1 == 2
vtSpectrumEnvelope = get(handles.gainPlotHandle,'ydata');
vtSpectrumEnvelope = vtSpectrumEnvelope(1:fftlTmp/2+1);
vtSpectrumEnvelope(sourceFx(:,1)<f0Sgram(1)) = NaN;
set(handles.totalEnvelopeHandle,'visible','on','ydata',vtSpectrumEnvelope(:)+sourceSgram(:,1), ...
    'xdata',sourceFx(:,1));
end;
sourceSignalStr.handles = handles;
%end;
if 1 == 2
    fundamentalComponent = sin(cumsum(2*pi*f0/fs));
    signOfFcomp = sign(fundamentalComponent);
    signOfFcompPre = signOfFcomp([1;(1:length(signOfFcomp)-1)']);
    eventLocation = tt(signOfFcomp > signOfFcompPre);
    %eventLocation = (0:1/f0:tt(end))';
    tmpIndex = (1:length(pSingle))';
    eventLocationIndex = round(eventLocation*fs);
    sourceSignal = tt*0;
    for ii = 1:length(eventLocationIndex)
        sourceSignal(max(1,min(length(sourceSignal),tmpIndex+eventLocationIndex(ii)))) = pSingle;
    end;
end;
end

%---- basic LPC functions
function k = Zarea2ref(s)
%   Area to reflection coefficients
%   s   : cross sectional area
%   k   : reflection coefficients

n = length(s)-1;
k = zeros(n,1);
for ii=1:n
    k(ii) = (s(ii+1)-s(ii))/(s(ii+1)+s(ii));
end;
end

function alp = Zk2alp(k)
%   Reflection coefficients to predictor
%   k   : reflection coefficient
%   alp : predictor

%   by Hideki Kawahara

n = length(k);
a = zeros(n,1);
b = zeros(n,1);
a(1) = k(1);
for ii=2:n
    for jj = 1:ii-1
        b(jj) = a(jj)-k(ii)*a(ii-jj);
    end;
    a = b;
    a(ii) = k(ii);
end;
alp = [1;-a];
end


% --- Executes on button press in releaseToPlayEnableRadioButton.
function releaseToPlayEnableRadioButton_Callback(hObject, eventdata, handles)
% hObject    handle to releaseToPlayEnableRadioButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of releaseToPlayEnableRadioButton
handles.releaseToPlay = get(hObject,'Value');
guidata(handles.vtTester, handles);
end


% --- Executes on button press in LoadButton.
function LoadButton_Callback(hObject, eventdata, handles)
% hObject    handle to LoadButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[file,path] = uigetfile({'*.mat';'*.txt'},'Select saved .mat file or compliant .txt file');
if length(file) == 1 && length(path) == 1
    if file == 0 || path == 0
        disp('Load is cancelled!');
        return;
    end;
end;
switch file(end-2:end)
    case 'mat'
        handles = loadSavedMatFile(handles,path,file);
    case 'txt'
        handles = loadCompliantTextFile(handles,path,file);
end;
syncVTL(handles.vtLength,handles)
set(handles.poleMarker,'visible','off');
set(handles.bandWidthValue,'visible','off');
set(handles.frequencyValue,'visible','off');
set(handles.bandWidthTitleText,'visible','off');
set(handles.frequencyTitleText,'visible','off');
guidata(handles.vtTester, handles);
updatePlots(handles)
end

function handles = loadCompliantTextFile(handles,path,file)
fid = fopen([path file]);
tline = fgetl(fid);
readItem = textscan(tline,'%s %s %s %f');
if strcmp('Number',readItem{1}) && strcmp('of',readItem{2})
    nSection = readItem{4};
else
    fclose(fid);disp('Number of section is missing.');return;
end;
tline = fgetl(fid);
readItem = textscan(tline,'%s %s %s %f');
if strcmp('Vocal',readItem{1}) && strcmp('tract',readItem{2})
    handles.vtLength = readItem{4};
    if abs(handles.vtLength-handles.vtLengthReference) < 0.01
        handles.vtLength = handles.vtLengthReference;
    end;
else
    fclose(fid);disp('Vocal tract length is missing.');return;
end;
tline = fgetl(fid);
readItem = textscan(tline,'%s %s %s %f');
if strcmp('List',readItem{1}) && strcmp('of',readItem{2})
    handles.vtLength = handles.vtLength; % do nothing
else
    fclose(fid);disp('Data prefix is missing.');return;
end;
xData = (0:nSection-1)'/(nSection-1)*handles.vtLength;
tmpArea = zeros(nSection,1);
for ii = 1:nSection
    tline = fgetl(fid);
    if ischar(tline)
        tmp = textscan(tline,'%f');
        tmpArea(ii) = tmp{1};
    else
        fclose(fid);disp('Data is missing.');return;
    end;
end;
%tmpArea
%handles.nSection;%
logArea = interp1(xData,log(tmpArea),(0:handles.nSection-1)'/(handles.nSection-1)*xData(end),'linear','extrap');
handles.logArea(1:handles.nSection) = logArea;
%handles.logArea
fclose(fid);
end

function handles = loadSavedMatFile(handles,path,file)
tmp = load([path file]);
xData = get(handles.logAreaPlotHandle,'xData');
if ~isfield(tmp,'outStructure')
    disp([path file ' does not consist of relevant data!']);return;
end;
if ~isfield(tmp.outStructure,'finalAreaFunction')
    disp([path file ' does not consist of relevant data!']);return;
end;
if tmp.outStructure.finalAreaFunction(end) ~= 1 || ...
        length(tmp.outStructure.finalAreaFunction) ~= length(xData)
    if length(tmp.outStructure.finalAreaFunction) ~= 46
        disp([path file ' does not consist of relevant data!']);return;
    else
        disp([path file ' is in old format. Updating']);
        deltaX = tmp.outStructure.finalLocationData(2)-tmp.outStructure.finalLocationData(1);
        vtLength = deltaX*(length(tmp.outStructure.finalAreaFunction)-1);
        recordedXdata = (0:44)/44*vtLength;
        tmpxData = (0:length(xData)-2)/(length(xData)-2)*vtLength;
        logArea = interp1(recordedXdata,log(tmp.outStructure.finalAreaFunction(1:end-1)), ...
            [tmpxData tmpxData(end)],'linear','extrap');
        logArea(end) = 0;
        handles.logArea = logArea;
    end;
else
    logArea = log(tmp.outStructure.finalAreaFunction);
    handles.logArea = log(tmp.outStructure.finalAreaFunction);
end;
set(handles.logAreaPlotHandle,'ydata',logArea);
if isfield(tmp.outStructure,'vtLength')
    vtl = tmp.outStructure.vtLength;
else
    vtl = handles.vtLengthReference;
end;
handles.vtLength = vtl;
end

% --- Executes on button press in SaveButton.
function SaveButton_Callback(hObject, eventdata, handles)
% hObject    handle to SaveButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
outFileNameRoot = ['vts' datestr(now,30)];
vtTestGUIStructure = guidata(handles.vtTester);
vtl = handles.vtLength;
outStructure = struct;
outStructure.vtLength = vtl;
outStructure.finalLocationData = get(handles.logAreaPlotHandle,'xdata')/handles.vtLengthReference*vtl;
outStructure.finalLogAreaData = get(handles.logAreaPlotHandle,'ydata');
outStructure.finalAreaFunction = exp(outStructure.finalLogAreaData);
outStructure.LFparameters = handles.LFparameters;
outStructure.synthesizedSound = vtTestGUIStructure.synthesizedSound;
outStructure.samplingFrequency = vtTestGUIStructure.samplingFrequency;
outStructure.lastUpdata = datestr(now);
switch get(handles.inSpectrumHandle,'visible')
    case 'on'
       outStructure.inputSegment = handles.inputSegment;
end;
[file,path] = uiputfile('*','Save status (.mat), area function (.txt) and sound at once.',outFileNameRoot);
if length(file) == 1 && length(path) == 1
    if file == 0 || path == 0
        disp('Save is cancelled!');
        return;
    end;
end;
x = outStructure.finalLocationData;
y = exp(outStructure.finalLogAreaData);
save([path [file '.mat']],'outStructure');
audiowrite([path [file '.wav']],handles.synthesizedSound,handles.samplingFrequency);
fid = fopen([path [file '.txt']],'w');
nSection = length(x)-1;
fprintf(fid,'Number of sections: %4d\n',nSection);
fprintf(fid,'Vocal tract length: %7.4f\n',vtl);
fprintf(fid,'List of relative area from lip to glottis\n');
for ii = 1:nSection
    %fprintf(fid,'%5.2f %8.2f\n',x(ii),y(ii));
    fprintf(fid,'%8.2f\n',y(ii));
end;
fclose(fid);
end

% --- Executes on button press in modifierResetPushbutton.
function modifierResetPushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to modifierResetPushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.magnifierKnob,'ydata',0);
handles.magnifierValue = 0;
handles.coefficientList = handles.coefficientList*0;
ydata = get(handles.modifierHandle,'ydata');
set(handles.modifierIndicatorHandle,'ydata',ydata*handles.magnifierValue+log(16));
yData = handles.modifierBasis*handles.coefficientList(:);
for ii = 1:length(handles.coefficientList)
    set(handles.modifierComponentHandle(ii),'ydata',handles.modifierBasis(:,ii)*handles.coefficientList(ii));
    set(handles.modifierAnchorHandles(ii),'ydata',handles.coefficientList(ii));
end;
set(handles.modifierHandle,'yData',yData);
handles.logAreaDeviation = handles.logArea;
updatePlots(handles)
guidata(handles.vtTester,handles);
end

function frequencyValue_Callback(hObject, eventdata, handles)
% hObject    handle to frequencyValue (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of frequencyValue as text
%        str2double(get(hObject,'String')) returns contents of frequencyValue as a double
frequencyString = get(handles.frequencyValue,'string');%currentPoint(1,1);
frequencyTmp = str2double(frequencyString);
frequency = frequencyTmp*handles.vtLength/handles.vtLengthReference;
if ~isnan(frequency)
    frequency = max(1,min(5000,frequency));
else
    frequency = handles.lastFrequency;
end
bandWidthString = get(handles.bandWidthValue,'string');%10.0.^(-currentPoint(1,2));
bandWidthTmp = str2double(bandWidthString);
bandWidth = bandWidthTmp*handles.vtLength/handles.vtLengthReference;
if ~isnan(bandWidth)
    bandWidth = max(2,min(1000,bandWidth));
else
    bandWidth = handles.lastBandWidth;
end
handles = updateParametersFromRoots(handles,frequency,bandWidth);
%----- log area plot
logAreaPlot(handles);
%------
crossSection = exp(handles.logArea);
crossSection = crossSection/max(crossSection);
[X,Y,Z] = cylinder(crossSection,40);
set(handles.tract3D,'xdata',Z,'ydata',Y,'zdata',X);
guidata(handles.vtTester,handles);
if handles.releaseToPlay
    soundItBody(handles)
end;
end

% --- Executes during object creation, after setting all properties.
function frequencyValue_CreateFcn(hObject, eventdata, handles)
% hObject    handle to frequencyValue (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


function bandWidthValue_Callback(hObject, eventdata, handles)
% hObject    handle to bandWidthValue (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of bandWidthValue as text
%        str2double(get(hObject,'String')) returns contents of bandWidthValue as a double
frequencyString = get(handles.frequencyValue,'string');%currentPoint(1,1);
frequencyTmp = str2double(frequencyString);
frequency = frequencyTmp*handles.vtLength/handles.vtLengthReference;
if ~isnan(frequency)
    frequency = max(1,min(5000,frequency));
else
    frequency = handles.lastFrequency;
end
bandWidthString = get(handles.bandWidthValue,'string');%10.0.^(-currentPoint(1,2));
bandWidthTmp = str2double(bandWidthString);
bandWidth = bandWidthTmp*handles.vtLength/handles.vtLengthReference;
if ~isnan(bandWidth)
    bandWidth = max(2,min(1000,bandWidth));
else
    bandWidth = handles.lastBandWidth;
end
handles = updateParametersFromRoots(handles,frequency,bandWidth);
%----- log area plot
logAreaPlot(handles);
%------
crossSection = exp(handles.logArea);
crossSection = crossSection/max(crossSection);
[X,Y,Z] = cylinder(crossSection,40);
set(handles.tract3D,'xdata',Z,'ydata',Y,'zdata',X);
guidata(handles.vtTester,handles);
if handles.releaseToPlay
    soundItBody(handles)
end;
end

% --- Executes during object creation, after setting all properties.
function bandWidthValue_CreateFcn(hObject, eventdata, handles)
% hObject    handle to bandWidthValue (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

%---- private function for defining pointer
function handles = defineLRPointerShape(handles)
tmp = imread('lrTool.png');
[nRow,nColumn] = size(tmp);
pointerShapeCData = double(tmp)+NaN;
for ii = 1:nColumn
    for jj = 1:nRow
        if tmp(jj,ii) > 200;pointerShapeCData(jj,ii) = 2;end;
        if tmp(jj,ii) < 100;pointerShapeCData(jj,ii) = 1;end;
    end;
end;
handles.pointerShapeCDataForLR = pointerShapeCData;
handles.hotSpotForLR = [7,nRow/2];
end

function handles = definePenPointerShape(handles)
tmp = imread('penTool.png');
tmpV = double(tmp>0);
[nRow,nColumn] = size(tmpV);
pointerShapeCData = tmpV+NaN;
for ii = 1:nColumn
    lowerIndex = min(find(tmpV(:,ii)==0));
    upperIndex = max(find(tmpV(:,ii)==0));
    for jj = max(1,lowerIndex-1):min(nRow,upperIndex+1)
        pointerShapeCData(jj,ii) = tmpV(jj,ii)+1;
    end;
end;
handles.pointerShapeCDataForPen = pointerShapeCData;
handles.hotSpotForPen = [nRow,1];
end

%---- private function for defining pointer
function handles = definePickerPointerShape(handles)
tmp = imread('pickTool.png');
[nRow,nColumn] = size(tmp);
pointerShapeCData = double(tmp)+NaN;
for ii = 1:nColumn
    for jj = 1:nRow
        if tmp(jj,ii) > 200;pointerShapeCData(jj,ii) = 2;end;
        if tmp(jj,ii) < 100;pointerShapeCData(jj,ii) = 1;end;
    end;
end;
handles.pointerShapeCDataForPicker = pointerShapeCData;
handles.hotSpotForPicker = [7,7];
end

function insideInd = isInsideAxis(axisHandle)
insideInd = false;
currentPoint = get(axisHandle,'currentPoint');
%currentPoint
xLimit = get(axisHandle,'xlim');
yLimit = get(axisHandle,'ylim');
if ((currentPoint(1,1)-xLimit(1))*(currentPoint(1,1)-xLimit(2)) < 0)  && ...
        ((currentPoint(1,2)-yLimit(1))*(currentPoint(1,2)-yLimit(2)) < 0)
    insideInd = true;
end;
end

% --- Executes on button press in shawallButton.
function shawallButton_Callback(hObject, eventdata, handles)
% hObject    handle to shawallButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.coefficientList = handles.coefficientList*0+1;
yData = handles.modifierBasis*handles.coefficientList(:);
for ii = 1:length(handles.coefficientList)
    set(handles.modifierComponentHandle(ii),'ydata',handles.modifierBasis(:,ii)*handles.coefficientList(ii));
    set(handles.modifierAnchorHandles(ii),'ydata',handles.coefficientList(ii));
end;
if max(abs(yData)) > 1;yData = yData/max(abs(yData));end;
set(handles.modifierHandle,'yData',yData);
ydata = get(handles.modifierHandle,'ydata');
set(handles.modifierIndicatorHandle,'ydata',ydata*handles.magnifierValue+log(16));
guidata(handles.vtTester,handles);
end


function vtlEdit_Callback(hObject, eventdata, handles)
% hObject    handle to vtlEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of vtlEdit as text
%        str2double(get(hObject,'String')) returns contents of vtlEdit as a double
vtl = str2double(get(hObject,'String'));
if ~isnan(vtl) && vtl > 10 && vtl < 35
    vtl = vtl;
else
    vtl = handles.vtLengthReference;
end;
handles.vtLength = vtl;
syncVTL(vtl,handles);
%handles
guidata(handles.vtTester,handles);
end

% --- Executes during object creation, after setting all properties.
function vtlEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to vtlEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

% --- Executes on button press in resetVTLbutton.
function resetVTLbutton_Callback(hObject, eventdata, handles)
% hObject    handle to resetVTLbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.vtLength = handles.vtLengthReference;
syncVTL(handles.vtLengthReference,handles);
set(handles.vtlHandle,'xdata',8*[1 1]);
set(handles.totalEnvelopeHandle,'linewidth',1);
guidata(handles.vtTester,handles);
if handles.releaseToPlay
    soundItBody(handles)
end;
end

%----- private function for VTL synchronization
function syncVTL(vtl,handles)
vtl = abs(vtl);
set(handles.vtlEdit,'string',num2str(vtl,'%4.2f'));
set(handles.vtlHandle,'xdata',8*handles.vtLengthReference/vtl*[1 1]);
set(handles.VTDrawer,'xtick',handles.vtDrawerXtick*handles.vtLengthReference/vtl);
set(handles.gainPlot,'xtick',[1000:1000:10000]*vtl/handles.vtLengthReference);
set(handles.gainRootAxis(2),'ytick',-log10(vtl/handles.vtLengthReference*[2000 1000 700 500 300 200 100 70 50 30 20 10 7 5 3 2 1]));
envelopeSpec = get(handles.totalEnvelopeHandle,'ydata');
envelopeFaxis = get(handles.totalEnvelopeHandle,'xdata');
maxEnvelope = max(envelopeSpec(envelopeFaxis<5000));
set(handles.harmonicsHandle,'xdata', ...
    handles.harmonicAxis*handles.F0*vtl/handles.vtLengthReference);
switch get(handles.inSpectrumHandle,'visible');
    case 'on'
        %ylim = get(handles.gainRootAxis(1),'ylim');
        set(handles.inSpectrumHandle,'xdata',handles.nominalFaxis/handles.vtLengthReference*vtl);
    inputSpecData = get(handles.inSpectrumHandle,'ydata');
    inputSpecFAxis = get(handles.inSpectrumHandle,'xdata');
    maxInputSpec = max(inputSpecData(inputSpecFAxis<5000));
    set(handles.inSpectrumHandle,'ydata',inputSpecData-maxInputSpec+maxEnvelope);
end;
for ii = 1:length(handles.vtDrawerXGridHandleList)
    set(handles.vtDrawerXGridHandleList(ii),'xdata',ii*handles.vtLengthReference/vtl*[1 1]);
end;
for ii = 1:length(handles.modifierMinorGridList)
    set(handles.modifierMinorGridList(ii),'xdata',handles.minorGrid(ii)*handles.vtLengthReference/vtl*[1 1]);
end;
for ii = 1:length(handles.modifierMajorGridList)
    set(handles.modifierMajorGridList(ii),'xdata',handles.majorGrid(ii)*handles.vtLengthReference/vtl*[1 1]);
end;
if ~isempty(handles.LFDesigner) && ishghandle(handles.LFDesigner)
    lfDesignerGUIdata = guidata(handles.LFDesigner);
    if isfield(handles,'F0')
        %disp('F0 exist')
        f0Base = handles.F0;
    else
        f0Base = 125;
    end
    modelFaxis = get(handles.gainPlotHandle,'xdata')*handles.vtLengthReference/vtl;
    modelVTgain = get(handles.gainPlotHandle,'ydata');
    if isfield(lfDesignerGUIdata,'LFmodelGenericSpectrum')
    sourceSpectrum = lfDesignerGUIdata.LFmodelGenericSpectrum;
    levelAtF0 = interp1(lfDesignerGUIdata.LFmodelGenericFaxis,sourceSpectrum,1);
    sourceGain = interp1(lfDesignerGUIdata.LFmodelGenericFaxis*f0Base,sourceSpectrum-levelAtF0,modelFaxis*handles.vtLengthReference/vtl,'linear','extrap');
    scaledVTgain = interp1(modelFaxis/handles.vtLengthReference*vtl,modelVTgain,modelFaxis,'linear','extrap');
    set(handles.totalEnvelopeHandle,'visible','on',...
        'xdata',modelFaxis,'ydata',scaledVTgain(:)+sourceGain(:),'linewidth',3);
    end;
end;
end

function F0Edit_Callback(hObject, eventdata, handles)
% hObject    handle to F0Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of F0Edit as text
%        str2double(get(hObject,'String')) returns contents of F0Edit as a double
tmpF0 = str2double(get(hObject,'String'));
if ~isnan(tmpF0)
    handles.F0 = max(55,min(880,tmpF0));
end;
guidata(handles.vtTester,handles);
synchSource(handles)
end

% --- Executes during object creation, after setting all properties.
function F0Edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to F0Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

% --- Executes on selection change in noteNamePopup.
function noteNamePopup_Callback(hObject, eventdata, handles)
% hObject    handle to noteNamePopup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns noteNamePopup contents as cell array
%        contents{get(hObject,'Value')} returns selected item from noteNamePopup
itemID = get(hObject,'Value');
switch itemID
    case 1
        handles.F0 = 125;
        handles = closeLFdesigner(handles,'on');
        handles.variableF0 = 'off';
    case 2
        handles.F0 = 250;
        handles = closeLFdesigner(handles,'on');
        handles.variableF0 = 'off';
    case 3
        handles = closeLFdesigner(handles,'off');
        handles.variableF0 = 'on';
        guidata(handles.vtTester,handles);
        if isempty(handles.LFDesigner)
            handles.LFDesigner = lfModelDesignerX(handles.vtTester);
        end;
        if ishghandle(handles.LFDesigner)
            lfDesignerGUIdata = guidata(handles.LFDesigner);
            handles.LFparameters = lfDesignerGUIdata.LFparameters;
            handles.currentVQName = 'Design';
            set(handles.voiceQualityPopup,'value',4);
            set(handles.harmonicsHandle,'visible','on');
            guidata(handles.vtTester,handles);
            if handles.releaseToPlay
                soundItBody(handles)
            end;
        else
            handles = defaultLFparameters(handles);
            guidata(handles.vtTester,handles);
        end;
    otherwise
        handles.F0 = 55*2.0.^((itemID-4)/12);
        handles = closeLFdesigner(handles,'on');
        handles.variableF0 = 'off';
end;
guidata(handles.vtTester,handles);
synchSource(handles)
end

function handles = closeLFdesigner(handles,variableF0State)
% variableF0State: on or off
if ~isempty(handles.LFDesigner) && strcmp(handles.variableF0,variableF0State)
    if ishghandle(handles.LFDesigner)
        lfDesignerUserData = guidata(handles.LFDesigner);
        %eval([fName '(instruction,handles.parentUserData.SoundItButton,[],handles.parentUserData);']);
        %quitButton_Callback(hObject, eventdata, handles)
        lfModelDesignerX('quitButton_Callback',lfDesignerUserData.quitButton,[],lfDesignerUserData);
        set(handles.harmonicsHandle,'visible','off');
        handles.LFDesigner = [];
    end;
end;
end

% --- Executes during object creation, after setting all properties.
function noteNamePopup_CreateFcn(hObject, eventdata, handles)
% hObject    handle to noteNamePopup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

function synchSource(handles)
set(handles.F0Edit,'string',num2str(handles.F0,'%5.1f'));
set(handles.vibratoRateEdit,'string',num2str(handles.vibratoFrequency,'%5.2f'));
set(handles.vibratoDepthEdit,'string',num2str(handles.vibratoDepth,'%5.0f'));
noteIndex = round(log2(handles.F0/55)*12+4);
if handles.F0 == 125 && ~(get(handles.noteNamePopup,'value') == 3)
    set(handles.noteNamePopup,'value',1);
elseif handles.F0 == 250 && ~(get(handles.noteNamePopup,'value') == 3)
    set(handles.noteNamePopup,'value',2);
elseif strcmp(handles.variableF0,'on')
    set(handles.noteNamePopup,'value',3);
else
    set(handles.noteNamePopup,'value',noteIndex);
end;
%guidata(handles.vtTester,handles);
updatePlots(handles);
if handles.releaseToPlay
    soundItBody(handles)
end;
end

% --- Executes on selection change in voiceQualityPopup.
function voiceQualityPopup_Callback(hObject, eventdata, handles)
% hObject    handle to voiceQualityPopup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns voiceQualityPopup contents as cell array
%        contents{get(hObject,'Value')} returns selected item from voiceQualityPopup
itemID = get(hObject,'Value');
LFparameters = handles.LFparameters;
switch itemID
    case {1,2,3}
        handles = closeLFdesigner(handles,'off');
        %if ~isempty(handles.LFDesigner)
        %    if ishghandle(handles.LFDesigner)
        %        close(handles.LFDesigner);
        %    end;
        %    handles.LFDesigner = [];
        %end;
        LFparameterVector = handles.LFparametersBaseSet(itemID,:);
        LFparameters.tp = LFparameterVector(1);
        LFparameters.te = LFparameterVector(2);
        LFparameters.ta = LFparameterVector(3);
        LFparameters.tc = LFparameterVector(4);
        handles.LFparameters = LFparameters;
        handles.currentVQName = char(handles.LFparameterNames{itemID});
        guidata(handles.vtTester,handles);
        if handles.releaseToPlay
            soundItBody(handles)
        end;
    case 4
        if isempty(handles.LFDesigner)
            handles.LFDesigner = lfModelDesignerX(handles.vtTester);
        end;
        if ishghandle(handles.LFDesigner)
            lfDesignerGUIdata = guidata(handles.LFDesigner);
            handles.LFparameters = lfDesignerGUIdata.LFparameters;
            handles.currentVQName = 'Design';
            set(handles.harmonicsHandle,'visible','on');
            guidata(handles.vtTester,handles);
            if handles.releaseToPlay
                soundItBody(handles)
            end;
        else
            handles = defaultLFparameters(handles);
            guidata(handles.vtTester,handles);
        end;
end;
updatePlots(handles);
end


% --- Executes during object creation, after setting all properties.
function voiceQualityPopup_CreateFcn(hObject, eventdata, handles)
% hObject    handle to voiceQualityPopup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


function vibratoRateEdit_Callback(hObject, eventdata, handles)
% hObject    handle to vibratoRateEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of vibratoRateEdit as text
%        str2double(get(hObject,'String')) returns contents of vibratoRateEdit as a double
tmpFrequency = str2double(get(hObject,'String'));
if ~isnan(tmpFrequency)
    handles.vibratoFrequency = tmpFrequency;
    guidata(handles.vtTester,handles);
    synchSource(handles);
end;
end

% --- Executes during object creation, after setting all properties.
function vibratoRateEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to vibratoRateEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

function vibratoDepthEdit_Callback(hObject, eventdata, handles)
% hObject    handle to vibratoDepthEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of vibratoDepthEdit as text
%        str2double(get(hObject,'String')) returns contents of vibratoDepthEdit as a double
tmpDepth = str2double(get(hObject,'String'));
if ~isnan(tmpDepth)
    handles.vibratoDepth = tmpDepth;
    guidata(handles.vtTester,handles);
    synchSource(handles);
end;
end

% --- Executes during object creation, after setting all properties.
function vibratoDepthEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to vibratoDepthEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

% --- Executes on selection change in durationPopup.
function durationPopup_Callback(hObject, eventdata, handles)
% hObject    handle to durationPopup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns durationPopup contents as cell array
%        contents{get(hObject,'Value')} returns selected item from durationPopup
itemID = get(hObject,'Value');
handles.duration = handles.durationList(itemID);
guidata(handles.vtTester,handles);
synchSource(handles)
end

% --- Executes during object creation, after setting all properties.
function durationPopup_CreateFcn(hObject, eventdata, handles)
% hObject    handle to durationPopup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

% --- Executes on button press in sourceResetButton.
function sourceResetButton_Callback(hObject, eventdata, handles)
% hObject    handle to sourceResetButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.F0 = 125;
handles.duration = 1;
set(handles.durationPopup,'value',3);
set(handles.noteNamePopup,'value',1);
handles.vibratoDepth = 50;
handles.vibratoFrequency = 5.5;
handles = closeLFdesigner(handles,'on');
handles = closeLFdesigner(handles,'off');
guidata(handles.vtTester,handles);
synchSource(handles)
end

% --- Executes on button press in startMonitorButton.
function startMonitorButton_Callback(hObject, eventdata, handles)
% hObject    handle to startMonitorButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.audioCounterText,'visible','on','string',num2str(handles.audioRecordCount));
handles.audioRecordCount = handles.maximumRecordCount;
record(handles.audioRecorder);
set(handles.stopMonitorButton,'enable','on');
set(handles.startMonitorButton,'enable','off');
set(handles.audioCounterText,'visible','on','string',num2str(handles.audioRecordCount));
guidata(handles.vtTester,handles);
end

% --- Executes on button press in stopMonitorButton.
function stopMonitorButton_Callback(hObject, eventdata, handles)
% hObject    handle to stopMonitorButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
stop(handles.audioRecorder);
set(handles.stopMonitorButton,'enable','off');
set(handles.startMonitorButton,'enable','on');
end

% --- Executes on button press in monitorRadioButton.
function monitorRadioButton_Callback(hObject, eventdata, handles)
% hObject    handle to monitorRadioButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of monitorRadioButton
switch get(hObject,'Value')
    case 1
        set(handles.SoundMonitorPanel,'visible','on');
        set(handles.stopMonitorButton,'visible','on');
        set(handles.stopMonitorButton,'enable','off');
        set(handles.startMonitorButton,'visible','on');
        set(handles.startMonitorButton,'enable','on');
        set(handles.inSpectrumHandle,'visible','on');
        set(handles.playMonitorButton,'visible','on');
        if length(handles.monitoredSound) < 100; set(handles.playMonitorButton,'enable','off');end;
    case 0
        stop(handles.audioRecorder);
        set(handles.SoundMonitorPanel,'visible','off');
        set(handles.stopMonitorButton,'visible','off');
        set(handles.startMonitorButton,'visible','off');
        set(handles.inSpectrumHandle,'visible','off');
        set(handles.audioCounterText,'visible','off');
        set(handles.playMonitorButton,'visible','on');
end;
guidata(handles.vtTester,handles);
end

function spectrumMonitor(src,evnt,handles)
handles = guidata(handles.vtTester);
handles.audioRecordCount = handles.audioRecordCount-1;
set(handles.audioCounterText,'string',num2str(handles.audioRecordCount));
%if 1 == 2
fftl = 8192;
fs = handles.samplingFrequency;
w = nuttallwin12(round(0.06*fs));
fx = (0:fftl-1)/fftl*fs/handles.vtLengthReference*handles.vtLength;% handles.vtLengthReference handles.vtLength
handles.nominalFaxis = (0:fftl-1)/fftl*fs;
ylim = get(handles.gainRootAxis(1),'ylim');
y = getaudiodata(handles.audioRecorder);
y = y(:);
if length(y)>length(w)
    power = 20*log10(abs(fft(w.*y(end-length(w):end-1),fftl)));
    maxPower = max(power(fx<5000));
    scaledPower = power-maxPower+ylim(2)-5;
    set(handles.inSpectrumHandle,'xdata',fx,'ydata',scaledPower);
    handles.inputSegment = y(end-length(w):end-1);
    handles.monitoredSound = y(end-min(length(y),round(0.2*fs))+1:end);
    set(handles.playMonitorButton,'enable','on');
end;
if handles.audioRecordCount < 0
    switch get(handles.timer,'running')
        case 'on'
            stop(handles.timer);
    end
    stop(handles.audioRecorder);
    handles.audioRecordCount = handles.maximumRecordCount;
    set(handles.playMonitorButton,'enable','off');
    record(handles.audioRecorder);
    switch get(handles.timer,'running')
        case 'off'
            start(handles.timer);
    end
end;
switch get(handles.monitorRadioButton,'value')
    case 'off'
        stop(handles.audioRecorder);
end;
%end;
guidata(handles.vtTester,handles);
end

% --- Executes on button press in playMonitorButton.
function playMonitorButton_Callback(hObject, eventdata, handles)
% hObject    handle to playMonitorButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
monitorSound = handles.monitoredSound;
handles.audioPlayer = audioplayer(monitorSound/max(abs(monitorSound))*0.99,handles.samplingFrequency);
playblocking(handles.audioPlayer);
end