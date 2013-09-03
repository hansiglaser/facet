%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Create averaging weight matrix to reproduce Niazy's behavior for slice
% triggers.
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
% The left and right HalfWindow epochs by taking every 2nd are averaged.
%
% Parameters:
%   obj .... FACET object
%
% Uses:
%   NumTriggers ... total number of epochs
%   HalfWindow .... number of epochs to average before and after the
%                   considered one
%
% Results:
%   M ............. averaging matrix
function M = AvgArtWghtSliceTrigger(obj)

M=zeros(obj.NumTriggers,obj.NumTriggers);

for s=1:obj.NumTriggers     % iterate over all triggers
  % calculate start trigger
  if s==1
    % first artifact = mean(artifacts 2,4,6,...,2+2*HalfWindow)
    IStart = 2;
  elseif s==2
    % second artifact = mean(3,5,7,...,3+2*HalfWindow)
    IStart = 3;
  elseif ((s>(3+obj.HalfWindow)) && (s<=(obj.NumTriggers-(obj.HalfWindow+2))))
    % n-th artifact = mean(prev(2:end),s+HalfWindow)
    %  ... alternating even and odd
    %  ... reusing previously picked trigger-periods
    IStart = s-obj.HalfWindow;
    % Artifacts 3,4,5,...,HalfWindow+2 and LastTrig-HalfWindow-3,...,LastTrig reuse
    % the previously set value of avg_art. Therefore they "saturate"
    % at the borders.
  end
  i = IStart : 2 : (IStart+2*obj.HalfWindow);
  M(s,i) = 1/length(i);
end
