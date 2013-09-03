%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Get trigger locations from an EEGLAB data set
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
%   event
%   EventType ........ Type of trigger event. All events which 
%                      event.type matches EventType are used. If left
%                      unset, all events are used.
%                      To get a list of all event types try
%                        unique({EEG.event.type})
%   TriggerOffset .... Offset of trigger times. The value of this variable
%                      is added to the values taken from event.latency. If
%                      the trigger events from the original data set are
%                      too late, you have to put a negative number here.
%
% Usage:
%   >> trigs = FindTriggers(EEG.event,'IA',-1563);
%
function Triggers = FindTriggers(event,EventType,TriggerOffset)
  if nargin < 2, EventType = []; end
  if nargin < 3, TriggerOffset = 0; end
 
  if isempty(EventType)
    % if no EventType was set, just use all events
    Triggers=[event.latency];
  else
    % filter events according to EventType
    Triggers=[];
    for E=1:length(event)
      if strcmp(event(E).type,EventType)
        Triggers(end+1)=round(event(E).latency);
      end
    end
  end
  % add offset
  Triggers = Triggers + TriggerOffset;
end
