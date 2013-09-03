%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FACET_Text  Artifact removal with text status information.
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
classdef FACET_Text < FACET.FACET
  % FACET_Text  Artifact removal with text status information.
  %
  % Use this class if you want status output on the progress of the
  % algorithm execution.
  %
  % This class is a descendant of FACET and simply registers listeners
  % for all events. These listeners print the status information.

  methods(Access=public)

    % Constructor
    function obj=FACET_Text()
      obj = obj@FACET.FACET();
      addlistener(obj,'EventCorrectTriggers',  @FACET.FACET_Text.ListenerCorrectTriggers);
      addlistener(obj,'StartPreFilter',        @FACET.FACET_Text.ListenerStartPreFilter);
      addlistener(obj,'StartRemoveArtifacts',  @FACET.FACET_Text.ListenerStartRemoveArtifacts);
      addlistener(obj,'EventRAChannelStart',   @FACET.FACET_Text.ListenerRAChannelStart);
      addlistener(obj,'EventRACut',            @FACET.FACET_Text.ListenerRACut);
      addlistener(obj,'EventRAUpSample',       @FACET.FACET_Text.ListenerUpSample);
      addlistener(obj,'EventRAAlignSlices',    @FACET.FACET_Text.ListenerAlignSlices);
      addlistener(obj,'EventRAAlignSubSample', @FACET.FACET_Text.ListenerAlignSubSample);
      addlistener(obj,'EventRARemoveVolumeArt',@FACET.FACET_Text.ListenerRARemoveVolumeArt);
      addlistener(obj,'EventRACalcAvgArt',     @FACET.FACET_Text.ListenerRACalcAvgArt);
      addlistener(obj,'EventRAPCA',            @FACET.FACET_Text.ListenerRAPCA);
      addlistener(obj,'EventAutoResidualPCs',  @FACET.FACET_Text.ListenerAutoResidualPCs);
      addlistener(obj,'EventRADownSample',     @FACET.FACET_Text.ListenerRADownSample);
      addlistener(obj,'EventRAPaste',          @FACET.FACET_Text.ListenerRAPaste);
      addlistener(obj,'EventRALowPass',        @FACET.FACET_Text.ListenerLowPass);
      addlistener(obj,'EventRAANC',            @FACET.FACET_Text.ListenerRAANC);
      addlistener(obj,'EventRAChannelDone',    @FACET.FACET_Text.ListenerRAChannelDone);
      addlistener(obj,'Finished',              @FACET.FACET_Text.ListenerFinished);
    end

  end

  methods(Static)

    function ListenerCorrectTriggers(src,EvtData)
      fprintf('Correcting slice triggers...\n');
    end

    function ListenerStartPreFilter(src,EvtData)
      fprintf('Pre-Filter input data...\n');
    end

    function ListenerStartRemoveArtifacts(src,EvtData)
      fprintf('Artifact Subtraction:\n');
    end

    function ListenerRAChannelStart(src,EvtData)
      fprintf('  Channel %2d: ',EvtData.Param1);
    end

    function ListenerRACut(src,EvtData)
    end

    function ListenerUpSample(src,EvtData)
      fprintf('  Upsample...');
    end

    function ListenerAlignSlices(src,EvtData)
      fprintf('  Align Slices...');
    end

    function ListenerAlignSubSample(src,EvtData)
      fprintf('  Sub-sample align...');
    end

    function ListenerRARemoveVolumeArt(src,EvtData)
      fprintf('  Remove Vol. Art...');
    end

    function ListenerRACalcAvgArt(src,EvtData)
      fprintf('  Averaging...');
    end

    function ListenerRAPCA(src,EvtData)
      fprintf('  Calc. OBS...');
    end

    function ListenerAutoResidualPCs(src,EvtData)
      fprintf(' (%d residual PCs)',EvtData.Param1);
    end

    function ListenerRADownSample(src,EvtData)
      fprintf('  Decimate...');
    end

    function ListenerRAPaste(src,EvtData)
    end

    function ListenerLowPass(src,EvtData)
      fprintf('  Low-pass...');
    end

    function ListenerRAANC(src,EvtData)
      fprintf('  ANC...');
    end

    function ListenerRAChannelDone(src,EvtData)
      fprintf('  Done.\n');
    end

    function ListenerFinished(src,EvtData)
      fprintf('Finished in %s (CPU: %s).\n',FACET.SecToString(src.RunTime),FACET.SecToString(src.RunCpuTime));
    end

  end

end
