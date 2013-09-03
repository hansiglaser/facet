%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Estimate noise by averaging epochs.
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
%   AvgMatrix ........... averaging matrix
%   SecMarker ........... array of epoch markers
%   SecMarkerAligned .... array of epoch markers aligned with average
%                         artifact, only used if Channel<>1
%   SearchWindow ........ search window for maximum correlation for section
%                         alignment, only used if Channel=1
%   PrePeak ............. epoch start before markers
%   PostPeak ............ epoch end after markers
%   Channel ............. current channel
%   ExcludeChannels ..... array of channels which are excluded from
%                         minimization of sum of squared errors
%   STARTFLAG ........... input to output argument feed-through
%   LASTFLAG ............ input to output argument feed-through
%
% Results:
%   INoise .............. Estimated noise (from averaging)
%   SecMarkerAligned .... array of epoch markers aligned with average
%                         artifact
%   STARTFLAG ........... flags if the first epoch couldn't be removed
%   LASTFLAG............. flags if the last  epoch couldn't be removed
% SecMarkerAligned, SecMarkerAligned and LASTFLAG are only set if
% Channel=1 and feed-through otherwise
%
% Details on AvgMatrix:
% Every row of AvgMatrix specifies how the epochs from IData are summed up
% to form the average artifact corresponding to this epoch.
% Ensure every row sums up to 1.0!

function INoise = CalcAvgArt(obj,Channel)

  % show weighting matrix
  %figure;
  %imagesc(obj.AvgMatrix);
  %colormap(gray(1000));

  EEGZeroMean=obj.RAEEGAcq-mean(obj.RAEEGAll);
  % split vector into 2D matrix
  IDataMatrix = FACET.SplitVector(EEGZeroMean,obj.TriggersUp-obj.PreTrig,obj.ArtLength);

  % check AvgMatrix
  AvgMatrixSum=sum(obj.AvgMatrix,2);
  if min(AvgMatrixSum) <= 0
    error('FACET:AvgMatrixZero','AvgMatrix contains rows with zero or negative sum: %s',mat2str(find(AvgMatrixSum<=0)));
  end
  % calculate average artefacts
  AvgArt = obj.AvgMatrix * IDataMatrix;

  INoise = zeros(1,length(EEGZeroMean));

%   try
    if Channel==1
      % For first channel, find shift in artifact position to minimise 
      % sum of squared error between data and artifact template
      % - Assume same shift applies for all channels-
      obj.AlignTriggersAvgArt(AvgArt);
    end
    % Calculate Scale factor 'Alpha' to minimize sum of squared error. This
    % is necessary if the EEG data amplitude increases or decreases with
    % time (e.g. the Niazy example data set). For the start and end values
    % the averaging doesn't use values to the left and to the right of the
    % artifact but is unilateral and therefore biased. The scale factor
    % can handle this.
    if isempty(intersect(obj.OBSExcludeChannels,Channel))
      IdataMatrixAligned = FACET.SplitVector(EEGZeroMean,obj.TriggersAligned-obj.PreTrig,obj.ArtLength);
      Alpha=sum(IdataMatrixAligned.*AvgArt,2) ./ sum(AvgArt.*AvgArt,2);
      % do some sanity-checks for Alpha
      if isnan(sum(Alpha))
        error('FACET:AvgArtNaN','Something is not correct with your data because Alpha contains %d NaNs',length(find(isnan(Alpha))));
      end
      if (min(Alpha) < 0) || (max(Alpha) > 2 * mean(Alpha))
        warning('FACET:AvgArtAlphaStrange','Strange results for Alpha with negative values and/or large outliers');
      end
    else
      Alpha=ones(obj.NumTriggers,1);
    end
    % Calculate estimated noise
    for s=1:obj.NumTriggers
      INoise(obj.TriggersAligned(s)-obj.PreTrig:obj.TriggersAligned(s)+obj.PostTrig)=Alpha(s)*AvgArt(s,:);
      if s == 1 || ~obj.InterpolateVolumeGaps
        continue
      end
      % if there was a hole between the previous and this averaging periode: interpolate
      StartThis = obj.TriggersAligned(s)-obj.PreTrig;
      EndPrev   = obj.TriggersAligned(s-1)+obj.PostTrig;
      Length    = StartThis - EndPrev - 1;
      if Length > 0 % == 1
        EndVal   = INoise(EndPrev);
        StartVal = INoise(StartThis);
        Diff     = StartVal - EndVal;
        Gap      = EndVal + (1:Length)*(Diff/(Length+1));
        INoise((EndPrev+1):(StartThis-1)) = Gap;
      end
    end
%   catch ME
%     if Channel==1
%       warning('AvgArt:FirstArtifactFail','Not enough data to remove first artifact segment (%s)',ME.message);
%       STARTFLAG=1;
%     elseif s==LastTrig
%       warning('AvgArt:LastArtifactFail', 'Not enough data to remove last artifact segment (%s)',ME.message);
%       LASTFLAG=1;
%     end
%   end
