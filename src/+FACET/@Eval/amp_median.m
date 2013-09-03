%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Median Imaging Artifact
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
% [All00] p. 235:
% mean of 10 measurements, made at equally spaced intervals (but what do
% they mean with "measurements"?); peak-peak values for every
% periode/epoch, then search for median in the list of all electrodes and
% subjects and measurements?
%
% samples(sample,epoch,channel,subject,recording)
%   sample ...... sample value within one epoch, every epoch must cover at
%                 least one artifact periode
%   epoch ....... epoch index, peak-peak values of all epochs are averaged
%   channel ..... EEG channel index
%   subject ..... subject index
%   recording ... recording index
% Note: channel, subject and recording dimensions are optional and can be
% omitted or mixed, the algorithms does not care.
function [VMin VMax VMed] = amp_median(obj,Samples)

  % calculate peak-peak values for every epoch
  PkPk = range(Samples);

  % average over every epoch
  MeanPkPk = mean(PkPk,2);

  % convert n-dim. array to 1-dim. vector to cover all channels, subjects and
  % recordings
  MeanPkPk=MeanPkPk(:);

  % calculate result
  VMin = min(MeanPkPk);
  VMax = max(MeanPkPk);
  VMed = median(MeanPkPk);

end
