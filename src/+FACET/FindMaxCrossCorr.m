%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Find the position of maximum cross correlation
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
% The cross correlation between Template to Base is calculated. Template
% is shifted from Center-PreCenter for SearchWindow samples. From the cross
% correlation results the position of the maximum value is used to find the
% position of the best match.
%
% Parameters
%   Base ............ base signal (haystack)
%   Template ........ template to "search" in the base signal (needle)
%   Center .......... center of search
%   PreCenter ....... number of samples before center to start
%   SearchWindow .... number of samples to search
%
function MaxPos = FindMaxCrossCorr(Base,Template,Center,PreCenter,SearchWindow)

% calculate correlations within search window
PostCenter = length(Template) - PreCenter - 1;

% Calculate Cross-Covariance (>20x faster than old approach with ptcorr2!)
Corr = xcorr(Base(Center-PreCenter:Center+PostCenter+SearchWindow),Template,SearchWindow);

% find maximum correlcation
[CV,CP]=max(Corr);
% calculate offset
MaxPos=CP-(SearchWindow+1);
