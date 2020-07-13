function [surData] = GenerateSurData(dataIn, varargin)
% function [surData] = GenerateSurData(dataIn, varargin) generates
% surrogate data using randomised phase.
%
% input:
% dataIn           matrix with dimension Space*Space*Time or Space*Time ;
% optional input:
% 'optSur'         optional input, 1/2 for randomised/equal phase 
%                  randomization over space, default = 1; 
% 'seedName'       matlab random seeds
%
% output:
% surData          matrix with dimension Space*Space*Time
%
% author: Xian Long, supervisor: Pulin Gong
% date: 24/07/2019
% 

%% Default input settings
if ndims(dataIn) ~= 3
    if ndims(dataIn) == 2
        [nRows, nCols] = size(dataIn) ;
        if nRows == 1 || nCols == 1    % single channel
            dataIn = reshape(dataIn, 1,1,[]) ;
            disp('single time series!')
            varargin{1} = 1 ;
        else                           % space * time input
            dataIn = reshape(dataIn, 1,nRows,nCols) ;
        end
    else
        error('wrong input matrix dimension for GenerateSurData')
    end
end
    
% optional default inputs
nanChans = any(isnan(dataIn(:,:,:)),3);
zeroChans = all(dataIn(:,:,:)==0, 3);
badChannels = find(nanChans | zeroChans);
optSur = 1 ;
seedName = 'shuffle' ;

while ~isempty(varargin)
    switch(lower(varargin{1}))
        case 'badchannels'
            badChannels = varargin{2} ;
        case 'optsur'
            optSur = varargin{2} ;
        case 'seedname'
            seedName = varargin{2} ;
        otherwise
            error(['Unexpected input: ',varargin{1}])
    end
    varargin(1:2) = [] ;
end

%% initialization
sigOriTemp = reshape(dataIn,size(dataIn,1)*size(dataIn,2),[]) ;
surSigTemp = nan(size(sigOriTemp)) ;

%% generating surrogate data    
if optSur == 1         % break the temperol structure only
    rng(seedName) 
    
    if mod(size(dataIn,3),2) == 1
        dataIn(:,:,end+1) = zeros(size(dataIn,1),size(dataIn,1)) ;
    end
    randNumHalf =  2*pi*rand(size(dataIn,3)/2-1,1) ;
    randNum = [0;randNumHalf;0;-flip(randNumHalf) ]' ;
    
    for iChannel = setdiff(1:size(sigOriTemp,1),badChannels)
    freqSig = fft(sigOriTemp(iChannel,:)) ;
    absFreq = abs(freqSig) ;
    phaseFreq = angle(freqSig) ;
    reconSig = ifft(absFreq.*exp(1i*phaseFreq)) ;
    if angle(reconSig)>0.01
        error('wrong surrogate data reconstruction!')
    end
    
    surSigTemp(iChannel,:) = ifft(absFreq.*exp(1i*(phaseFreq+randNum))) ;
    end
end

if optSur == 2         % break the spatial-temporal structure
    rng(seedName) 
    
    if mod(size(dataIn,3),2) == 1
        dataIn(:,:,end+1) = zeros(size(dataIn,1),size(dataIn,1)) ;
    end
    
    for iChannel = setdiff(1:size(sigOriTemp,1),badChannels)
        randNumHalf =  2*pi*rand(size(dataIn,3)/2-1,1) ;
        randNum = [0;randNumHalf;0;-flip(randNumHalf) ]' ;
        randNum(1:3)
        freqSig = fft(sigOriTemp(iChannel,:)) ;
        absFreq = abs(freqSig) ;
        phaseFreq = angle(freqSig) ;
        reconSig = ifft(absFreq.*exp(1i*phaseFreq)) ;
        if angle(reconSig)>0.01
            error('wrong surrogate data reconstruction!')
        end
        surSigTemp(iChannel,:) = ifft(absFreq.*exp(1i*(phaseFreq+randNum))) ;
    end
end
surData = reshape(real(surSigTemp),size(dataIn,1),size(dataIn,2),[]) ;
end
