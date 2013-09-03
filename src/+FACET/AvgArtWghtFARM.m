%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Create averaging weight matrix by selecting the epochs with the highest
% correlation to the averaged one.
%
%  Copyright (c) 2010-2012 Johann Glaser <Johann.Glaser@gmx.at>
%
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program; if not, write to the Free Software
% Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, 
% MA  02110-1301, USA.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Parameters:
%   IData ............... EEG data (1xn vector)
%   SecMarker ........... array of epoch markers
%   PrePeak ............. epoch start before markers
%   PostPeak ............ epoch end after markers
%   SearchHalfWindow .... search window for maximum correlation
%   Window .............. number of epochs to average
%
% Usage:
%
function AvgArtWghtFARM(obj,pos,Channel)

% split vector into 2D matrix
IDataMatrix = FACET.SplitVector(obj.RAEEGAcq,obj.TriggersUp-obj.PreTrig,obj.ArtLength);

% FMRIB Dataset
%  - with spares matrix: 2:50.5 / CPU: 2:52.8
%  - with full matrix:   2:31.9 / CPU: 2.34.9
if obj.NumTriggers < 1500
  % for small and moderate number of triggers use full matrix
  obj.AvgMatrix=zeros(obj.NumTriggers,obj.NumTriggers);
else
  % for large number of triggers use sparse matrix
  obj.AvgMatrix=spalloc(obj.NumTriggers,obj.NumTriggers,obj.NumTriggers*obj.AvgWindow);
end

% calculate correlation between all epochs
CorrMat = corrcoef(IDataMatrix');

SearchHalfWindow = obj.AvgMatrixUpdaterData.SearchHalfWindow;

TooLessSimilarRows = 0;
TooLessSimilarEpochs = 0;

for row=1:obj.NumTriggers
  % start of search window
  a=max(1,row-SearchHalfWindow);
  % end of search window
  b=min(a+2*SearchHalfWindow+1,obj.NumTriggers);
  % if width of search window is too small, extend to the left
  if b-a < 2*SearchHalfWindow+1
    a=b-2*SearchHalfWindow-1;
  end
  % if extension to the left resulted in a negative value, limit
  if a < 1
    a = 1;
  end
% Don't use xcorr() repeated times, this is very slow. This was replaced by
% corrcoef() to calculate all correlations. Strangely enough the results
% are different for approx. the second half of every row, no clue why.
%
%   Corr=zeros(1,2*SearchHalfWindow+1);
%   for col=a:b
%     Corr(col-a+1) = xcorr(IDataMatrix(row,:),IDataMatrix(col,:),0,'coeff');
%   end
  Corr = CorrMat(row,a:b);
  [CorrVal,Index]=sort(abs(Corr),2,'descend');
  %plot(Corr);
  %hold on;
  %plot(y,'r');
  %plot(IndexTemp,'g');

  % set all values below 0.9 to 0
  Index = Index.*(CorrVal >= 0.9);
  % select Window values but don't use the first (= 1.0, current epoch itself)
  Index = Index(2:(obj.AvgWindow+1));
  % find all non-zero values
  [i,j,Index] = find(Index);
  % check that we have enough similar epochs
  if isempty(Index)
    error('FACET:NonSimilarArtifact','Didn''t find any similar artifacts in periode %d while generateing the averaging matrix',row);
  elseif length(Index) < obj.AvgWindow
    % couldn't find AvgWindow similar epochs, just note and warn at the end
    TooLessSimilarRows   = TooLessSimilarRows   + 1;
    TooLessSimilarEpochs = TooLessSimilarEpochs + (obj.AvgWindow - length(Index));
  end

%  % weight averaging by RMS of periode
%  x=IDataMatrix(Index,:);    
%  s=std(x,0,2);
%  Weights = s;
%  Weights = 1./s;

  % equally weighted averaging
  Weights = ones(length(Index),1);
  Weights = Weights / sum(Weights);

  obj.AvgMatrix(row,Index+a-1) = Weights;

%  obj.AvgMatrix(row,randi(obj.NumTriggers,1,obj.AvgWindow)) = 1/length(obj.AvgWindow);
%  obj.AvgMatrix(row,1:obj.AvgWindow) = 1/length(obj.AvgWindow);
%  obj.AvgMatrix(row,max(row-1,1)) = 0.5;
%  obj.AvgMatrix(row,min(row+1,obj.NumTriggers)) = 0.5;
%   i = (a+1):2:b;
%   obj.AvgMatrix(row,i) = 1/length(i);

%  obj.AvgMatrixUpdaterData.Corr(row,:) = Corr(Index);

  if TooLessSimilarRows ~= 0
    warning('FACET:TooLessSimilarArtifacts','There were %d epochs for which not all %d similar epochs for averaging could be found (%d total missing)',TooLessSimilarRows,obj.AvgWindow,TooLessSimilarEpochs);
  end

end

% amp_median: slight improvement of median, big improvement of maximum
% fft_allen: slight improvement except for 8-12Hz band
% fft_niazy: FARM algorithm with optimized template selection is a bit worse
% fft_vandermeer: says nothing useful??
% rms_correction: better min and max, slightly better mean, slightly worse median
% rms_residual: slightly better min, max and median, slightly worse mean
% snr_residual: it got worse :-O 
