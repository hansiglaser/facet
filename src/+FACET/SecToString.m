%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Convert number of seconds to a human readable string
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
function st = SecToString(sec)

s = mod(sec,60); sec = floor(sec/60);
m = mod(sec,60); sec = floor(sec/60);
h = mod(sec,24); sec = floor(sec/24);
d = mod(sec, 7); sec = floor(sec/ 7);
w = sec;

sw=''; sd='';sh='';sm='';ss='';

if w > 0
    sw = sprintf('%d week',w);
    if w > 1
        sw = [sw 's'];
    end
end

if d > 0
    sd = sprintf('%d day',d);
    if d > 1
        sd = [sd 's'];
    end
end

if h > 0
    sh = sprintf('%d hour',h);
    if h > 1
        sh = [sh 's'];
    end
end

if m > 0
    sm = sprintf('%d minute',m);
    if m > 1
        sm = [sm 's'];
    end
end

if s > 0
    ss = sprintf('%.1f second',s);
    if s ~= 1
        ss = [ss 's'];
    end
end

st = FACET.StrJoin(' ',sw, sd, sh, sm, ss);
