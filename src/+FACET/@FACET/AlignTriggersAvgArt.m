%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Find shift in artifact position to minimise sum of squared error between
% data and artifact template.
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
% - Assume same shift applies for all channels-
function AlignTriggersAvgArt(obj,AvgArt)

  % prepare result vector
  obj.TriggersAligned = zeros(1,obj.NumTriggers);

  for Art = 1:obj.NumTriggers
    Beta=FACET.FindMaxCrossCorr(obj.RAEEGAcq,AvgArt(Art,:),obj.TriggersUp(Art),obj.PreTrig,obj.SearchWindow);
    obj.TriggersAligned(Art) = obj.TriggersUp(Art)+Beta;
  end

end
