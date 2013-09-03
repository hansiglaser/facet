%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Create averaging weight matrix as performed by Allen et al. (2000)
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
%
% Uses:
%   RAEEGAcq ...... EEG data
%   TriggersUp .... slice/volume triggers
%   PreTrig ....... slice/volume start before trigger
%   ArtLength ..... artifact length
%   NumTriggers ... total number of epochs
%   AvgWindow ..... number of epochs to average, i.e. that constitute the
%                   templates (typically 25)
%
% Results:
%   AvgMatrix ..... averaging matrix with row-sums normed to 1.0
%
% from Allen et al. (2000):
%  - with    volume gaps: one epoch is one volume period, average over  25 epochs
%  - without volume gaps: one epoch is one slice  period, average over 100 slices
% averaging: first five epochs were always included, subsequent only if the
% cross correlation between the epoch and the current average exceeded 0.975

function M = AvgArtWghtAllen(obj,pos,Channel)

% split vector into 2D matrix
IDataMatrix = FACET.SplitVector(obj.RAEEGAcq,obj.TriggersUp-obj.PreTrig,obj.ArtLength);

obj.AvgMatrix=zeros(obj.NumTriggers,obj.NumTriggers);

for Block=1:obj.AvgWindow:obj.NumTriggers
  Last = min(Block+obj.AvgWindow-1,obj.NumTriggers);
  Candidates=Block:Last;
  % first five epochs are always included
  Chosen = Candidates(1:5);
  Sum = sum(IDataMatrix(Chosen,:),1);
  % subsequently only include those epochs if the cross correlation between
  % it and the current average exceeds 0.975
  for Idx=Candidates(6:end)
    Avg = Sum / length(Chosen);
    % calculate correlation
    xcorr = corrcoef(Avg,IDataMatrix(Idx,:));
    % get correlation coefficient from 2x2 matrix
    xcorr = xcorr(1,2);
    % if it exceeds 0.975 include this epoch
    if xcorr > 0.975
      Sum = Sum + IDataMatrix(Idx,:);
      Chosen = [ Chosen Idx ];
    end
  end

  for Idx=Candidates
    obj.AvgMatrix(Idx,Chosen) = 1/length(Chosen);
  end
end
