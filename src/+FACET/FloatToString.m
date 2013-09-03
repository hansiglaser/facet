%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Convert a float to a string with given number of significant digits
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
% A float number is converted to a string with the given number of
% significant digits. This sets the number of decimal places to show
% a total of (at least) "sig" significant digits. Note that for large
% values, no rounding to 10s, 100s, ... is performed.
%
% Params:
%   f      float number to print
%   sig    number of significant digits
%   width  (optional) total minimum width, treated as 0 if omitted 
% 
% Example: f = 12.3456
%   sig = 2:   12
%   sig = 3:   12.3
%   sig = 4:   12.35
%
% Example: f = 123.456
%   sig = 2:   123      <-- no rounding to "120"
%   sig = 3:   123
%   sig = 4:   123.5
%   sig = 5:   123.46
%
% Example: f = 0.00123456
%   sig = 2:   0.0012
%   sig = 3:   0.00123
%   sig = 4:   0.001235
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function st = FloatToString(f,sig,width)
  if nargin == 2
    width = 0;
  end
  % calculate number of decimal places
  digits = max(0,sig - ceil(log10(f)));
  % using '*' instead of a number -> supply as additional parameter
  st = sprintf('%*.*f',width,digits,f);
end
