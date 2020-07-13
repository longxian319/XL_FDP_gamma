%% for project 1, figure 1. 
%% load data
addpath(genpath([pwd,'/Toolbox_CSC']))         % Tool
addpath(genpath([pwd,'/ToolOthers/nanconv']))

dataFileName = 'ma027_032' ;
load([pwd,'/Data/UtahArrayData/',dataFileName],'LFPs','Fs')
fsTemporal = Fs ;
flagBandstop = 1 ;
[sigOri,~,badChannels] = preprocess_LFP(LFPs, flagBandstop) ;
surSig = generateSur(sigOri,0,badChannels) ;
% apply bandpass filtering for Gamma signals
subBand = [30,80] ;
bandpassSig = find_bandpassSig(surSig,subBand, fsTemporal,3,badChannels) ;
% Hilbert transform for analytic signals
hilbertSig = find_Hilbert(bandpassSig, fsTemporal,4) ;
% find amplitdue of the analytic Gamma as the input
sigIn = abs(squeeze((hilbertSig))) ;

%% Find Gamma burst in the time domain for fig.1
numChannels = size(sigIn,1)*size(sigIn,2) ;   % sigIn is the abs hilbertSig
sigReshape = reshape(sigIn,numChannels,[]) ;
stdVal = 2.5;
GammaBurstEvent = find_Burst_1D(sigReshape,fsTemporal,0,badChannels,...
    numChannels,stdVal) ;
%% select a row for visualization
selectCol = 5 ;         % 5 for the paper
selectBur = 16160 ;     % 16180 for the paper
selectRowTF = 4 ;       % 1 for the paper
numRow = size(sigIn,2) ;
sumRowBurst = sum(GammaBurstEvent.is_burst((selectCol-1)*numRow+1:selectCol...
    *numRow,:),1) ;
burstTimeIdx =  find(sumRowBurst>2) ;    % guarantee multiple bursts (optional)

if length(burstTimeIdx) < selectBur
    error('there is not that many bursts! Reduce selectBur.')
end
% back to sigOri
burstSelect = burstTimeIdx(selectBur)+fix(fsTemporal) + fix(0.2*fsTemporal) ;   

burstIdx = find(GammaBurstEvent.is_burst((selectCol-1)*numRow+1:...
    selectCol*numRow,burstTimeIdx(selectBur)) == 1) ;
if length(burstIdx) < selectRowTF
    error('there is not that many bursts! Reduce selectColTF.')
end
burstTFSelect = burstIdx(selectRowTF) ;
threhold = mean(sigIn(burstTFSelect,selectCol,:))+stdVal*...
    std(sigIn(burstTFSelect,selectCol,:)) ;
% burstIdxReshape = reshape(GammaBurstEvent.is_burst,numRow,numRow,[]) ;
% cordBurst = burstIdxReshape(burstTFSelect,selectCol,:) ;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% fig.1 in the paper is generated in this section
% fig.1(B) Broadband signals
halfWidth = fix(0.6*fsTemporal) ;
plotStart = burstSelect-0.5*halfWidth ;
plotEnd = burstSelect+1.5*halfWidth ;

% fig.1(C) Gamma bandpass signals
plotStartG = plotStart-fix(fsTemporal)+1 ;
plotEndG = plotEnd-fix(fsTemporal)+1 ;

% fig.1(E) Time-frequency analysis (wavelet)

tempData = squeeze (sigOri(burstTFSelect,selectCol,:)) ;
[wt2,f22,coi] = cwt(tempData,fsTemporal,'VoicesPerOctave',30);
    for j = 1:length(coi)
        ind = find(f22<=coi(j));
        wt2(ind,j) = NaN;
    end
    wt2(f22<30 | f22>80,:) = [] ;
    f2 = f22 ;
    f2(f22<30 | f22>80,:) = [] ;
    
% close all
timeStartW = plotStart  ;
timeEndW = plotEnd   ;
timePlot = timeStartW: timeEndW  ; 
tempTimeAxis = linspace(plotStart,plotEnd,length(timePlot)) ;


%% for submission to PNAS
figure_width = 8.7; %cm  11.4 or 17.8 for two columns
figure_hight = 15; %cm
figure('NumberTitle','off','name', 'figure_size_control', 'units', 'centimeters', ...
    'color','w', 'position', [0, 0, figure_width, figure_hight], ...
    'PaperSize', [figure_width, figure_hight]); % this is the trick!

subplot(3,1,1)
count = 1 ;
for xChan = 5:8
    for yChan = selectCol
        plot(plotStart:plotEnd,squeeze(sigOri(xChan,yChan,plotStart:plotEnd)) - ...
            0.5*(count-1)*max(sigOri(:)),'linewidth',1)
        hold on
        legendName{count} = ['(',num2str(xChan),', ',num2str(yChan),')'] ;
        
        count = count + 1 ;
    end
end
xlim([plotStart,plotEnd])
axis off ; 

subplot(3,1,2)
count = 1 ;
for xChan = 5:8
    for yChan = selectCol
        plot(plotStart:plotEnd,squeeze(bandpassSig(1,xChan,yChan,plotStartG:plotEndG)) - ...
            0.5*(count-1)*max(bandpassSig(:)),'linewidth',1)
        hold on
        legendName{count} = ['(',num2str(xChan),', ',num2str(yChan),')'] ;
        
        count = count + 1 ;
    end
end
hold on
plot(plotStart:plotEnd,ones(plotEnd-plotStart+1,1)*threhold-...
    0.5*(count-2)*max(bandpassSig(:)))
xlim([plotStart,plotEnd])
axis off ; 

addpath(genpath([pwd,'/ToolOthers/uimage']))
subplot(3,1,3)
uimagesc(tempTimeAxis,flip(f2),((abs(wt2(end:-1:1,timeStartW:timeEndW)) )))
set(gca,'YDir','normal')
 ylabel('frequency (Hz)')
 % colormap(jet)
 % colorbar

% plot(1:10)
% text(2.5,2,{'The figure size should',' be 8.4 by 15 cm'})
set(gca,'FontSize', 8);  % 6 points for x-axis tickmark labels
xlabel('time (ms)', 'fontsize', 8 ); % this must be after the above line!

set(gcf, 'PaperPositionMode', 'auto'); % this is the trick!
print -depsc figure_size_control % this is the trick!! 
    
