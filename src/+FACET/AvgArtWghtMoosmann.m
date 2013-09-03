%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Create averaging weight matrix with the Realignment Parameter informed 
% (rp-info) algorithm (Moosmann et al. Neuroimage 2009).
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
%   RPFile ........ realignment parameter file from SPM (*.txt file)
%   Threshold ..... threshold of movement in mm
%
% Uses:
%   NumTriggers ... total number of epochs
%   Window ........ number of epochs to average, i.e. that constitute the
%                   templates (typical k=25)
%
% Usage:
%   M = AvgArtWghtMoosmann(obj,'example01.txt',300,0.8);
%
% Results:
%   M ............. averaging matrix with row-sums normed to 1.0
%
% Important: Ensure that the Bergen EEG&fMRI Toolbox plugin for EEGLAB is
% available via the PATH, e.g. at
%   /opt/eeglab7_2_9_20b/plugins/EEG_fMRI_recording/
%
% The RPFile contains one line per fMRI volume with 6 columns each with the
% estimated translation (in mm) and rotation (in radians) of the rigid body
% transformation relative to the previous volume.
%   1: x: right/left
%   2: y: front/back
%   3: z: up/down
%   4: pitch (about x axis)
%   5: roll  (about y axis)
%   6: yaw   (about z axis)
%
% Mossmann's m_rp_info uses the RPFile and uses the data right-aligned with
% respect to NumTrigs, i.e. if NumTrigs is 300 and the RPFile has 150
% entries, then M will have the corrections in lines 151:300.
%
function M = AvgArtWghtMoosmann(obj,RPFile,Threshold)

[motiondata_struct,M] = m_rp_info(RPFile,obj.NumTriggers,Threshold,2*obj.HalfWindow);

% ensure every row sums up to 1.0
for i = 1:size(M,1)
  M(i,:) = M(i,:) * 1/sum(M(i,:));
end
