%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Data storage container for BinOptRun
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
% This is the base class which must be derived for an actual application.
%
% General Rule: The index into the Data-array through Get(), GetOptions()
% and so on is always 0-based, i.e. Index is 0 .. NumRuns-1.
%
% The options are assembled with the binary value of Index. The LSB of
% Index corresponds to Options{1} and the MSB of Index to Options{end}.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
classdef BinOptContainer < handle

  properties(GetAccess=public,SetAccess=protected)
    % Cell array with the binary options
    Options;
    % Number of Options, i.e. length(Options)
    NumOpts;
    % Number of runs which combine all options, i.e. 2^NumOpts
    NumRuns;
    % Array of the function output data, is an array of BinOptData
    % (descendants)
    Data;
  end

  methods(Access=public)

    % Constructor
    %
    % Store the options, derive variables, and create the data storage
    % array.
    function obj=BinOptContainer(Options)
      obj.Options = Options;
      obj.NumOpts = length(Options);
      obj.NumRuns = 2^obj.NumOpts;
      for i = 1:obj.NumRuns
        obj.Data = [obj.Data obj.CreateData()];
      end
    end

    % Get a handle to the BinOptData object at Index
    %
    % Index is 0 .. NumRuns-1
    function Data = Get(obj,Index)
      % Check Index range
      if min(Index(:)) < 0 || max(Index(:)) >= obj.NumRuns
        error('FACET:BinOptContainer:GetOptions:InvalidIndex','Invalid index, must be between 0 and %d',obj.NumRuns-1);
      end
      % Return handle (Matlab arrays are 1-based)
      Data = obj.Data(Index+1);
    end

    % Get the list of options corresponding to Index
    %
    function Options = GetOptions(obj,Index)
      if (ndims(Index) ~= 2) || (numel(Index) ~= 1)
        % Index is a multi-dimensional array (i.e., not a scalar)
        % -> call ourself recursively for each element
        Options = cell(size(Index));
        % use one-dimensional indexing, which maps to the same elements of
        % the n-dimensional Index arrays
        for i = 1:numel(Index)
          Options{i} = obj.GetOptions(Index(i));
        end
        return;
      end
      % Index is a scalar -> perform the "normal" job
      % check Index range
      if (Index < 0) || (Index >= obj.NumRuns)
        error('FACET:BinOptContainer:GetOptions:InvalidIndex','Invalid index %d, must be between 0 and %d',Index,obj.NumRuns-1);
      end
      % assemble list of options
      Options = {};
      for OptIdx=0:obj.NumOpts-1
        if bitand(Index,2^OptIdx)
          Options = { Options{:} obj.Options{OptIdx+1} };
        end
      end
    end

    % Get the Index which corresponds to the given options
    %
    % It does not care about the order in Options.
    %
    % An error is generated, if an option is supplied, which does not
    % exist.
    %
    % If an option is supplied multiple times in Options, this is ignored.
    function Index = GetIndex(obj,Options)
      Index = uint8(0);
      for i = 1:length(Options)
        Found = false;
        for OptIdx=0:obj.NumOpts-1
          Found = strcmp(Options{i},obj.Options{OptIdx+1});   % returns 1 if they are equal
          if Found
            Index = bitor(Index,2^OptIdx);
            break;
          end
        end
        if ~Found
          error('FACET:BinOptContainer:GetIndex:UnknownOption','Unknown option "%s"',Options{i});
        end
      end
    end

    % Permute the order of the options
    %
    % NewOrder must have exactly NumOpts elements, going from 0 to
    % NumOpts-1, with all numbers included, i.e. none more than once.
    %
    % IndexIn can be a numeric array of any dimension.
    function IndexOut = Permute(obj,NewOrder,IndexIn)
      if length(NewOrder) ~= obj.NumOpts
        error('FACET:BinOptContainer:Permute:NewOrderLength','NewOrder must have exactly %d items, not %d',obj.NumOpts,length(NewOrder));
      end
      if min(NewOrder) ~= 0
        error('FACET:BinOptContainer:Permute:NewOrderMin','NewOrder items must be from 0 to %d',obj.NumRuns-1);
      end
      if max(NewOrder) ~= obj.NumOpts-1
        error('FACET:BinOptContainer:Permute:NewOrderMax','NewOrder items must be from 0 to %d',obj.NumRuns-1);
      end
      % check that NewOrder has all indices
      if ~isequal(sort(NewOrder),0:(obj.NumOpts-1))
        error('FACET:BinOptContainer:Permute:NewOrderElements','NewOrder must have all values from 0 to %d',obj.NumRuns-1);
      end
      % check that IndexIn doesn't have invalid numbers
      if min(IndexIn(:)) < 0 || max(IndexIn(:)) >= obj.NumRuns
        error('FACET:BinOptContainer:Permute:InvalidIndex','Invalid index, must be between 0 and %d',obj.NumRuns-1);
      end

      % create result array of the same size as IndexIn
      IndexOut = zeros(size(IndexIn),'uint32');
      % interate over all elements
      for Element = 1:numel(IndexIn)
        % iterate over all bits
        for Bit=1:obj.NumOpts   % bitget() and the NewOrder arry are 1-based
          if bitget(IndexIn(Element),Bit) ~= 0
            % set the bit in the result, NewOrder values are 0-based
            IndexOut(Element) = bitor(IndexOut(Element),2^NewOrder(Bit));
          end
        end
      end
    end

  end

  methods(Access=protected)

    % Extract data with extraction function
    %
    % Func must be a function handle which accepts a BinOptData object
    % as argument and returns any Matlab type of data.
    function Data = GetFunc(obj,Index,Func)
      if (ndims(Index) ~= 2) || (numel(Index) ~= 1)
        % Index is a multi-dimensional array (i.e., not a scalar)
        % -> call ourself recursively for each element
        Data = cell(size(Index));
        % use one-dimensional indexing, which maps to the same elements of
        % the n-dimensional Index arrays
        for i = 1:numel(Index)
          Data{i} = obj.GetFunc(Index(i),Func);
        end
        return;
      end
      % Index is a scalar -> perform the "normal" job
      % check Index range
      if (Index < 0) || (Index >= obj.NumRuns)
        error('FACET:BinOptContainer:GetFunc:InvalidIndex','Invalid index %d, must be between 0 and %d',Index,obj.NumRuns-1);
      end
      % assemble list of options
      Data = Func(obj.Get(Index));
    end

  end

  methods(Access=protected,Static,Abstract)

    % Abstract function to create one BinOptData (descendant) instance
    %
    % This function is called by the constructor to fill obj.Data.
    Data = CreateData();

  end

end
