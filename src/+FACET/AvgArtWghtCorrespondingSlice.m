%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Create averaging weight matrix to average every slice of a volume with
% its corresponding slices of other volumes.
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
%   obj ........... FACET object
%   Periode ....... number of slices per volume
%
% Uses:
%   NumTriggers ... total number of epochs
%   HalfWindow .... number of epochs to average before and after the
%                   considered one
%
% Results:
%   M ............. averaging matrix
%
% This routine also covers interlaved EPI sequences, so just choose the
% Periode value accordingly. See also
%   http://users.fmrib.ox.ac.uk/~stuart/thesis/chapter_5/contents.html
%
function M = AvgArtWghtCorrespondingSlice(obj,Periode)

  M=zeros(obj.NumTriggers,obj.NumTriggers);
  WarningShown = false;

  for row=1:obj.NumTriggers     % iterate over all triggers
    % start of search window
    IStart=row-obj.HalfWindow*Periode;
    if IStart < 1
      IStart = 1 + mod(row-1,Periode);
    end
    % end of search window
    IEnd=IStart+(2*obj.HalfWindow)*Periode;
    % if width of search window is too small, extend to the left
    if IEnd > obj.NumTriggers
      IEnd   = NearestMultipleBefore(row,Periode,obj.NumTriggers);
      IStart = IEnd-(2*obj.HalfWindow)*Periode;
    end
    % if extension to the left resulted in a negative value, limit
    if IStart < 1
      IStart = 1 + mod(row-1,Periode);
      if ~WarningShown
        warning('AvgArtWghtCorrespondingSlice:NotEnoughVolumes','Not enough volumes to use %d corresponding slices. Using only %d slices',2*obj.HalfWindow+1,(IEnd-IStart)/Periode+1);
        WarningShown = true;
      end
    end
    % indices for current row
    i = IStart : Periode : IEnd;
    M(row,i) = 1/length(i);
  end

end

% Calculate the maximum value
%   Result = Origin + N*Periode
% which is below Limit with N being a natural number
function Result = NearestMultipleBefore(Origin,Periode,Limit)
  N = floor((Limit - Origin) / Periode);
  Result = Origin + N * Periode;
end
